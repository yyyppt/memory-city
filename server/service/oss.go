package service

import (
	"bytes"
	"crypto/rand"
	"fmt"
	"gopkg.in/errgo.v2/errors"
	"io"
	"mime"
	"net/http"
	"shiguangji/config"
	"shiguangji/model"
	"strings"
	"time"
)

// UpdateUserInfo 修改用户信息
func UpdateUserInfo(userID string, nickname, avatar, bio string) (*model.User, error) {
	var user model.User
	if err := Db.Where("id = ?", userID).First(&user).Error; err != nil {
		return nil, errors.New("用户不存在")
	}

	updated := false

	if nickname != "" && nickname != user.Nickname {
		user.Nickname = nickname
		updated = true
	}

	if bio == "" {
		user.Bio = "请设置你的个性签名"
		updated = true
	} else if bio != user.Bio {
		user.Bio = bio
		updated = true
	}

	if avatar != "" && avatar != user.Avatar {
		var imgData []byte
		var imgType string
		var err error

		if strings.HasPrefix(avatar, "data:image/") {
			imgData, imgType, err = decodeDataURLImage(avatar)
		} else if isLikelyBase64(avatar) {
			imgData, imgType, err = decodeBase64Image(avatar)
		} else if strings.HasPrefix(avatar, "http://") || strings.HasPrefix(avatar, "https://") {
			imgData, imgType, err = downloadImageFromURL(avatar)
		} else {
			err = fmt.Errorf("不支持的图片格式")
		}

		if err != nil {
			return nil, fmt.Errorf("处理头像失败：%v", err)
		}

		ossAvatarURL, err := uploadUserImageToOSS(userID, imgData, imgType, "avatar")
		if err != nil {
			return nil, fmt.Errorf("上传头像到OSS失败：%v", err)
		}

		user.Avatar = ossAvatarURL
		updated = true
	}

	if updated {
		user.UpdateTime = time.Now()
		if err := Db.Save(&user).Error; err != nil {
			return nil, errors.New("更新用户信息失败")
		}
	}

	user.Password = ""
	return &user, nil
}

func uploadUserImageToOSS(userID string, imgData []byte, mimeType, imgType string) (string, error) {
	if config.OSSBucketName == "" || config.OSSEndpoint == "" {
		return "", errors.New("OSS配置不完整")
	}
	if OssClient == nil {
		return "", errors.New("OSS客户端未初始化")
	}

	var fileExt string
	if strings.Contains(mimeType, "jpeg") {
		fileExt = ".jpg"
	} else if strings.Contains(mimeType, "png") {
		fileExt = ".png"
	} else if strings.Contains(mimeType, "gif") {
		fileExt = ".gif"
	} else {
		fileExt = ".jpg"
	}

	timestamp := time.Now().UnixNano()
	randomBytes := make([]byte, 4)
	rand.Read(randomBytes)
	randomNum := fmt.Sprintf("%x", randomBytes)

	var ossFilePath string
	if imgType == "avatar" {
		ossFilePath = fmt.Sprintf("user/avatar/%s_avatar%s", userID, fileExt)
	} else {
		ossFilePath = fmt.Sprintf("user/content/%s/%d_%s%s",
			userID, timestamp, randomNum, fileExt)
	}

	bucket, err := OssClient.Bucket(config.OSSBucketName)
	if err != nil {
		return "", fmt.Errorf("获取Bucket失败: %w", err)
	}

	err = bucket.PutObject(ossFilePath, bytes.NewReader(imgData))
	if err != nil {
		return "", fmt.Errorf("上传失败: %w", err)
	}

	ossAccessURL := fmt.Sprintf("https://%s.%s/%s",
		config.OSSBucketName, config.OSSEndpoint_IOS, ossFilePath)

	return ossAccessURL, nil
}

// downloadImageFromURL 从指定URL下载图片（返回字节数组）
func downloadImageFromURL(url string) ([]byte, string, error) {
	client := &http.Client{
		Timeout: 30 * time.Second,
		Transport: &http.Transport{
			MaxIdleConns:       10,
			IdleConnTimeout:    30 * time.Second,
			DisableCompression: true,
		},
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, "", fmt.Errorf("创建请求失败: %w", err)
	}

	req.Header.Set("User-Agent", "Mozilla/5.0 (compatible; ImageDownloader/1.0)")
	req.Header.Set("Accept", "image/webp,image/*,*/*;q=0.8")

	resp, err := client.Do(req)
	if err != nil {
		return nil, "", fmt.Errorf("请求失败: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, "", fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
	}

	contentType := resp.Header.Get("Content-Type")
	if contentType == "" {
		contentType = http.DetectContentType([]byte{})
	}

	if !strings.HasPrefix(contentType, "image/") {
		return nil, "", fmt.Errorf("非图片内容: %s", contentType)
	}

	maxSize := 10 * 1024 * 1024
	imgData, err := io.ReadAll(io.LimitReader(resp.Body, int64(maxSize)+1))
	if err != nil {
		return nil, "", fmt.Errorf("读取失败: %w", err)
	}

	if len(imgData) > maxSize {
		return nil, "", fmt.Errorf("图片过大: %d > %d", len(imgData), maxSize)
	}

	if len(imgData) == 0 {
		return nil, "", errors.New("图片内容为空")
	}

	detectedType := http.DetectContentType(imgData)
	if !strings.HasPrefix(detectedType, "image/") {
		return nil, "", fmt.Errorf("下载内容非图片: %s", detectedType)
	}

	return imgData, contentType, nil
}

// uploadImageToOSS 将图片字节数组上传到自有OSS，返回OSS访问URL
func uploadImageToOSS(userID string, imgData []byte, mimeType string) (string, error) {
	if config.OSSBucketName == "" {
		return "", errors.New("OSSBucketName未配置")
	}
	if config.OSSEndpoint == "" {
		return "", errors.New("OSSEndpoint未配置")
	}
	if OssClient == nil {
		return "", errors.New("OSS客户端未初始化")
	}

	ext, err := mime.ExtensionsByType(mimeType)
	var fileExt string
	if err != nil || len(ext) == 0 {
		switch mimeType {
		case "image/jpeg", "image/jpg":
			fileExt = ".jpg"
		case "image/png":
			fileExt = ".png"
		case "image/gif":
			fileExt = ".gif"
		case "image/webp":
			fileExt = ".webp"
		default:
			detected := http.DetectContentType(imgData)
			if strings.Contains(detected, "jpeg") {
				fileExt = ".jpg"
			} else if strings.Contains(detected, "png") {
				fileExt = ".png"
			} else {
				fileExt = ".jpg" // 默认
			}
		}
	} else {
		fileExt = ext[0] // 使用第一个扩展名
	}

	timestamp := time.Now().UnixNano()
	randomBytes := make([]byte, 4)
	rand.Read(randomBytes)
	randomNum := fmt.Sprintf("%x", randomBytes)

	ossFilePath := fmt.Sprintf("user/content/%s/%d_%s%s",
		userID, timestamp, randomNum, fileExt)

	bucket, err := OssClient.Bucket(config.OSSBucketName)
	if err != nil {
		return "", fmt.Errorf("获取Bucket失败: %w", err)
	}

	var lastErr error
	for i := 0; i < 3; i++ {
		err = bucket.PutObject(ossFilePath, bytes.NewReader(imgData))
		if err == nil {
			break
		}
		lastErr = err
		time.Sleep(time.Duration(i*100) * time.Millisecond) // 递增延迟
	}

	if lastErr != nil {
		return "", fmt.Errorf("上传OSS失败: %w", lastErr)
	}

	ossAccessURL := fmt.Sprintf("https://%s.%s/%s",
		config.OSSBucketName, config.OSSEndpoint_IOS, ossFilePath)

	return ossAccessURL, nil
}

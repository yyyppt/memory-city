package service

import (
	"errors"
	"fmt"
	"log"
	"shiguangji/model"
	"shiguangji/utils"
	"time"
)

// UploadToken 获取OSS上传凭证（生成预签名URL供前端直传）
func UploadToken(userID string) (*model.UploadTokenResp, error) {
	uid, err := parseInt64Safe(userID)
	if err != nil {
		log.Printf("[UploadToken] 用户ID格式错误：userID=%s, err=%v", userID, err)
		return nil, fmt.Errorf("用户ID格式错误：必须为有效数字（%w）", err)
	}

	if OssClient == nil {
		log.Printf("[UploadToken] OSS客户端未初始化：userID=%s", userID)
		return nil, errors.New("OSS客户端初始化失败，请检查配置")
	}

	bucket, err := utils.OSSBucket(OssClient)
	if err != nil {
		log.Printf("[UploadToken] 获取OSS Bucket失败：userID=%s, err=%v", userID, err)
		return nil, fmt.Errorf("Bucket获取失败：%w", err)
	}

	fileExt := "jpg"
	objectKey := utils.GenerateOSSObjectKey(uid, fileExt)
	if objectKey == "" {
		log.Printf("[UploadToken] 生成OSS ObjectKey失败：userID=%s, uid=%d", userID, uid)
		return nil, errors.New("生成文件存储路径失败")
	}

	expireSeconds := utils.GetOSSExpireSeconds()
	if expireSeconds <= 0 || expireSeconds > 3600 {
		expireSeconds = 300
		log.Printf("[UploadToken] OSS过期时间配置异常，使用默认值：expireSeconds=%d → %d",
			utils.GetOSSExpireSeconds(), expireSeconds)
	}
	expireTime := time.Now().Add(time.Duration(expireSeconds) * time.Second)

	signedURL, err := utils.GenerateOSSPresignedURL(bucket, objectKey, expireSeconds)
	if err != nil {
		log.Printf("[UploadToken] 生成预签名URL失败：userID=%s, objectKey=%s, err=%v",
			userID, objectKey, err)
		return nil, fmt.Errorf("预签名URL生成失败：%w", err)
	}

	uploadPath := fmt.Sprintf("user/%d/%s/", uid, time.Now().Format("20060102"))
	resp := &model.UploadTokenResp{
		UploadURL:  signedURL,
		Policy:     "",
		Token:      "",
		ObjectKey:  objectKey,
		ExpireTime: expireTime.Unix(),
		UploadPath: uploadPath,
	}

	log.Printf("[UploadToken] 生成OSS上传凭证成功：userID=%s, uid=%d, objectKey=%s, expireTime=%d",
		userID, uid, objectKey, resp.ExpireTime)
	return resp, nil
}

package service

import (
	"encoding/base64"
	"errors"
	"fmt"
	"net/http"
	"shiguangji/model"
	"strings"
	"time"

	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// ContentPublish 发布内容
func ContentPublish(userID string, title, content, city, year, mood string, visible bool, images []string) (int64, error) {
	if title == "" || content == "" {
		return 0, errors.New("标题和内容不能为空")
	}

	uid, err := parseInt64Safe(userID)
	if err != nil {
		return 0, fmt.Errorf("用户ID格式错误：%w", err)
	}

	ossImageURLs := make([]string, 0, len(images))
	failedImages := make([]int, 0)

	for idx, imageData := range images {
		if imageData == "" {
			continue
		}

		var imgData []byte
		var err error
		var imgType string

		switch {
		case strings.HasPrefix(imageData, "data:image/"):
			// dataURL格式: data:image/jpeg;base64,/9j/4AAQ...
			imgData, imgType, err = decodeDataURLImage(imageData)
		case isLikelyBase64(imageData):
			// 纯Base64格式: /9j/4AAQ...
			imgData, imgType, err = decodeBase64Image(imageData)
		case strings.HasPrefix(imageData, "http://") || strings.HasPrefix(imageData, "https://"):
			// HTTP URL格式
			imgData, imgType, err = downloadImageFromURL(imageData)
		default:
			err = fmt.Errorf("不支持的图片格式")
		}

		if err != nil {
			failedImages = append(failedImages, idx+1)

			fmt.Printf("[WARN] 第%d张图片处理失败: %v\n", idx+1, err)
			continue
		}

		ossURL, err := uploadImageToOSS(userID, imgData, imgType)
		if err != nil {
			failedImages = append(failedImages, idx+1)
			fmt.Printf("[WARN] 第%d张图片上传失败: %v\n", idx+1, err)
			continue
		}

		ossImageURLs = append(ossImageURLs, ossURL)
	}

	if len(failedImages) > 0 {
		fmt.Printf("[INFO] 用户 %s 发布内容，%d 张图片处理失败: %v\n",
			userID, len(failedImages), failedImages)
	}

	contentModel := model.Content{
		UserID:       uid,
		Title:        title,
		Content:      content,
		City:         city,
		Year:         year,
		Mood:         mood,
		Images:       datatypes.JSONSlice[string](ossImageURLs),
		LikeCount:    0,
		CommentCount: 0,
		IsPublic:     visible,
		IsDelete:     0,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := Db.Create(&contentModel).Error; err != nil {
		return 0, fmt.Errorf("发布内容失败：%w", err)
	}

	return contentModel.ID, nil
}

func ContentFilter(city, year, mood string, page, size int) (*model.ContentListResp, error) {
	if page < 1 {
		page = 1
	}
	if size < 1 || size > 50 {
		size = 10
	}
	offset := (page - 1) * size

	var list []model.Content
	var total int64

	query := Db.Model(&model.Content{}).Where("is_delete = ?", 0)
	if city != "" {
		query = query.Where("city = ?", city)
	}
	if year != "" {
		query = query.Where("year = ?", year)
	}
	if mood != "" {
		query = query.Where("mood = ?", mood)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("筛选内容总数失败：%w", err)
	}
	if err := query.Order("created_at DESC").Offset(offset).Limit(size).Find(&list).Error; err != nil {
		return nil, fmt.Errorf("筛选内容列表失败：%w", err)
	}

	resp := &model.ContentListResp{
		List:  list,
		Total: total,
	}
	return resp, nil
}

func MapList(req *model.MapListReq) (*model.MapListResp, error) {
	if req.LatMin.IsZero() || req.LatMax.IsZero() || req.LngMin.IsZero() || req.LngMax.IsZero() {
		return &model.MapListResp{List: []model.Content{}, Total: 0}, nil
	}

	if req.Page <= 0 {
		req.Page = 1
	}
	if req.Size <= 0 || req.Size > 50 {
		req.Size = 10
	}
	offset := (req.Page - 1) * req.Size

	query := Db.Model(&model.Content{}).
		Preload("User").
		Where("is_delete = 0 AND visible = 1").
		Where("latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?",
			req.LatMin, req.LatMax, req.LngMin, req.LngMax).
		Where("city = ?", req.City)

	if req.City != "" {
		query = query.Where("city LIKE ?", "%"+req.City+"%")
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("查询总数失败: %w", err)
	}

	var contents []model.Content
	if err := query.
		Order("created_at DESC").
		Offset(offset).
		Limit(req.Size).
		Find(&contents).Error; err != nil {
		return nil, fmt.Errorf("查询列表失败: %w", err)
	}

	resp := &model.MapListResp{
		List:  contents,
		Total: total,
	}
	return resp, nil
}

// decodeDataURLImage 处理 data:image/ 格式
func decodeDataURLImage(dataURL string) ([]byte, string, error) {
	// 格式: data:image/jpeg;base64,/9j/4AAQ...
	parts := strings.SplitN(dataURL, ",", 2)
	if len(parts) != 2 {
		return nil, "", errors.New("无效的dataURL格式")
	}

	// 解析MIME类型
	mimePart := parts[0]
	if !strings.HasPrefix(mimePart, "data:image/") {
		return nil, "", errors.New("非图片dataURL")
	}

	// 提取MIME类型
	mimeParts := strings.Split(strings.TrimPrefix(mimePart, "data:"), ";")
	if len(mimeParts) == 0 {
		return nil, "", errors.New("无法解析MIME类型")
	}

	mimeType := mimeParts[0]

	// 解码Base64
	imgData, err := base64.StdEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, "", fmt.Errorf("Base64解码失败: %w", err)
	}

	if len(imgData) == 0 {
		return nil, "", errors.New("解码后数据为空")
	}

	detectedType := http.DetectContentType(imgData)
	if !strings.HasPrefix(detectedType, "image/") {
		return nil, "", fmt.Errorf("非图片数据: %s", detectedType)
	}

	return imgData, mimeType, nil
}

// decodeBase64Image 处理纯Base64格式
func decodeBase64Image(base64Data string) ([]byte, string, error) {
	// 解码
	imgData, err := base64.StdEncoding.DecodeString(base64Data)
	if err != nil {
		return nil, "", fmt.Errorf("Base64解码失败: %w", err)
	}

	// 验证
	if len(imgData) == 0 {
		return nil, "", errors.New("解码后数据为空")
	}

	// 检测类型
	mimeType := http.DetectContentType(imgData)
	if !strings.HasPrefix(mimeType, "image/") {
		return nil, "", fmt.Errorf("非图片数据: %s", mimeType)
	}

	return imgData, mimeType, nil
}

// isLikelyBase64 判断是否是Base64字符串
func isLikelyBase64(str string) bool {
	if len(str) < 100 {
		return false
	}

	// Base64特征：只包含特定字符，长度是4的倍数
	validChars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
	for _, ch := range str {
		if !strings.ContainsRune(validChars, ch) {
			return false
		}
	}

	// 排除URL特征
	if strings.Contains(str, "://") ||
		strings.Contains(str, "www.") ||
		strings.Contains(str, ".com") ||
		strings.Contains(str, ".cn") {
		return false
	}

	return true
}

// ContentList 首页内容展示
func ContentList(page, size int) (*model.ContentListResp, error) {
	if page < 1 {
		page = 1
	}
	if size < 1 {
		size = 10
	}
	offset := (page - 1) * size

	var list []model.Content
	var total int64

	query := Db.Model(&model.Content{}).Where("is_delete = ? AND is_public = ?", 0, true)
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("查询内容总数失败: %w", err)
	}

	if err := query.Order("created_at DESC").Offset(offset).Limit(size).Find(&list).Error; err != nil {
		return nil, fmt.Errorf("查询内容列表失败: %w", err)
	}

	resp := &model.ContentListResp{
		List:  list,
		Total: total,
	}
	return resp, nil
}

func ContentDetail(contentID string) (*model.ContentDetailResp, error) {
	cid, err := parseInt64Safe(contentID)
	if err != nil {
		return nil, fmt.Errorf("内容ID格式错误：%w", err)
	}

	var content model.Content
	if err := Db.Where("id = ? AND is_delete = ?", cid, 0).First(&content).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, errors.New("内容不存在或已删除")
		}
		return nil, fmt.Errorf("查询内容详情失败：%w", err)
	}

	var count int64
	if err := Db.Model(model.Collect{}).Where("content_id = ? AND is_cancel = ?", cid, 0).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("查询内容详情失败：%w", err)
	}

	aiResult, err := AIAnalyzeText(content.Content)
	if err != nil {
		summary := content.Content
		if len(summary) > 100 {
			summary = summary[:100]
		}

		aiResult = &model.AISearchAnalysis{
			Summary:     summary,
			Suggestions: []string{content.City, content.Mood, "城市探索"},
			Highlights:  []string{content.Title, content.City},
			Guide:       "继续探索更多城市记忆",
		}
	}

	images := []string(content.Images)

	resp := &model.ContentDetailResp{
		UserId:       content.UserID,
		ContentID:    content.ID,
		Title:        content.Title,
		Content:      content.Content,
		City:         content.City,
		Year:         content.Year,
		Mood:         content.Mood,
		Images:       images,
		LikeCount:    content.LikeCount,
		CommentCount: content.CommentCount,
		Summary:      aiResult.Summary,
		Tags:         aiResult.Suggestions,
		CollectCount: count,
	}

	return resp, nil
}

func ContentDelete(userID, contentID string) error {
	uid, err := parseInt64Safe(userID)
	if err != nil {
		return fmt.Errorf("用户ID格式错误：%w", err)
	}
	cid, err := parseInt64Safe(contentID)
	if err != nil {
		return fmt.Errorf("内容ID格式错误：%w", err)
	}

	result := Db.Model(&model.Content{}).
		Where("id = ? AND user_id = ? AND is_delete = ?", cid, uid, 0).
		Updates(map[string]interface{}{
			"is_delete":  1,
			"updated_at": time.Now(),
		})
	if result.Error != nil {
		return fmt.Errorf("删除内容失败：%w", result.Error)
	}
	if result.RowsAffected == 0 {
		return errors.New("无权限删除该内容或内容不存在")
	}

	return nil
}

func ContentMy(userID string, page, size int) (*model.ContentMyResp, error) {
	uid, err := parseInt64Safe(userID)
	if err != nil {
		return nil, fmt.Errorf("用户ID格式错误：%w", err)
	}

	if page < 1 {
		page = 1
	}
	if size < 1 || size > 50 {
		size = 10
	}
	offset := (page - 1) * size

	var list []model.Content
	var total int64

	query := Db.Model(&model.Content{}).Where("user_id = ? AND is_delete = ?", uid, 0)
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("查询我的发布总数失败：%w", err)
	}
	if err := query.Order("created_at DESC").Offset(offset).Limit(size).Find(&list).Error; err != nil {
		return nil, fmt.Errorf("查询我的发布列表失败：%w", err)
	}

	var count int64
	var contentids []int64
	for _, v := range list {
		contentids = append(contentids, v.ID)
	}

	if err := Db.Model(&model.Collect{}).
		Where("content_id IN (?) AND is_cancel = ?", contentids, 0).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("查询收藏总数失败：%w", err)
	}

	resp := &model.ContentMyResp{
		CL: &model.ContentListResp{
			List:  list,
			Total: total,
		},
		CollectCount: count,
	}
	return resp, nil
}

func ContentSearch(keyword string, page, size int) (*model.ContentSearchResp, error) {
	keyword = strings.TrimSpace(keyword)
	if keyword == "" {
		return &model.ContentSearchResp{
			CList: []model.C_List{},
			UList: []model.U_List{},
		}, nil
	}

	if page < 1 {
		page = 1
	}
	if size < 1 || size > 50 {
		size = 10
	}

	key := "%" + keyword + "%"

	resp := &model.ContentSearchResp{
		CList: []model.C_List{},
		UList: []model.U_List{},
	}

	// 搜索内容（按优先级：city > title > content）
	contentList, contentTotal, err := searchContentsWithPriority(key, page, size)
	if err != nil {
		return nil, fmt.Errorf("搜索内容失败：%w", err)
	}

	// 搜索用户（按用户名匹配）
	userList, userTotal, err := searchUsers(key, page, size)
	if err != nil {
		return nil, fmt.Errorf("搜索用户失败：%w", err)
	}

	resp.CList = append(resp.CList, model.C_List{
		Content: contentList,
		Total:   contentTotal,
	})

	resp.UList = append(resp.UList, model.U_List{
		User:  userList,
		Total: userTotal,
	})

	fmt.Println(resp)

	return resp, nil
}

// 搜索内容（按优先级）
func searchContentsWithPriority(keywordPattern string, page, size int) ([]model.Content, int64, error) {
	offset := (page - 1) * size

	var total int64
	countQuery := Db.Model(&model.Content{}).
		Where("is_delete = ? AND is_public = ?", 0, true).
		Where("city LIKE ? OR title LIKE ? OR content LIKE ?",
			keywordPattern, keywordPattern, keywordPattern)

	if err := countQuery.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var contents []model.Content

	sql := `
        SELECT * FROM contents 
        WHERE is_delete = 0 
          AND is_public = 1
          AND (city LIKE ? OR title LIKE ? OR content LIKE ?)
        ORDER BY 
            CASE 
                WHEN city LIKE ? THEN 1
                WHEN title LIKE ? THEN 2
                WHEN content LIKE ? THEN 3
                ELSE 4
            END ASC, 
            created_at DESC
        LIMIT ? OFFSET ?
    `

	err := Db.Raw(sql,
		keywordPattern, keywordPattern, keywordPattern,
		keywordPattern, keywordPattern, keywordPattern,
		size, offset,
	).Scan(&contents).Error

	if err != nil {
		return nil, 0, err
	}

	return contents, total, nil
}

// 搜索用户
func searchUsers(keywordPattern string, page, size int) ([]model.User, int64, error) {
	offset := (page - 1) * size

	var total int64
	countQuery := Db.Model(&model.User{}).
		Where("username LIKE ? OR nickname LIKE ?",
			keywordPattern, keywordPattern)

	if err := countQuery.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var users []model.User
	query := Db.Model(&model.User{}).
		Where("username LIKE ? OR nickname LIKE ?",
			keywordPattern, keywordPattern)

	err := query.
		Offset(offset).
		Limit(size).
		Find(&users).Error

	if err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

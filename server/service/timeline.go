package service

import (
	"fmt"
	"log"
	"shiguangji/model"
)

// TimelineMy 我的时间轴（按年月分组展示用户发布的内容）
func TimelineMy(userID, year string) (map[string][]model.Content, error) {
	uid, err := parseInt64Safe(userID)
	if err != nil {
		log.Printf("[TimelineMy] 用户ID格式错误：userID=%s, err=%v", userID, err)
		return nil, fmt.Errorf("用户ID格式错误：%w", err)
	}

	query := Db.Model(&model.Content{}).Where("user_id = ? AND is_delete = ?", uid, 0)

	if year != "" {
		if len(year) == 4 {
			query = query.Where("year LIKE ?", year+"%")
		} else if len(year) == 7 {
			query = query.Where("year LIKE ?", year+"%")
		} else if len(year) == 10 {
			query = query.Where("year = ?", year)
		}
	}

	var list []model.Content
	if err := query.Order("created_at DESC").Find(&list).Error; err != nil {
		log.Printf("[TimelineMy] 查询时间轴失败：userID=%s, year=%s, err=%v", userID, year, err)
		return nil, fmt.Errorf("查询时间轴失败：%w", err)
	}

	result := make(map[string][]model.Content)
	for _, content := range list {
		month := content.CreatedAt.Format("2006-01")
		result[month] = append(result[month], content)
	}

	log.Printf("[TimelineMy] 查询时间轴成功：userID=%s, year=%s, 内容总数=%d, 分组数=%d",
		userID, year, len(list), len(result))
	return result, nil
}

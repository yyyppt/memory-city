package service

import (
	"errors"
	"fmt"
	"shiguangji/model"
	"strconv"
	"time"

	"gorm.io/gorm"
)

func parseInt64Safe(s string) (int64, error) {
	if s == "" {
		return 0, errors.New("字符串为空")
	}
	res, err := strconv.ParseInt(s, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("转换失败：%s", s)
	}
	return res, nil
}

// InteractLike 点赞/取消点赞
func InteractLike(userID, contentID string) (int64, bool, error) {
	uid, err := parseInt64Safe(userID)
	if err != nil {
		return 0, false, fmt.Errorf("用户ID格式错误：%w", err)
	}
	cid, err := parseInt64Safe(contentID)
	if err != nil {
		return 0, false, fmt.Errorf("内容ID格式错误：%w", err)
	}

	tx := Db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	var content model.Content
	if err := tx.Where("id = ? AND is_delete = ?", cid, 0).First(&content).Error; err != nil {
		tx.Rollback()
		if err == gorm.ErrRecordNotFound {
			return 0, false, errors.New("内容不存在或已删除")
		}
		return 0, false, fmt.Errorf("查询内容失败：%w", err)
	}

	var like model.Like
	err = tx.Where("user_id = ? AND content_id = ?", uid, cid).First(&like).Error
	switch {
	case err == gorm.ErrRecordNotFound:
		like = model.Like{
			UserID:    uid,
			ContentID: cid,
			CreatedAt: time.Now(),
			IsCancel:  0,
		}
		if err := tx.Create(&like).Error; err != nil {
			tx.Rollback()
			return 0, false, fmt.Errorf("点赞失败：%w", err)
		}
		if err := tx.Model(&content).Update("like_count", gorm.Expr("like_count + ?", 1)).Error; err != nil {
			tx.Rollback()
			return 0, false, fmt.Errorf("更新点赞数失败：%w", err)
		}

	case err == nil:
		delta := 1
		newStatus := 1 - like.IsCancel
		if newStatus == 1 {
			delta = -1
		}

		like.IsCancel = newStatus
		like.UpdatedAt = time.Now()
		if err := tx.Save(&like).Error; err != nil {
			tx.Rollback()
			return 0, false, fmt.Errorf("修改点赞状态失败：%w", err)
		}

		isLiked := newStatus == 0
		if err := tx.Model(&content).Update("like_count", gorm.Expr("like_count + ?", delta)).Error; err != nil {
			tx.Rollback()
			return 0, isLiked, fmt.Errorf("更新点赞数失败：%w", err)
		}

	default:
		tx.Rollback()
		return 0, false, fmt.Errorf("查询点赞状态失败：%w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return 0, false, fmt.Errorf("事务提交失败：%w", err)
	}

	if err := Db.Where("id = ?", cid).First(&content).Error; err != nil {
		return 0, false, fmt.Errorf("查询最新点赞数失败：%w", err)
	}
	return content.LikeCount, like.IsCancel == 0, nil
}

// CommentLike 评论点赞
func CommentLike(userID, commentID string) (int64, bool, error) {
	uid, err := parseInt64Safe(userID)
	if err != nil {
		return 0, false, fmt.Errorf("用户ID格式错误：%w", err)
	}
	cid, err := parseInt64Safe(commentID)
	if err != nil {
		return 0, false, fmt.Errorf("评论ID格式错误：%w", err)
	}

	tx := Db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	var comment model.Comment
	if err := tx.Where("id = ? AND is_delete = ?", cid, 0).First(&comment).Error; err != nil {
		tx.Rollback()
		if err == gorm.ErrRecordNotFound {
			return 0, false, errors.New("评论不存在或已删除")
		}
		return 0, false, fmt.Errorf("查询评论失败：%w", err)
	}

	var like model.CommentLike
	err = tx.Where("comment_id = ? AND user_id = ?", cid, uid).First(&like).Error

	switch {
	case err == gorm.ErrRecordNotFound:
		like = model.CommentLike{
			CommentID: cid,
			UserID:    uid,
			IsCancel:  0,
			CreatedAt: time.Now(),
		}
		if err := tx.Create(&like).Error; err != nil {
			tx.Rollback()
			return 0, false, fmt.Errorf("点赞失败：%w", err)
		}
		if err := tx.Model(&comment).Update("like_count", gorm.Expr("like_count + ?", 1)).Error; err != nil {
			tx.Rollback()
			return 0, false, fmt.Errorf("更新点赞数失败：%w", err)
		}
		comment.LikeCount++

	case err == nil:
		delta := 1
		newStatus := 1 - like.IsCancel
		if newStatus == 1 {
			delta = -1
		}

		like.IsCancel = newStatus
		like.UpdatedAt = time.Now()
		if err := tx.Save(&like).Error; err != nil {
			tx.Rollback()
			return 0, false, fmt.Errorf("修改点赞状态失败：%w", err)
		}

		if err := tx.Model(&comment).Update("like_count", gorm.Expr("like_count + ?", delta)).Error; err != nil {
			tx.Rollback()
			return 0, false, fmt.Errorf("更新点赞数失败：%w", err)
		}
		comment.LikeCount += int64(delta)

	default:
		tx.Rollback()
		return 0, false, fmt.Errorf("查询点赞状态失败：%w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return 0, false, fmt.Errorf("事务提交失败：%w", err)
	}

	isLiked := like.IsCancel == 0
	return comment.LikeCount, isLiked, nil
}

// 发布评论   一级/多级
func InteractComment(userID, commentContent, parentID string, contentID int64) (*model.Comment, error) {
	uid, err := parseInt64Safe(userID)
	if err != nil {
		return nil, fmt.Errorf("用户ID格式错误：%w", err)
	}
	cid := contentID

	var pid *int64 = nil
	if parentID != "" && parentID != "0" {
		parsed, err := parseInt64Safe(parentID)
		if err != nil {
			return nil, fmt.Errorf("父评论ID格式错误：%w", err)
		}
		pid = &parsed
	}

	if commentContent == "" {
		return nil, errors.New("评论内容不能为空")
	}

	tx := Db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	var content model.Content
	if err := tx.Where("id = ? AND is_delete = ?", cid, 0).First(&content).Error; err != nil {
		tx.Rollback()
		if err == gorm.ErrRecordNotFound {
			return nil, errors.New("内容不存在或已删除")
		}
		return nil, fmt.Errorf("查询内容失败：%w", err)
	}

	if pid != nil {
		var parentComment model.Comment
		if err := tx.Where("id = ? AND content_id = ? AND is_delete = 0", *pid, cid).First(&parentComment).Error; err != nil {
			tx.Rollback()
			if err == gorm.ErrRecordNotFound {
				return nil, errors.New("父评论不存在")
			}
			return nil, fmt.Errorf("查询父评论失败：%w", err)
		}
	}

	comment := model.Comment{
		UserID:    uid,
		ContentID: cid,
		ParentID:  pid,
		Content:   commentContent,
		CreatedAt: time.Now(),
	}

	if err := tx.Create(&comment).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("发布评论失败：%w", err)
	}

	if err := tx.Model(&content).Update("comment_count", gorm.Expr("comment_count + ?", 1)).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("更新评论数失败：%w", err)
	}

	if err := tx.Preload("User").First(&comment, comment.ID).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("查询评论详情失败：%w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("事务提交失败：%w", err)
	}

	return &comment, nil
}

// 评论列表  一级评论 parent_id IS NULL
func InteractCommentList(contentID string, page, size, depth int) (*model.CommentListResp, error) {
	cid, err := parseInt64Safe(contentID)
	if err != nil {
		return nil, fmt.Errorf("内容ID格式错误：%w", err)
	}

	if page < 1 {
		page = 1
	}
	if size < 1 || size > 50 {
		size = 10
	}
	offset := (page - 1) * size

	var total int64
	if err := Db.Model(&model.Comment{}).
		Where("content_id = ? AND parent_id IS NULL AND is_delete = 0", cid).
		Count(&total).Error; err != nil {
		return nil, fmt.Errorf("查询评论总数失败：%w", err)
	}

	var comments []model.Comment
	if err := Db.
		Preload("User").
		Where("content_id = ? AND parent_id IS NULL AND is_delete = 0", cid).
		Order("created_at DESC").
		Offset(offset).
		Limit(size).
		Find(&comments).Error; err != nil {
		return nil, fmt.Errorf("查询评论列表失败：%w", err)
	}

	for i := range comments {
		if err := loadCommentReplies(&comments[i], depth, 1); err != nil {
			return nil, fmt.Errorf("加载子评论失败：%w", err)
		}
	}

	return &model.CommentListResp{
		List:  comments,
		Total: total,
	}, nil
}

func loadCommentReplies(comment *model.Comment, maxDepth, currentDepth int) error {
	if currentDepth >= maxDepth {
		return nil
	}

	var replies []model.Comment
	if err := Db.
		Preload("User").
		Where("parent_id = ? AND is_delete = 0", comment.ID).
		Order("created_at ASC").
		Find(&replies).Error; err != nil {
		return err
	}

	for i := range replies {
		if err := loadCommentReplies(&replies[i], maxDepth, currentDepth+1); err != nil {
			return err
		}
	}

	comment.Replies = make([]*model.Comment, len(replies))
	for i := range replies {
		comment.Replies[i] = &replies[i]
	}
	return nil
}

// InteractCollect 收藏/取消收藏
func InteractCollect(userID, contentID string) (bool, int64, error) {
	uid, err := parseInt64Safe(userID)
	if err != nil {
		return false, 0, fmt.Errorf("用户ID格式错误：%w", err)
	}
	cid, err := parseInt64Safe(contentID)
	if err != nil {
		return false, 0, fmt.Errorf("内容ID格式错误：%w", err)
	}

	tx := Db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	var content model.Content
	if err := tx.Where("id = ? AND is_delete = ?", cid, 0).First(&content).Error; err != nil {
		tx.Rollback()
		if err == gorm.ErrRecordNotFound {
			return false, 0, errors.New("内容不存在或已删除")
		}
		return false, 0, fmt.Errorf("查询内容失败：%w", err)
	}

	var collect model.Collect
	err = tx.Where("user_id = ? AND content_id = ?", uid, cid).First(&collect).Error

	var isCollected bool
	var count int64

	switch {
	case err == gorm.ErrRecordNotFound:
		collect = model.Collect{
			UserID:    uid,
			ContentID: cid,
			CreatedAt: time.Now(),
			IsCancel:  0,
		}
		if err := tx.Create(&collect).Error; err != nil {
			tx.Rollback()
			return false, 0, fmt.Errorf("收藏失败：%w", err)
		}
		isCollected = true

	case err == nil:
		collect.IsCancel = 1 - collect.IsCancel
		collect.UpdatedAt = time.Now()
		if err := tx.Save(&collect).Error; err != nil {
			tx.Rollback()
			return false, 0, fmt.Errorf("修改收藏状态失败：%w", err)
		}
		isCollected = (collect.IsCancel == 0) // 0=已收藏, 1=已取消

	default:
		tx.Rollback()
		return false, 0, fmt.Errorf("查询收藏状态失败：%w", err)
	}

	if err := tx.Model(&model.Collect{}).
		Where("content_id = ? AND is_cancel = ?", cid, 0).
		Count(&count).Error; err != nil {
		tx.Rollback()
		return false, 0, fmt.Errorf("统计收藏数失败：%w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return false, 0, fmt.Errorf("事务提交失败：%w", err)
	}

	return isCollected, count, nil
}

// InteractCollectMy 我的收藏
func InteractCollectMy(userID string, page, size int) (*model.ContentListResp, error) {
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

	var collectIDs []int64
	if err := Db.Table("collects").
		Where("user_id = ? AND is_cancel = ?", uid, 0).
		Pluck("content_id", &collectIDs).Error; err != nil {
		return nil, fmt.Errorf("查询收藏ID失败：%w", err)
	}

	if len(collectIDs) == 0 {
		return &model.ContentListResp{List: []model.Content{}, Total: 0}, nil
	}

	var list []model.Content
	var total int64

	query := Db.Model(&model.Content{}).
		Where("id IN (?) AND is_delete = ?", collectIDs, 0)

	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("查询收藏内容总数失败：%w", err)
	}

	if err := query.Order("created_at DESC").Offset(offset).Limit(size).Find(&list).Error; err != nil {
		return nil, fmt.Errorf("查询收藏内容列表失败：%w", err)
	}

	return &model.ContentListResp{
		List:  list,
		Total: total,
	}, nil
}

func CommentDelete(deleteone string, commentid, deletedone int64) (*model.CommentDeleteResp, error) {
	uid, err := parseInt64Safe(deleteone)
	if err != nil || uid != deletedone {
		return nil, fmt.Errorf("无权删除评论")
	}

	var targetComment model.Comment
	err = Db.Where("id = ? AND is_delete = 0", commentid).First(&targetComment).Error
	if err != nil {
		return nil, fmt.Errorf("评论不存在")
	}

	if targetComment.UserID != deletedone {
		return nil, fmt.Errorf("无权删除他人评论")
	}

	allCommentIDs := []int64{commentid}

	var findChildComments func(parentID int64)
	findChildComments = func(parentID int64) {
		var childComments []model.Comment
		Db.Where("parent_id = ? AND is_delete = 0", parentID).Find(&childComments)

		for _, child := range childComments {
			allCommentIDs = append(allCommentIDs, child.ID)
			findChildComments(child.ID)
		}
	}

	findChildComments(commentid)

	result := Db.Model(&model.Comment{}).
		Where("id IN (?)", allCommentIDs).
		Updates(map[string]interface{}{
			"is_delete": 1,
		})

	if result.Error != nil {
		return nil, fmt.Errorf("删除失败: %v", result.Error)
	}

	return &model.CommentDeleteResp{
		DeletedCommentId: allCommentIDs,
		DeletedCount:     int64(len(allCommentIDs)),
	}, nil
}

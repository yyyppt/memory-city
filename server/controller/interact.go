package controller

import (
	"log"
	"net/http"
	"shiguangji/service"
	"shiguangji/utils"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
)

// InteractLike 点赞/取消点赞
func InteractLike(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		log.Printf("[InteractLike] 操作失败：未获取到user_id")
		utils.Fail(c, http.StatusUnauthorized, "未登录或登录态失效")
		return
	}
	userID, ok := userIDVal.(string)
	if !ok || userID == "" {
		log.Printf("[InteractLike] 用户ID格式错误：userIDVal=%v", userIDVal)
		utils.Fail(c, http.StatusBadRequest, "用户ID格式错误")
		return
	}

	var req struct {
		ContentID string `json:"content_id" binding:"required" label:"内容ID"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		errMsg := utils.TranslateBindingError(err, &req)
		log.Printf("[InteractLike] 参数绑定失败：userID=%s, err=%v", userID, err)
		utils.Fail(c, http.StatusBadRequest, "参数错误："+errMsg)
		return
	}

	log.Printf("[InteractLike] 点赞/取消点赞：userID=%s, contentID=%s", userID, req.ContentID)
	likeCount, is_liked, err := service.InteractLike(userID, req.ContentID)
	if err != nil {
		log.Printf("[InteractLike] 操作失败：userID=%s, contentID=%s, err=%v", userID, req.ContentID, err)

		switch err.Error() {
		case "内容ID格式错误", "内容不存在或已删除":
			utils.Fail(c, http.StatusBadRequest, "操作失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "操作失败："+err.Error())
		}
		return
	}

	log.Printf("[InteractLike] 操作成功：userID=%s, contentID=%s, likeCount=%d", userID, req.ContentID, likeCount)
	utils.Success(c, gin.H{
		"like_count": likeCount,
		"is_liked":   is_liked,
	})
}

// CommentLike 评论点赞/取消点赞
func CommentLike(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		log.Printf("[CommentLike] 操作失败：未获取到user_id")
		utils.Fail(c, http.StatusUnauthorized, "未登录或登录态失效")
		return
	}
	userID, ok := userIDVal.(string)
	if !ok || userID == "" {
		log.Printf("[CommentLike] 用户ID格式错误：userIDVal=%v", userIDVal)
		utils.Fail(c, http.StatusBadRequest, "用户ID格式错误")
		return
	}

	var req struct {
		CommentID string `json:"comment_id" binding:"required" label:"评论ID"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		errMsg := utils.TranslateBindingError(err, &req)
		log.Printf("[CommentLike] 参数绑定失败：userID=%s, err=%v", userID, err)
		utils.Fail(c, http.StatusBadRequest, "参数错误："+errMsg)
		return
	}

	log.Printf("[CommentLike] 评论点赞/取消点赞：userID=%s, commentID=%s", userID, req.CommentID)
	likeCount, isLiked, err := service.CommentLike(userID, req.CommentID)
	if err != nil {
		log.Printf("[CommentLike] 操作失败：userID=%s, commentID=%s, err=%v", userID, req.CommentID, err)

		switch err.Error() {
		case "评论ID格式错误", "评论不存在或已删除":
			utils.Fail(c, http.StatusBadRequest, "操作失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "操作失败："+err.Error())
		}
		return
	}

	log.Printf("[CommentLike] 操作成功：userID=%s, commentID=%s, likeCount=%d", userID, req.CommentID, likeCount)
	utils.Success(c, gin.H{
		"like_count": likeCount,
		"is_liked":   isLiked,
	})
}

// InteractComment 发布评论  多级
func InteractComment(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		utils.Fail(c, http.StatusUnauthorized, "未登录或登录态失效")
		return
	}
	userID, ok := userIDVal.(string)
	if !ok || userID == "" {
		utils.Fail(c, http.StatusBadRequest, "用户ID格式错误")
		return
	}

	var req struct {
		ContentID int64  `json:"content_id" binding:"required" label:"内容ID"`
		Content   string `json:"content" binding:"required,min=1,max=500" label:"评论内容"`
		ParentID  string `json:"parent_id" label:"父评论ID"` // 新增：0或空=一级评论
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		errMsg := utils.TranslateBindingError(err, &req)
		log.Printf("[InteractComment] 参数绑定失败：userID=%s, err=%v", userID, err)
		utils.Fail(c, http.StatusBadRequest, "参数错误："+errMsg)
		return
	}

	log.Printf("[InteractComment] 发布评论：userID=%s, contentID=%s, parentID=%s",
		userID, req.ContentID, req.ParentID)

	comment, err := service.InteractComment(userID, req.Content, req.ParentID, req.ContentID)
	if err != nil {
		log.Printf("[InteractComment] 发布失败：userID=%s, contentID=%s, err=%v",
			userID, req.ContentID, err)

		switch err.Error() {
		case "内容ID格式错误", "内容不存在或已删除", "评论内容不能为空", "父评论不存在":
			utils.Fail(c, http.StatusBadRequest, "发布评论失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "发布评论失败："+err.Error())
		}
		return
	}

	log.Printf("[InteractComment] 发布成功：userID=%s, contentID=%s, commentID=%d",
		userID, req.ContentID, comment.ID)
	utils.Success(c, comment)
}

// InteractCommentList 评论列表   多级
func InteractCommentList(c *gin.Context) {
	contentID := c.Query("content_id")
	if contentID == "" {
		utils.Fail(c, http.StatusBadRequest, "内容ID不能为空")
		return
	}

	pageStr := c.DefaultQuery("page", "1")
	sizeStr := c.DefaultQuery("size", "10")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}
	size, err := strconv.Atoi(sizeStr)
	if err != nil || size < 1 || size > 50 {
		size = 10
	}

	depthStr := c.DefaultQuery("depth", "2") // 默认显示2级嵌套
	depth, _ := strconv.Atoi(depthStr)
	if depth < 1 {
		depth = 2
	}
	if depth > 5 { // 限制最大嵌套深度
		depth = 5
	}

	log.Printf("[InteractCommentList] 查询评论列表：contentID=%s, page=%d, size=%d, depth=%d",
		contentID, page, size, depth)

	list, err := service.InteractCommentList(contentID, page, size, depth)
	if err != nil {
		log.Printf("[InteractCommentList] 查询失败：contentID=%s, page=%d, size=%d, err=%v",
			contentID, page, size, err)

		switch err.Error() {
		case "内容ID格式错误", "内容不存在或已删除":
			utils.Fail(c, http.StatusBadRequest, "查询评论失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "查询评论失败："+err.Error())
		}
		return
	}

	utils.Success(c, list)
}

// InteractCollect 收藏/取消收藏
func InteractCollect(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		utils.Fail(c, http.StatusUnauthorized, "未登录或登录态失效")
		return
	}
	userID, ok := userIDVal.(string)
	if !ok || userID == "" {
		utils.Fail(c, http.StatusBadRequest, "用户ID格式错误")
		return
	}

	contentID := c.Query("content_id")
	if contentID == "" {
		utils.Fail(c, http.StatusBadRequest, "内容ID不能为空")
		return
	}

	log.Printf("[InteractCollect] 收藏/取消收藏：userID=%s, contentID=%s", userID, contentID)
	is_collected, count, err := service.InteractCollect(userID, contentID)
	if err != nil {
		log.Printf("[InteractCollect] 操作失败：userID=%s, contentID=%s, err=%v", userID, contentID, err)

		switch err.Error() {
		case "内容ID格式错误", "内容不存在或已删除":
			utils.Fail(c, http.StatusBadRequest, "操作失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "操作失败："+err.Error())
		}
		return
	}

	log.Printf("[InteractCollect] 操作成功：userID=%s, contentID=%s", userID, contentID)
	c.JSON(200, gin.H{
		"is_collected":  is_collected,
		"collect_count": count,
	})
}

// InteractCollectMy 我的收藏
func InteractCollectMy(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		utils.Fail(c, http.StatusUnauthorized, "未登录或登录态失效")
		return
	}
	userID, ok := userIDVal.(string)
	if !ok || userID == "" {
		utils.Fail(c, http.StatusBadRequest, "用户ID格式错误")
		return
	}

	pageStr := c.DefaultQuery("page", "1")
	sizeStr := c.DefaultQuery("size", "10")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}
	size, err := strconv.Atoi(sizeStr)
	if err != nil || size < 1 || size > 50 {
		size = 10
	}

	log.Printf("[InteractCollectMy] 查询我的收藏：userID=%s, page=%d, size=%d", userID, page, size)
	list, err := service.InteractCollectMy(userID, page, size)
	if err != nil {
		log.Printf("[InteractCollectMy] 查询失败：userID=%s, page=%d, size=%d, err=%v", userID, page, size, err)

		switch err.Error() {
		case "用户ID格式错误":
			utils.Fail(c, http.StatusBadRequest, "查询收藏失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "查询收藏失败："+err.Error())
		}
		return
	}

	utils.Success(c, list)
}

// controller/comment_controller.go
func DeleteComment(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		utils.Fail(c, http.StatusUnauthorized, "未登录或登录态失效")
		return
	}
	userID, ok := userIDVal.(string)
	if !ok || userID == "" {
		utils.Fail(c, http.StatusBadRequest, "用户ID格式错误")
		return
	}

	var req struct {
		CommentID int64 `json:"comment_id" binding:"required"`
		UserId    int64 `json:"user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		errMsg := utils.TranslateBindingError(err, &req)
		log.Printf("[CommentDelete] 参数绑定失败：userID=%s, err=%v", userID, err)
		utils.Fail(c, http.StatusBadRequest, "参数错误："+errMsg)
		return
	}

	resp, err := service.CommentDelete(userID, req.CommentID, req.UserId)
	if err != nil {
		log.Printf("[CommentDelete] 操作失败：userID=%s, commentID=%d, targetUserID=%d, err=%v",
			userID, req.CommentID, req.UserId, err)

		if strings.Contains(err.Error(), "无权") {
			utils.Fail(c, http.StatusForbidden, err.Error())
		} else if strings.Contains(err.Error(), "不存在") {
			utils.Fail(c, http.StatusNotFound, err.Error())
		} else {
			utils.Fail(c, http.StatusInternalServerError, "操作失败："+err.Error())
		}
		return
	}

	log.Printf("[CommentDelete] 操作成功：userID=%s, commentID=%s", userID, req.CommentID)
	utils.SuccessWithMsg(c, "删除成功", resp)
}

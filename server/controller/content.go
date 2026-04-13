package controller

import (
	"log"
	"net/http"
	"shiguangji/model"
	"shiguangji/service"
	"shiguangji/utils"
	"strconv"

	"github.com/gin-gonic/gin"
)

// ContentPublish 发布内容
func ContentPublish(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Title    string   `json:"title" binding:"required"`
		Content  string   `json:"content" binding:"required"`
		City     string   `json:"city"`
		Year     string   `json:"year"`
		Mood     string   `json:"mood"`
		IsPublic bool     `json:"is_public"`
		Images   []string `json:"images"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误："+err.Error())
		return
	}

	contentID, err := service.ContentPublish(userID.(string), req.Title, req.Content, req.City,
		req.Year, req.Mood, req.IsPublic, req.Images)
	if err != nil {
		utils.Fail(c, 500, "发布失败："+err.Error())
		return
	}

	utils.SuccessWithMsg(c, "发布成功", gin.H{
		"content_id": contentID,
	})
}

// ContentList 内容列表
func ContentList(c *gin.Context) {
	page := c.GetInt("page")
	size := c.GetInt("size")

	list, err := service.ContentList(page, size)
	if err != nil {
		utils.Fail(c, 500, "查询失败："+err.Error())
		return
	}

	utils.Success(c, list)
}

// ContentDetail 内容详情
func ContentDetail(c *gin.Context) {
	contentID := c.Query("content_id")
	if contentID == "" {
		utils.Fail(c, 400, "内容ID不能为空")
		return
	}

	detail, err := service.ContentDetail(contentID)
	if err != nil {
		utils.Fail(c, 500, "查询失败："+err.Error())
		return
	}

	utils.Success(c, detail)
}

// ContentDelete 删除内容
func ContentDelete(c *gin.Context) {
	userID, _ := c.Get("user_id")
	contentID := c.Query("content_id")

	if contentID == "" {
		utils.Fail(c, 400, "内容ID不能为空")
		return
	}

	err := service.ContentDelete(userID.(string), contentID)
	if err != nil {
		utils.Fail(c, 500, "删除失败："+err.Error())
		return
	}

	utils.SuccessWithMsg(c, "删除成功", nil)
}

// ContentMy 我的发布
func ContentMy(c *gin.Context) {
	userID, _ := c.Get("user_id")
	page := c.GetInt("page")
	size := c.GetInt("size")

	list, err := service.ContentMy(userID.(string), page, size)
	if err != nil {
		utils.Fail(c, 500, "查询失败："+err.Error())
		return
	}

	utils.Success(c, list)
}

func ContentSearch(c *gin.Context) {
	keyword := c.Query("keyword")
	if keyword == "" {
		utils.Fail(c, http.StatusBadRequest, "搜索关键词不能为空")
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

	result, err := service.ContentSearch(keyword, page, size)
	if err != nil {
		log.Printf("[SearchContent] 搜索失败：keyword=%s, err=%v", keyword, err)
		utils.Fail(c, http.StatusInternalServerError, "搜索失败："+err.Error())
		return
	}

	utils.Success(c, result)
}

// ContentFilter 内容筛选
func ContentFilter(c *gin.Context) {
	city := c.Query("city")
	year := c.Query("year")
	mood := c.Query("mood")
	page := c.GetInt("page")
	size := c.GetInt("size")

	list, err := service.ContentFilter(city, year, mood, page, size)
	if err != nil {
		utils.Fail(c, 500, "筛选失败："+err.Error())
		return
	}

	utils.Success(c, list)
}

func MapList(c *gin.Context) {
	var req *model.MapListReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误："+err.Error())
		return
	}

	list, err := service.MapList(req)
	if err != nil {
		utils.Fail(c, 500, "查询失败："+err.Error())
		return
	}
	utils.Success(c, list)
}

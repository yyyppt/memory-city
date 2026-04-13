package controller

import (
	"shiguangji/service"
	"shiguangji/utils"

	"github.com/gin-gonic/gin"
)

// AIAnalyze AI文本分析
func AIAnalyze(c *gin.Context) {
	var req struct {
		Text string `json:"text" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误："+err.Error())
		return
	}

	result, err := service.AIAnalyzeText(req.Text)
	if err != nil {
		utils.Fail(c, 500, "AI分析失败："+err.Error())
		return
	}

	utils.Success(c, result)
}

package controller

import (
	"shiguangji/service"
	"shiguangji/utils"

	"github.com/gin-gonic/gin"
)

// UploadToken 获取上传凭证
func UploadToken(c *gin.Context) {
	userID, _ := c.Get("user_id")

	token, err := service.UploadToken(userID.(string))
	if err != nil {
		utils.Fail(c, 500, "获取上传凭证失败："+err.Error())
		return
	}

	utils.Success(c, token)
}

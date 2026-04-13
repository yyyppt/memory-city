package controller

import (
	"shiguangji/service"
	"shiguangji/utils"

	"github.com/gin-gonic/gin"
)

// TimelineMy 我的时间轴
func TimelineMy(c *gin.Context) {
	userID, _ := c.Get("user_id")
	year := c.Query("year")

	timeline, err := service.TimelineMy(userID.(string), year)
	if err != nil {
		utils.Fail(c, 500, "查询时间轴失败："+err.Error())
		return
	}

	utils.Success(c, timeline)
}

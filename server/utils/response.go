package utils

import (
	"github.com/gin-gonic/gin"
)

// Response 统一返回结构体
type Response struct {
	Code int         `json:"code"`
	Msg  string      `json:"msg"`
	Data interface{} `json:"data"`
}

// Success 成功返回
func Success(c *gin.Context, data interface{}) {
	c.JSON(200, Response{
		Code: 200,
		Msg:  "success",
		Data: data,
	})
}

// SuccessWithMsg 自定义成功提示
func SuccessWithMsg(c *gin.Context, msg string, data interface{}) {
	c.JSON(200, Response{
		Code: 200,
		Msg:  msg,
		Data: data,
	})
}

// Fail 失败返回
func Fail(c *gin.Context, code int, msg string) {
	c.JSON(200, Response{
		Code: code,
		Msg:  msg,
		Data: nil,
	})
}

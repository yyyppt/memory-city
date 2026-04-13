package middleware

import (
	"net/http"
	"shiguangji/config"
	"shiguangji/utils"
	"strings"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.FullPath() == "/api/user/login" ||
			c.FullPath() == "/api/user/register" ||
			strings.HasPrefix(c.FullPath(), "/api/content/") &&
				(c.Request.Method == "GET" && !strings.Contains(c.FullPath(), "/my")) {
			c.Next()
			return
		}

		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "msg": "未登录"})
			c.Abort()
			return
		}
		tokenString := authHeader[7:]

		userID, _, err := utils.ParseAccessToken(tokenString, config.AccessSecret, c.ClientIP())
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "msg": "登录已失效"})
			c.Abort()
			return
		}

		c.Set("user_id", userID)
		c.Next()
	}
}

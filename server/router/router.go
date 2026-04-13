package router

import (
	"shiguangji/controller"
	"shiguangji/middleware"

	"github.com/gin-gonic/gin"
)

// InitRouter 初始化路由
func InitRouter() *gin.Engine {
	r := gin.Default()
	r.Use(middleware.Cors())

	api := r.Group("/api")

	// 用户模块
	user := api.Group("/user")
	{
		user.POST("/register", controller.UserRegister)
		user.POST("/login", controller.UserLogin)
		user.GET("/info", middleware.AuthMiddleware(), controller.UserInfo)
		user.PUT("/info", middleware.AuthMiddleware(), controller.UserUpdateInfo)
		user.PUT("/info/updatepassword", middleware.AuthMiddleware(), controller.UserUpdatePassword)
		user.GET("/profile", controller.UserProfile)
		user.POST("/forgetPasswd/fgt", controller.UserFgt)
		user.POST("/forgetPasswd/update", controller.UserUdt)
	}

	// 内容模块
	content := api.Group("/content")
	{
		content.POST("/publish", middleware.AuthMiddleware(), controller.ContentPublish)
		content.GET("/list", controller.ContentList)
		content.GET("/detail", controller.ContentDetail)
		content.DELETE("/delete", middleware.AuthMiddleware(), controller.ContentDelete)
		content.GET("/my", middleware.AuthMiddleware(), controller.ContentMy)
		content.GET("/search", controller.ContentSearch)
		content.GET("/filter", controller.ContentFilter)
		content.GET("/map/list", controller.MapList)
	}

	// 互动模块
	interact := api.Group("/interact")
	{
		interact.POST("/like", middleware.AuthMiddleware(), controller.InteractLike)
		interact.POST("/comment/like", middleware.AuthMiddleware(), controller.CommentLike)
		interact.POST("/comment", middleware.AuthMiddleware(), controller.InteractComment)
		interact.GET("/comment/list", controller.InteractCommentList)
		interact.POST("/collect", middleware.AuthMiddleware(), controller.InteractCollect)
		interact.GET("/collect/my", middleware.AuthMiddleware(), controller.InteractCollectMy)
		interact.DELETE("/comment/delete", middleware.AuthMiddleware(), controller.DeleteComment)
	}

	// AI模块
	ai := api.Group("/ai")
	{
		ai.POST("/analyze", controller.AIAnalyze)
	}

	// 时光轴模块
	timeline := api.Group("/timeline")
	{
		timeline.GET("/my", middleware.AuthMiddleware(), controller.TimelineMy)
	}

	// 上传模块
	upload := api.Group("/upload")
	{
		upload.GET("/token", middleware.AuthMiddleware(), controller.UploadToken)
	}

	return r
}

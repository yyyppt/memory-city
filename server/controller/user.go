package controller

import (
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"shiguangji/service"
	"shiguangji/utils"
)

func UserRegister(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required,min=3,max=20" label:"用户名"`
		Password string `json:"password" binding:"required,min=6,max=32" label:"密码"`
		Nickname string `json:"nickname" binding:"max=20" label:"昵称"`
		Phone 	 string `json:"phone" binding:"required" label:"手机号"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		errMsg := utils.TranslateBindingError(err, &req)
		log.Printf("[UserRegister] 参数绑定失败：ip=%s, err=%v", c.ClientIP(), err)
		utils.Fail(c, http.StatusBadRequest, "参数错误："+errMsg)
		return
	}

	log.Printf("[UserRegister] 用户注册请求：ip=%s, username=%s", c.ClientIP(), req.Username)

	userID, _, err := service.UserRegister(c.ClientIP(), req.Username, req.Password, req.Nickname, req.Phone)
	if err != nil {
		log.Printf("[UserRegister] 注册失败：ip=%s, username=%s, err=%v", c.ClientIP(), req.Username, err)

		switch err.Error() {
		case "用户名已存在", "用户名格式错误", "密码格式错误", "手机号已存在":
			utils.Fail(c, http.StatusBadRequest, "注册失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "注册失败："+err.Error())
		}
		return
	}

	log.Printf("[UserRegister] 注册成功：userID=%d, username=%s", userID, req.Username)
	utils.SuccessWithMsg(c, "注册成功", gin.H{
		"user_id": userID,
	})
}

func UserLogin(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required" label:"用户名"`
		Password string `json:"password" binding:"required" label:"密码"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		errMsg := utils.TranslateBindingError(err, &req)
		log.Printf("[UserLogin] 参数绑定失败：ip=%s, err=%v", c.ClientIP(), err)
		utils.Fail(c, http.StatusBadRequest, "参数错误："+errMsg)
		return
	}

	log.Printf("[UserLogin] 用户登录请求：ip=%s, username=%s", c.ClientIP(), req.Username)
	user, token, rtoken, err := service.UserLogin(req.Username, req.Password, c.ClientIP())
	if err != nil {
		log.Printf("[UserLogin] 登录失败：ip=%s, username=%s, err=%v", c.ClientIP(), req.Username, err)

		switch err.Error() {
		case "用户名不存在", "密码错误", "用户名或密码不能为空":
			utils.Fail(c, http.StatusBadRequest, "登录失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "登录失败："+err.Error())
		}
		return
	}

	log.Printf("[UserLogin] 登录成功：userID=%d, username=%s", user.ID, req.Username)
	utils.SuccessWithMsg(c, "登录成功", gin.H{
		"user_id":      user.ID,
		"nickname":     user.Nickname,
		"avatar":       user.Avatar,
		"token":        token,
		"refreshtoken": rtoken,
	})
}

func UserInfo(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		log.Printf("[UserInfo] 获取用户信息失败：未获取到user_id")
		utils.Fail(c, http.StatusUnauthorized, "未登录或登录态失效")
		return
	}

	userID, ok := userIDVal.(string)
	if !ok || userID == "" {
		log.Printf("[UserInfo] 用户ID格式错误：userIDVal=%v", userIDVal)
		utils.Fail(c, http.StatusBadRequest, "用户ID格式错误")
		return
	}

	log.Printf("[UserInfo] 获取用户信息：userID=%s", userID)
	user, err := service.GetUserInfo(userID)
	if err != nil {
		log.Printf("[UserInfo] 获取失败：userID=%s, err=%v", userID, err)

		switch err.Error() {
		case "用户ID格式错误", "用户不存在":
			utils.Fail(c, http.StatusBadRequest, "获取用户信息失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "获取用户信息失败："+err.Error())
		}
		return
	}

	utils.Success(c, gin.H{
		"user_id":     user.ID,
		"nickname":    user.Nickname,
		"bio":         user.Bio,
		"username":    user.Username,
		"avatar":      user.Avatar,
		"create_time": user.CreateTime.Format("2006-01-02 15:04:05"), // 优化时间格式
	})
}

func UserUpdateInfo(c *gin.Context) {
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
		Nickname string `json:"nickname" binding:"max=20" label:"昵称"`
		Avatar   string `json:"avatar" label:"头像URL"`
		Bio      string `json:"bio" label:"个签"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		errMsg := utils.TranslateBindingError(err, &req)
		log.Printf("[UserUpdateInfo] 参数绑定失败：userID=%s, err=%v", userID, err)
		utils.Fail(c, http.StatusBadRequest, "参数错误："+errMsg)
		return
	}

	if req.Nickname == "" && req.Avatar == "" && req.Bio == "" {
		log.Printf("[UserUpdateInfo] 无修改内容：userID=%s", userID)
		utils.Fail(c, http.StatusBadRequest, "请至少修改昵称或头像其中一项")
		return
	}

	log.Printf("[UserUpdateInfo] 修改用户信息：userID=%s, nickname=%s", userID, req.Nickname)
	user, err := service.UpdateUserInfo(userID, req.Nickname, req.Avatar, req.Bio)
	if err != nil {
		log.Printf("[UserUpdateInfo] 更新失败：userID=%s, err=%v", userID, err)

		switch err.Error() {
		case "用户ID格式错误", "用户不存在":
			utils.Fail(c, http.StatusBadRequest, "更新失败："+err.Error())
		default:
			utils.Fail(c, http.StatusInternalServerError, "更新失败："+err.Error())
		}
		return
	}

	log.Printf("[UserUpdateInfo] 更新成功：userID=%s, nickname=%s", userID, user.Nickname)
	utils.SuccessWithMsg(c, "更新成功", gin.H{
		"nickname": user.Nickname,
		"avatar":   user.Avatar,
	})
}

func UserUpdatePassword(c *gin.Context) {
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
		OldPassword    string `json:"old_password"`
		NewPassword    string `json:"new_password"`
		RepeatPassword string `json:"repeat_passwd"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		errMsg := utils.TranslateBindingError(err, &req)
		log.Printf("[UserUpdatePassword] 参数绑定失败：userID=%s, err=%v", userID, err)
		utils.Fail(c, http.StatusBadRequest, "参数错误："+errMsg)
		return
	}

	if req.OldPassword == "" || req.NewPassword == "" || req.RepeatPassword == "" {
		log.Printf("[UserUpdatePassword] 无修改内容：userID=%s", userID)
		utils.Fail(c, http.StatusBadRequest, "请输入有效数据")
		return
	}
	if req.NewPassword != req.RepeatPassword {
		utils.Fail(c, http.StatusBadRequest, "两次输入密码不一致")
		return
	}

	log.Printf("[UserUpdatePassword] 修改用户密码：userID=%s", userID)
	err := service.UpdateUserPassword(userID, req.OldPassword, req.NewPassword)
	if err != nil {
		log.Printf("[UserUpdatePassword] 更新失败：userID=%s, err=%v", userID, err)

		utils.Fail(c, http.StatusBadRequest, err.Error())
		return
	}

	log.Printf("[UserUpdateInfo] 更新成功：userID=%s", userID)
	utils.Success(c, nil)
}

func UserProfile(c *gin.Context) {
	userID := c.Query("user_id")
    if userID == "" {
		log.Printf("[UserProfile] 参数绑定失败")
        utils.Fail(c, http.StatusBadRequest, "用户ID不能为空")
        return
    }

	data, err := service.UserProfile(userID)
	if err != nil {
        log.Printf("[UserProfile] 查询失败: userID=%s, err=%v", userID, err)
        utils.Fail(c, http.StatusInternalServerError, "系统错误")
        
        return
    }

	utils.Success(c, data)
}

// controllers/user_controller.go
func UserFgt(c *gin.Context) {
	var req struct {
		UserName string `json:"user_name" binding:"required"`
		Phone    string `json:"phone" binding:"required,len=11"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[UserFgt] 绑定失败: err=%v", err)
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}
	
	data, err := service.UserFgt(req.UserName, req.Phone)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.Success(c, data)
}

func UserUdt(c *gin.Context) {
	var req struct {
		UserName   string `json:"user_name" binding:"required"`
		Phone      string `json:"phone" binding:"required,len=11"`
		Code       string `json:"code" binding:"required,len=6"`  // 验证码字段就叫code
		NewPassword string `json:"new_password" binding:"required,min=6"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[UserUdt] 绑定失败: err=%v", err)
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}
	
	err := service.UserUpdatePassword(req.UserName, req.Phone, req.Code, req.NewPassword)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, err.Error())
		return
	}
	
	utils.Success(c, "密码修改成功")
}
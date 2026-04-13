package service

import (
	"errors"
	"fmt"
	"log"
	"math/rand"
	"shiguangji/config"
	"shiguangji/model"
	"shiguangji/utils"
	"strconv"
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	openapi "github.com/alibabacloud-go/darabonba-openapi/v2/client"
	dypnsapi20170525 "github.com/alibabacloud-go/dypnsapi-20170525/v3/client"
	"github.com/alibabacloud-go/tea/tea"
)

// UserRegister 用户注册
func UserRegister(ip, username, password, nickname, phone string) (int64, string, error) {
	var existUser model.User
	if err := Db.Where("username = ?", username).First(&existUser).Error; err != gorm.ErrRecordNotFound {
		return 0, "", errors.New("用户名已存在")
	}
	if err := Db.Where("phone = ?", phone).First(&existUser).Error; err != gorm.ErrRecordNotFound {
		return 0, "", errors.New("手机号已存在")
	}

	hashPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return 0, "", errors.New("密码加密失败")
	}

	user := &model.User{
		Username:   username,
		Password:   string(hashPassword),
		Nickname:   nickname,
		Avatar:     "https://shiguangji-oss.oss-cn-chengdu.aliyuncs.com/defaultAvatar.jpg",
		CreateTime: time.Now(),
		Phone:      phone,
	}
	if err := Db.Create(user).Error; err != nil {
		return 0, "", errors.New("创建用户失败")
	}

	token := utils.CreateToken(
		string(rune(user.ID)),
		config.AccessExp,
		config.AccessSecret,
		config.RefreshExp,
		config.RefreshSecret,
		ip,
	)
	if token == nil {
		return 0, "", errors.New("生成Token失败")
	}

	return user.ID, token.AccessToken, nil
}

// UserLogin 用户登录
func UserLogin(username, password, ip string) (*model.User, string, string, error) {
	var user model.User
	if err := Db.Where("username = ?", username).First(&user).Error; err != nil {
		return nil, "", "", errors.New("用户名或密码错误")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		return nil, "", "", errors.New("用户名或密码错误")
	}

	userId := strconv.Itoa(int(user.ID))
	token := utils.CreateToken(
		userId,
		config.AccessExp,
		config.AccessSecret,
		config.RefreshExp,
		config.RefreshSecret,
		ip,
	)
	if token == nil {
		return nil, "", "", errors.New("生成Token失败")
	}

	return &user, token.AccessToken, token.RefreshToken, nil
}

// GetUserInfo 获取用户信息
func GetUserInfo(userID string) (*model.User, error) {
	var user model.User
	if err := Db.Where("id = ?", userID).First(&user).Error; err != nil {
		return nil, errors.New("数据库查询出错")
	}
	user.Password = ""
	return &user, nil
}

// UpdateUserPassword 修改用户密码
func UpdateUserPassword(userID, oldpassword, newpassword string) error {
	if oldpassword == newpassword {
		return errors.New("前后密码相同")
	}

	var user model.User
	if err := Db.Where("id = ?", userID).First(&user).Error; err != nil {
		return errors.New("数据库查询出错")
	}
	if !checkPasswordHash(oldpassword, user.Password) {
		return errors.New("原密码错误")
	}

	newPasswd, err := bcrypt.GenerateFromPassword([]byte(newpassword), bcrypt.DefaultCost)
	if err != nil {
		log.Println("输入的新密码加密措施失败")
		return errors.New("加密函数对比失败")
	}

	if err := Db.Model(&user).Update("password", string(newPasswd)).Error; err != nil {
		return errors.New("密码更新失败")
	}
	return nil
}
func checkPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func UserProfile(userID string) (*model.User, error) {
	var user model.User
	err := Db.Where("id = ?", userID).First(&user).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("用户不存在")
		}
		return nil, fmt.Errorf("数据库查询失败: %w", err)
	}
	user.Password = ""

	return &user, nil
}

func UserFgt(username, phone string) (string, error) {
	if username == "" || phone == "" {
		return "", errors.New("用户名和手机号不能为空")
	}

	var user model.User
	if err := Db.Where("username = ? AND phone = ?", username, phone).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", errors.New("用户名和手机号不匹配")
		}
		return "", fmt.Errorf("查询用户失败: %v", err)
	}

	code, err := SendSmsVerifyCode(phone)
	if err != nil {
		return "", fmt.Errorf("发送短信验证码失败: %v", err)
	}

	userCode := model.UserCode{
		Username:  username,
		Phone:     phone,
		Code:      code,
		ExpiresAt: time.Now().Add(5 * time.Minute), // 5分钟有效期
		CreatedAt: time.Now(),
		Used:      false,
	}

	var existingCode model.UserCode
	err = Db.Where("username = ? AND phone = ? AND used = ?", username, phone, false).
		First(&existingCode).Error

	if err == nil {
		existingCode.Code = code
		existingCode.ExpiresAt = time.Now().Add(5 * time.Minute)
		existingCode.CreatedAt = time.Now()
		existingCode.Used = false

		if err := Db.Save(&existingCode).Error; err != nil {
			return "", fmt.Errorf("更新验证码失败: %v", err)
		}
	} else if errors.Is(err, gorm.ErrRecordNotFound) {
		if err := Db.Create(&userCode).Error; err != nil {
			return "", fmt.Errorf("创建验证码记录失败: %v", err)
		}
	} else {
		return "", fmt.Errorf("查询验证码记录失败: %v", err)
	}

	return "验证码已发送，5分钟内有效", nil
}

func CreateClient() (*dypnsapi20170525.Client, error) {
	aki := config.OSSAccessKeyID
	aks := config.OSSAccessKeySecret
	config := &openapi.Config{
		AccessKeyId:     tea.String(aki),
		AccessKeySecret: tea.String(aks),
		Endpoint:        tea.String("dypnsapi.aliyuncs.com"),
	}
	return dypnsapi20170525.NewClient(config)
}

func SendSmsVerifyCode(phone string) (string, error) {
	client, err := CreateClient()
	if err != nil {
		return "", err
	}

	code := genCode()

	req := &dypnsapi20170525.SendSmsVerifyCodeRequest{
		PhoneNumber:   tea.String(phone),
		SchemeName:    tea.String("默认方案"),
		SignName:      tea.String("速通互联验证码"),
		TemplateCode:  tea.String("100001"),
		TemplateParam: tea.String(`{"code":"` + code + `","min":"5"}`),
	}

	resp, err := client.SendSmsVerifyCode(req)
	if err != nil {
		return "", err
	}

	fmt.Println("接口返回Code:", tea.StringValue(resp.Body.Code))
	fmt.Println("接口返回Message:", tea.StringValue(resp.Body.Message))
	return code, nil
}
func genCode() string {
	rand.Seed(time.Now().UnixNano())
	return fmt.Sprintf("%06d", rand.Intn(1000000))
}

func UserUpdatePassword(username, phone, code, newpassword string) error {
	var userCode model.UserCode
	if err := Db.Where("username = ? AND phone = ? AND code = ?", username, phone, code).
		First(&userCode).Error; err != nil {
		return errors.New("验证码错误")
	}

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(newpassword), bcrypt.DefaultCost)
	if err := Db.Model(&model.User{}).
		Where("username = ?", username).
		Update("password", hashedPassword).Error; err != nil {
		return errors.New("更新密码失败")
	}

	Db.Where("id = ?", userCode.ID).Delete(&model.UserCode{})

	return nil
}

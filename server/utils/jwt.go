package utils

import (
	"errors"
	"fmt"
	"github.com/golang-jwt/jwt/v4"
	"log"
	"time"
)

// 错误码
const (
	ErrCodeTokenInvalid      = 10001 // Token无效
	ErrCodeTokenExpired      = 10002 // Token已过期
	ErrCodeTokenTypeMismatch = 10003 // Token类型不匹配
	ErrCodeIPMismatch        = 10004 // IP不合法
	ErrCodeTokenFormatErr    = 10005 // Token内容格式错误
	ErrCodeSignMethodErr     = 10006 // 签名算法不支持
)

// 错误信息映射
var errMsgMap = map[int]string{
	ErrCodeTokenInvalid:      "token无效",
	ErrCodeTokenExpired:      "token已过期",
	ErrCodeTokenTypeMismatch: "token类型不匹配",
	ErrCodeIPMismatch:        "IP不合法",
	ErrCodeTokenFormatErr:    "token内容格式错误",
	ErrCodeSignMethodErr:     "不支持的签名算法",
}

type JwtToken struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	AccessExp    int64  `json:"access_exp"`
	RefreshExp   int64  `json:"refresh_exp"`
}

func CreateToken(token string, accessExp time.Duration, accessSecret string, refreshExp time.Duration, refreshSecret string, ip string) *JwtToken {
	if token == "" || accessSecret == "" || refreshSecret == "" {
		log.Printf("生成Token失败：token/secret不能为空")
		return nil
	}
	if accessExp <= 0 || refreshExp <= 0 {
		log.Printf("生成Token失败：过期时间不能小于等于0")
		return nil
	}

	aExp := time.Now().Add(accessExp).Unix()
	accessClaims := jwt.MapClaims{
		"token": token,
		"exp":   aExp,
		"ip":    ip,
		"type":  "access",
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	aToken, err := accessToken.SignedString([]byte(accessSecret))
	if err != nil {
		log.Printf("生成access token失败: %v", err)
		return nil
	}

	rExp := time.Now().Add(refreshExp).Unix()
	refreshClaims := jwt.MapClaims{
		"token": token,
		"exp":   rExp,
		"ip":    ip,
		"type":  "refresh",
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	rToken, err := refreshToken.SignedString([]byte(refreshSecret))
	if err != nil {
		log.Printf("生成refresh token失败: %v", err)
		return nil
	}

	return &JwtToken{
		AccessExp:    aExp,
		AccessToken:  aToken,
		RefreshExp:   rExp,
		RefreshToken: rToken,
	}
}

func ParseAccessToken(tokenString string, secret string, ip string) (string, int, error) {
	return parseTokenWithType(tokenString, secret, ip, "access")
}

func ParseRefreshToken(tokenString string, refreshSecret string, ip string) (string, int, error) {
	return parseTokenWithType(tokenString, refreshSecret, ip, "refresh")
}

func parseTokenWithType(tokenString string, secret string, ip string, tokenType string) (string, int, error) {
	if tokenString == "" || secret == "" {
		return "", ErrCodeTokenInvalid, errors.New(errMsgMap[ErrCodeTokenInvalid])
	}

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("%v: %v", errors.New(errMsgMap[ErrCodeSignMethodErr]), token.Header["alg"])
		}
		return []byte(secret), nil
	})
	if err != nil {
		return "", ErrCodeTokenInvalid, fmt.Errorf("解析token失败: %v", err)
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		if claims["type"] != tokenType {
			return "", ErrCodeTokenTypeMismatch, errors.New(errMsgMap[ErrCodeTokenTypeMismatch])
		}

		exp := int64(claims["exp"].(float64))
		if exp <= time.Now().Unix() {
			return "", ErrCodeTokenExpired, errors.New(errMsgMap[ErrCodeTokenExpired])
		}

		if tokenType == "access" && claims["ip"] != ip {
			return "", ErrCodeIPMismatch, errors.New(errMsgMap[ErrCodeIPMismatch])
		}

		val, ok := claims["token"].(string)
		if !ok {
			return "", ErrCodeTokenFormatErr, errors.New(errMsgMap[ErrCodeTokenFormatErr])
		}
		return val, 0, nil
	} else {
		return "", ErrCodeTokenInvalid, errors.New(errMsgMap[ErrCodeTokenInvalid])
	}
}

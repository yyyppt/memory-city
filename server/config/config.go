package config

import (
	"github.com/spf13/viper"
	"os"
	"time"
)

// JWT配置
var (
	AccessSecret  = "shiguangji_access_2026"
	RefreshSecret = "shiguangji_refresh_2026"
	AccessExp     = 1 * time.Hour      // Access Token过期时间
	RefreshExp    = 7 * 24 * time.Hour // Refresh Token过期时间
)

// 数据库配置
var (
	MySQLDSN = "root:shiguangji12345.@tcp(127.0.0.1:3306)/shiguangji?charset=utf8mb4&parseTime=True&loc=Local"
)

var (
	// OSS配置
	OSSEndpoint        string
	OSSAccessKeyID     string
	OSSAccessKeySecret string
	OSSBucketName      string
	OSSEndpoint_IOS    string
	// 通义千问配置
	AIAPIKey string
)

func GetSettings() {
	viper := viper.New()

	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")

	viper.ReadInConfig()

	OSSBucketName = viper.GetString("set.OSSBucketName")
	OSSEndpoint = viper.GetString("set.OSSEndpoint")
	OSSEndpoint_IOS = viper.GetString("set.OSSEndpoint_IOS")

	OSSAccessKeyID = os.Getenv("OSS_Access_Key_ID")
	OSSAccessKeySecret = os.Getenv("OSS_Access_Key_Secret")
	AIAPIKey = os.Getenv("AI_API_Key")
}

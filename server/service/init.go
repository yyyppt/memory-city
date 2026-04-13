package service

import (
	"fmt"
	"github.com/aliyun/aliyun-oss-go-sdk/oss"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"log"
	"shiguangji/config"
	"shiguangji/model"
	"shiguangji/utils"
)

var (
	Db        *gorm.DB
	OssClient *oss.Client
)

func GenerateOSSClient() error {
	var err error
	OssClient, err = utils.OSSClient()
	if err != nil {
		return err
	}
	return nil
}

func InitServices() error {
	log.Println("开始初始化服务...")

	err := GenerateOSSClient()
	if err != nil {
		return fmt.Errorf("OSS客户端创建失败: %w", err)
	}
	log.Printf("OSS客户端初始化成功，Endpoint: %s", config.OSSEndpoint)

	Db, err = gorm.Open(mysql.Open(config.MySQLDSN), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("数据库连接失败: %w", err)
	}
	log.Println("数据库连接成功")

	err = Db.AutoMigrate(
		&model.User{},
		&model.Content{},
		&model.Like{},
		&model.Comment{},
		&model.Collect{},
		&model.UserCode{},
	)
	if err != nil {
		return fmt.Errorf("数据库迁移失败: %w", err)
	}
	log.Println("数据库迁移完成")

	return nil
}

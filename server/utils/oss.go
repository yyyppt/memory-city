package utils

import (
	"fmt"
	"shiguangji/config"
	"time"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
	"github.com/satori/go.uuid"
)

// OSSClient 获取OSS客户端实例
func OSSClient() (*oss.Client, error) {
	client, err := oss.New(config.OSSEndpoint, config.OSSAccessKeyID, config.OSSAccessKeySecret)
	if err != nil {
		return nil, fmt.Errorf("OSS客户端创建失败：%v", err)
	}
	return client, nil
}

// OSSBucket 获取OSS Bucket实例
func OSSBucket(client *oss.Client) (*oss.Bucket, error) {
	bucket, err := client.Bucket(config.OSSBucketName)
	if err != nil {
		return nil, fmt.Errorf("OSS Bucket获取失败：%v", err)
	}
	return bucket, nil
}

// GenerateOSSObjectKey 生成OSS唯一文件路径
// 参数：userID-用户ID，fileExt-文件后缀（如jpg/png）
// 返回：完整的OSS文件路径（如user/1/20240312/xxx.jpg）
func GenerateOSSObjectKey(userID int64, fileExt string) string {
	uploadPath := fmt.Sprintf("user/%d/%s/", userID, time.Now().Format("20060102"))
	fileUUID := uuid.NewV4().String()

	return uploadPath + fileUUID + "." + fileExt
}

// GenerateOSSPresignedURL 生成OSS预签名上传URL
// 参数：bucket-Bucket实例，objectKey-文件路径，expireSeconds-有效期（秒）
// 返回：带鉴权的可上传URL
func GenerateOSSPresignedURL(bucket *oss.Bucket, objectKey string, expireSeconds int64) (string, error) {
	expireTime := time.Now().Add(time.Duration(expireSeconds) * time.Second)

	signedURL, err := bucket.SignURL(objectKey, oss.HTTPPut, expireSeconds,
		oss.ContentType("image/jpeg"),
		oss.ContentLength(10*1024*1024), // 10MB上限
		oss.Expires(expireTime),
	)
	if err != nil {
		return "", fmt.Errorf("预签名URL生成失败：%v", err)
	}
	return signedURL, nil
}

// GetOSSExpireSeconds 计算OSS URL有效期（秒）   默认1小时
func GetOSSExpireSeconds() int64 {
	return int64(1 * time.Hour.Seconds())
}

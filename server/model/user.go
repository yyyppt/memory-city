package model

import "time"

type User struct {
	ID         int64     `gorm:"primaryKey;autoIncrement" json:"user_id"`
	Username   string    `gorm:"unique;size:50;not null" json:"username"`
	Password   string    `gorm:"size:100;not null" json:"password"`
	Bio        string    `gorm:"size:200" json:"bio"`
	Nickname   string    `gorm:"size:50" json:"nickname"`
	Avatar     string    `gorm:"size:255" json:"avatar"`
	CreateTime time.Time `gorm:"autoCreateTime" json:"create_time"`
	UpdateTime time.Time `gorm:"autoUpdateTime" json:"update_time"`
	Phone 	   string    `gorm:"size:11" json:"phone"`
}

type UserCode struct {
	ID       int64     `gorm:"primaryKey;autoIncrement" json:"code_id"`
	Username string    `gorm:"size:50;not null;index" json:"username"`  // 移除unique约束
	Phone    string    `gorm:"size:11;not null" json:"phone"`
	Code     string    `gorm:"size:6;not null" json:"code"`
	ExpiresAt time.Time `gorm:"not null" json:"expires_at"`  // 添加过期时间字段
	CreatedAt time.Time `json:"created_at"`
	Used      bool      `gorm:"default:false" json:"used"`    // 添加是否已使用标记
}
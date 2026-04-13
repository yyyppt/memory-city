package model

import (
	"time"
)

type Like struct {
	ID        int64     `gorm:"primarykey;autoIncrement"`
	UserID    int64     `gorm:"index:idx_user_content"`
	ContentID int64     `gorm:"index:idx_user_content"`
	IsCancel  int       `gorm:"default:0"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
	UpdatedAt time.Time `gorm:"autoUpdateTime"`
}

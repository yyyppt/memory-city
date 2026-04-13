package model

import (
	"github.com/shopspring/decimal"
	"gorm.io/datatypes"
	"time"
)

type Content struct {
	ID           int64                       `gorm:"primaryKey;autoIncrement" json:"content_id"`
	UserID       int64                       `gorm:"not null;index" json:"user_id"`
	Title        string                      `gorm:"size:100;not null" json:"title"`
	Content      string                      `gorm:"type:text;not null" json:"content"`
	City         string                      `gorm:"size:50;index" json:"city"`
	Year         string                      `gorm:"size:10;index" json:"year"`
	Mood         string                      `gorm:"size:20;index" json:"mood"`
	Images       datatypes.JSONSlice[string] `gorm:"column:images;type:json" json:"images"`
	LocationName string                      `gorm:"size:50" json:"location_name"`
	Latitude     decimal.Decimal             `gorm:"type:decimal(9,6);index" json:"latitude"`
	Longitude    decimal.Decimal             `gorm:"type:decimal(9,6);index" json:"longitude"`
	IsPublic     bool                        `gorm:"default:true;index" json:"is_public"`
	LikeCount    int64                       `gorm:"default:0" json:"like_count"`
	CommentCount int64                       `gorm:"default:0" json:"comment_count"`
	CreatedAt    time.Time                   `gorm:"autoCreateTime;index" json:"created_at"`
	UpdatedAt    time.Time                   `gorm:"autoUpdateTime" json:"updated_at"`
	Visible      bool                        `gorm:"default:true;index" json:"visible"`
	IsDelete     int                         `gorm:"default:0;index" json:"is_delete"`
	// User User `gorm:"foreignKey:UserID;references:ID" json:"user"`
}
type ContentListResp struct {
	List  []Content `json:"list"`
	Total int64     `json:"total"`
}

type MapListReq struct {
	City   string          `json:"city" binding:"required"`
	LatMin decimal.Decimal `json:"lat_min" binding:"required"`
	LatMax decimal.Decimal `json:"lat_max" binding:"required"`
	LngMin decimal.Decimal `json:"lng_min" binding:"required"`
	LngMax decimal.Decimal `json:"lng_max" binding:"required"`
	Page   int             `json:"page" binding:"omitempty,min=1"`
	Size   int             `json:"size" binding:"omitempty,min=1,max=50"`
}

type MapListResp struct {
	List  []Content `json:"list"`
	Total int64     `json:"total"`
}

type C_List struct {
	Content []Content `json:"content"`
	Total int64 `json:"content_total"`
}

type U_List struct {
	User []User `json:"user"`
	Total int64 `json:"user_total"`
}

type ContentSearchResp struct {
	CList  []C_List `json:"content_list"`
	UList []U_List `json:"user_list"`
}

type ContentDetailResp struct {
	UserId 		 int64	  `json:"user_id"`
	ContentID    int64    `json:"content_id"`
	Title        string   `json:"title"`
	Content      string   `json:"content"`
	City         string   `json:"city"`
	Year         string   `json:"year"`
	Mood         string   `json:"mood"`
	Images       []string `json:"images"`
	LikeCount    int64    `json:"like_count"`
	CommentCount int64    `json:"comment_count"`
	Summary      string   `json:"summary"`
	Tags         []string `json:"tags"`
	CollectCount int64	  `json:"collect_count"`
}

type ContentMyResp struct {
	CL           *ContentListResp `json:"content_list"`
	CollectCount int64            `json:"collect_count"`
}

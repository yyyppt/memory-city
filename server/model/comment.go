package model

import "time"

type Comment struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"comment_id"`
	ContentID int64     `gorm:"not null;index:idx_content_parent" json:"content_id"`
	UserID    int64     `gorm:"not null;index" json:"user_id"`
	Content   string    `gorm:"type:text;not null" json:"content"`
	ParentID  *int64    `gorm:"default:null"`
	LikeCount int64     `gorm:"default:0" json:"like_count"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
	IsDelete  int8      `gorm:"default:0;index" json:"is_delete"`

	User    *User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Replies []*Comment `gorm:"foreignKey:ParentID" json:"replies,omitempty"`
}

type CommentListResp struct {
	List  []Comment `json:"list"`
	Total int64     `json:"total"`
}

type CommentWithReplies struct {
	Comment
	ReplyCount int64                 `json:"reply_count"`
	Replies    []*CommentWithReplies `json:"replies,omitempty"`
}

type CommentLike struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	CommentID int64     `gorm:"not null;index:idx_comment_user" json:"comment_id"`
	UserID    int64     `gorm:"not null;index:idx_comment_user" json:"user_id"`
	IsCancel  int8      `gorm:"default:0" json:"is_cancel"` // 0=点赞，1=取消
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

type CommentDeleteResp struct {
	DeletedCommentId []int64 `json:"deleted_comment_id"`
	DeletedCount     int64   `json:"deleted_count"`
}

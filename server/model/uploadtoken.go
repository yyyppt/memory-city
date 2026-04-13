package model

type UploadTokenResp struct {
	UploadURL  string `json:"upload_url"`
	Policy     string `json:"policy"`
	Token      string `json:"token"`
	ObjectKey  string `json:"object_key"`
	ExpireTime int64  `json:"expire_time"`
	UploadPath string `json:"upload_path"`
}

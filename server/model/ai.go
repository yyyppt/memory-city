package model

type AISearchAnalysis struct {
	Summary     string   `json:"summary"`     // 搜索结果总结
	Suggestions []string `json:"suggestions"` // 推荐关键词列表
	Highlights  []string `json:"highlights"`  // 内容亮点
	Guide       string   `json:"guide"`       // 探索引导
}
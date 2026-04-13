package service

import (
	"encoding/json"
	"net/http"
	"io"
	"shiguangji/config"
	"errors"
	"bytes"
	"fmt"
	"shiguangji/model"
	"strings"
	"time"
)

// 完整的AnalyzeSearchResults函数
func AIAnalyzeText(resultText string) (*model.AISearchAnalysis, error) {
	if resultText == "" {
		return nil, errors.New("内容不能为空")
	}
	
	prompt := `你是一个"城市记忆搜索助手"，需要帮助用户更好地探索内容。

请根据【搜索结果】，生成搜索辅助信息。

要求：
1. summary：用不超过80字总结当前搜索结果在讲什么；
2. suggestions：给出3个推荐继续搜索的关键词（中文，英文逗号分隔）；
3. highlights：提取2-3个有代表性的内容点（短句，每条不超过20字）；
4. guide：用一句话引导用户继续探索，不超过40字；
5. 如果搜索结果较少或内容不集中，请优先生成"扩展搜索建议"；
6. 严禁编造不存在的信息；
7. 输出必须是JSON，不能有任何额外文字或说明。

请严格按照以下格式返回：

{
  "summary": "搜索结果总结",
  "suggestions": "关键词1,关键词2,关键词3",
  "highlights": ["亮点1","亮点2"],
  "guide": "一句探索引导"
}

搜索结果内容：
%s`
	
	prompt = fmt.Sprintf(prompt, resultText)
	
	content, err := callAI(prompt)
	if err != nil {
		return nil, err
	}
	
	var aiResult struct {
		Summary     string   `json:"summary"`
		Suggestions string   `json:"suggestions"`
		Highlights  []string `json:"highlights"`
		Guide       string   `json:"guide"`
	}
	
	if err := json.Unmarshal([]byte(content), &aiResult); err != nil {
		return nil, err
	}
	
	suggestions := []string{}
	if aiResult.Suggestions != "" {
		for _, s := range strings.Split(aiResult.Suggestions, ",") {
			s = strings.TrimSpace(s)
			if s != "" {
				suggestions = append(suggestions, s)
			}
		}
	}
	
	return &model.AISearchAnalysis{
		Summary:     aiResult.Summary,
		Suggestions: suggestions,
		Highlights:  aiResult.Highlights,
		Guide:       aiResult.Guide,
	}, nil
}
func callAI(prompt string) (string, error) {
	reqBody := map[string]interface{}{
		"model": "qwen-turbo",
		"input": map[string]interface{}{
			"messages": []map[string]interface{}{
				{
					"role":    "user",
					"content": prompt,
				},
			},
		},
		"parameters": map[string]interface{}{
			"result_format": "json",
		},
	}
	
	jsonBody, _ := json.Marshal(reqBody)
	
	req, _ := http.NewRequest("POST", "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation", 
		bytes.NewBuffer(jsonBody))
	
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+config.AIAPIKey)
	
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	
	var result struct {
		Output struct {
			Choices []struct {
				Message struct {
					Content string `json:"content"`
				} `json:"message"`
			} `json:"choices"`
		} `json:"output"`
		Error struct {
			Message string `json:"message"`
		} `json:"error"`
	}
	
	body, _ := io.ReadAll(resp.Body)
	json.Unmarshal(body, &result)
	
	if result.Error.Message != "" {
		return "", errors.New(result.Error.Message)
	}
	
	if len(result.Output.Choices) == 0 {
		return "", errors.New("AI返回空结果")
	}
	
	return result.Output.Choices[0].Message.Content, nil
}
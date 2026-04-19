---
name: bilingual-sxs
description: 此技能負責將長篇文字檔分區塊翻譯，輸出中英對照之易讀 HTML 文件
---

# Transcript Translator

此技能為非英語母語者將長篇文章翻譯為 zh-tw，輸出包含中英對照翻譯與語言學習提示之易讀網頁

## 工作流程

### 步驟一：分塊 Chunking

- 使用者提供長篇英文之文字檔路徑
- 執行 `.github\skills\bilingual-sxs\scripts\chunk.ps1` 將內容依段落切割為不超過 4K 字元的區塊：
```powershell
.github\skills\bilingual-sxs\scripts\chunk.ps1 -InputFile "路徑/檔名.txt"
```

執行後會建立專案目錄 `.\script\work\檔名`，包含 `chunk_001.txt`、`chunk_002.txt` … 等區塊檔案。chunk.ps1 輸出結果會包含區塊檔案清單，方便後續作為參數傳送給 Subagent。


### 步驟二：逐 Chunk 翻譯

對專案目錄**每個** `chunk_NNN.txt`，依序以 **Subagent** 處理：

1. 讀取 `translate-chunk/SKILL.md` 作為 Subagent 的 Skill 指令
2. 傳入參數：`chunk_file = 專案目錄/chunk_NNN.txt`
3. Subagent 完成後會在專案目錄產生 `chunk_NNN.json`
4. 確認結果檔存在後，繼續處理下一個 chunk

> 每個子 Agent 調用的 context 完全隔離，主 Agent 只需追蹤「下一個待處理 chunk 編號」。

### 步驟三：合併輸出 HTML

執行 `.github\skills\bilingual-sxs\scripts\merge.ps1` 將所有 JSON 結果合併為單一 HTML 檔案：

```powershell
.github\skills\bilingual-sxs\scripts\merge.ps1 -Project 專案目錄 
```

結果儲存於 專案目錄\output.html

### 步驟四：呈現結果

告知使用者已產生 `output.html`，並摘要顯示部分翻譯內容。


## 檔案結構

```
.github/skills/bilingual-sxs/
├── SKILL.md                            ← 本檔案（主 Orchestrator）
├── translate-chunk/
│   └── SKILL.md                        ← 子 Agent Skill（單一 chunk 翻譯）
├── prompts/
│   └── translate-instruction.md       ← LLM System Prompt（子 Agent 使用）
└── scripts/
    ├── chunk.ps1                       ← 文章切割腳本
    ├── merge.ps1                       ← HTML 合併腳本
    └── reader.html                     ← HTML 範本
```
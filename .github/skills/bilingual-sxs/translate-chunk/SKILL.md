---
name: translate-chunk
description: 子 Agent Skill，負責將單一 chunk 檔案翻譯並輸出 JSON 結果檔
---

# Translate Chunk（子 Agent）

此 Skill 由主 Agent（transcript-translator）調用，每次僅處理**一個** chunk 檔案，完成後即結束，不保留任何跨 chunk 的狀態。

## 輸入

| 參數 | 說明 |
|------|------|
| `chunk_file` | 待翻譯的區塊檔案路徑，例如 `work/proj-folder/chunk_003.txt` |

## 執行步驟

### 步驟 1：讀取翻譯指令

讀取 `prompts/translate-instruction.md`，作為本次翻譯的 System Prompt。

### 步驟 2：讀取 chunk 內容

讀取 `chunk_file` 的完整文字內容，作為 User Input。

### 步驟 3：執行翻譯

依 translate-instruction.md 的指令對 chunk 內容執行翻譯，輸出格式與規則以該檔案為唯一依據。

### 步驟 4：儲存結果

將 JSON 儲存至對應結果檔。

- 命名規則：將 `chunk_NNN.txt` 對應為 `chunk_NNN.json`
- 存放位置：與 chunk 檔案相同的 `work/` 目錄

## 輸出

`chunk_NNN.json`：符合上述格式的有效 JSON 檔案。

## 注意事項

- 輸出**僅含 JSON**，不加任何說明文字或 markdown 程式碼區塊
- 每個英文段落對應一個 `paragraphs` 元素，不合併、不拆分
- 翻譯完成後，此子 Agent 的工作即告完成，無需等待其他 chunk

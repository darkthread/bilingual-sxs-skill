# Bilingual Side-by-Side — Copilot Custom Skill

一個 GitHub Copilot 自訂技能（Custom Skill），將長篇英文文章翻譯為**中英對照**的互動式 HTML 網頁，附帶語言學習提示，專為非英語母語的學習者設計。([註]本文件由 AI 生成)

## 特色

- **中英逐句對照** — 每句英文緊跟繁體中文翻譯，可逐句 hover 高亮對應
- **語言學習提示** — 自動標註文法結構、專業術語、慣用語、口語用法
- **互動式閱讀器** — 自由切換原文／翻譯／提示的顯示，支援「對照」與「穿插」兩種雙語模式
- **大型文章支援** — 自動分塊處理，透過 Subagent 架構平行翻譯，不受 context window 限制

## 輸出範例

產出的 HTML 為自包含的單一檔案，右上角工具列可切換閱讀模式：

| 按鈕 | 功能 |
|------|------|
| **原文** | 顯示／隱藏英文原文 |
| **翻譯** | 顯示／隱藏中文翻譯 |
| **提示** | 顯示／隱藏語言學習提示 |
| **對照** | 原文與翻譯分段上下排列，hover 高亮對應句子 |
| **穿插** | 翻譯穿插於每句英文之後，適合精讀 |

## 設計原理

### Orchestrator + Subagent 架構

長篇文章的翻譯容易遇到 LLM context window 限制與品質下降的問題。本技能採用**主從式架構**解決：

```
主 Agent (Orchestrator)
  ├─ 步驟一：chunk.ps1 將文章切割為 ≤4K 字元的區塊
  ├─ 步驟二：逐一呼叫 Subagent 翻譯每個 chunk（彼此完全隔離）
  ├─ 步驟三：merge.ps1 合併所有 JSON 為 HTML
  └─ 步驟四：回報結果
```

- **分塊（Chunking）**：以段落為邊界切割，保證段落完整性
- **隔離翻譯**：每個 Subagent 只處理一個 chunk，context 不交叉污染，翻譯品質一致
- **結構化中介格式**：翻譯結果以 JSON 儲存（`orig` / `trans` / `hints`），方便驗證與後處理

### Skill 檔案結構

```
.github/skills/bilingual-sxs/
├── SKILL.md                        ← 主 Orchestrator 指令
├── translate-chunk/
│   └── SKILL.md                    ← Subagent 指令（單一 chunk 翻譯）
├── prompts/
│   └── translate-instruction.md    ← LLM System Prompt（翻譯規則與 JSON 格式）
└── scripts/
    ├── chunk.ps1                   ← 段落分塊腳本
    ├── merge.ps1                   ← JSON → HTML 合併腳本
    └── reader.html                 ← Vue 3 互動式閱讀器範本
```

### 資料流

```
sample.txt
  │  chunk.ps1
  ▼
work/sample/chunk_001.txt … chunk_NNN.txt
  │  Subagent × N（translate-instruction.md）
  ▼
work/sample/chunk_001.json … chunk_NNN.json
  │  merge.ps1 + reader.html
  ▼
translated/sample.html
```

## 使用方式

### 前置需求

- [VS Code](https://code.visualstudio.com/) + [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) 擴充套件
- PowerShell 7+（腳本執行環境）

### 安裝

將本專案 clone 至本地，或作為 Git submodule 加入你的專案：

```bash
git clone https://github.com/<your-username>/bilingual-sxs-skills.git
```

### 執行翻譯

1. 將要翻譯的英文文字檔放進專案根目錄（例如 `sample.txt`）
2. 在 VS Code 中開啟 Copilot Chat（Agent mode）
3. 輸入指令：

```
use bilingual-sxs skill to translate sample.txt
```

Copilot 會自動依照 SKILL.md 的流程：分塊 → 逐塊翻譯 → 合併 HTML。

4. 完成後開啟產出的 HTML 檔案即可閱讀

### 手動執行各步驟

如果需要單獨執行某個步驟：

```powershell
# 分塊
.github\skills\bilingual-sxs\scripts\chunk.ps1 -InputFile "sample.txt"

# 合併（翻譯 JSON 完成後）
.github\skills\bilingual-sxs\scripts\merge.ps1 -ProjectDir ".github\skills\bilingual-sxs\scripts\work\sample"
```

## 自訂與擴展

| 想改什麼 | 修改哪裡 |
|----------|----------|
| 翻譯目標語言或提示風格 | `prompts/translate-instruction.md` |
| 分塊大小 | `chunk.ps1` 的 `-ChunkSize` 參數（預設 4096） |
| HTML 外觀與互動 | `scripts/reader.html`（CSS 變數 + Vue 3） |

## License

MIT
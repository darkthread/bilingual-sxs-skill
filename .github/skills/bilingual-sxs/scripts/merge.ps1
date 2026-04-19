<#
.SYNOPSIS
    將翻譯區塊 JSON 結果檔合併為單一 HTML 檔案。

.DESCRIPTION
    讀取工作目錄下所有 chunk_###.json 結果檔，
    依序合併，產生包含原文、翻譯與語言提示之雙語對照 HTML 頁面。

.PARAMETER ProjectDir
    包含 chunk-NNN.json 結果檔的目錄

.EXAMPLE
    <script-path>\merge.ps1 -ProjectDir <project-directory-path>
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectDir
)

[string]$Title = [System.IO.Path]::GetFileName($ProjectDir.TrimEnd('\'))

# 搜尋區塊結果檔
$jsonFiles = Get-ChildItem -Path $ProjectDir -Filter "chunk_*.json" -ErrorAction SilentlyContinue |
Sort-Object Name

if (-not $jsonFiles -or $jsonFiles.Count -eq 0) {
    Write-Error "在 '$ProjectDir' 中找不到 chunk_*.json 結果檔。"
    exit 1
}

Write-Host "找到 $($jsonFiles.Count) 個結果檔，開始合併..."


$totalParas = 0
$paragraphs = @()

foreach ($jsonFile in $jsonFiles) {
    try {
        $json = Get-Content -Path $jsonFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        Write-Warning "無法解析 $($jsonFile.Name)：$_"
        continue
    }

    if (-not $json.paragraphs) {
        Write-Warning "$($jsonFile.Name) 中無 paragraphs 資料，略過。"
        continue
    }

    foreach ($para in $json.paragraphs) {
        $paragraphs += [PSCustomObject]@{
            O = [string[]]$para.orig
            T = [string[]]$para.trans
            H = [array]@($para.hints | ForEach-Object {
                    [PSCustomObject]@{
                        W = $_.words
                        E = $_.exact
                        D = $_.desc
                    }
                })
        }
    }
    $totalParas++
}

$template = Get-Content -Path (Join-Path $PSScriptRoot "reader.html") -Raw -Encoding UTF8
$template = $template -replace '\$TITLE\$', (ConvertTo-Json $Title)
$template = $template -replace '\$PARAGRAPHS\$', (ConvertTo-Json $paragraphs -Depth 10)

$OutputFile = Join-Path $ProjectDir "output.html"
$template | Set-Content -Path $OutputFile -Encoding UTF8
$HtmlPath = Join-Path $PSScriptRoot "translated" ([System.IO.Path]::GetFileName($ProjectDir.TrimEnd('\')) + ".html") 
Copy-Item $OutputFile -Destination $HtmlPath -Force

Write-Host "完成。已產生 '$HtmlPath'，共 $totalParas 個段落。"

<#
.SYNOPSIS
    將英文文字檔依段落切割為不超過指定字元數的區塊。

.DESCRIPTION
    讀取英文文字內容，以空行為段落界線進行切割，
    確保每個區塊不超過指定字元上限（預設 4096 字元），
    避免段落被截斷。區塊檔案依序輸出至指定目錄。

.PARAMETER InputFile
    輸入文字檔路徑。

.PARAMETER ChunkSize
    每個區塊的最大字元數，預設為 4096。

.EXAMPLE
    <script-path>\chunk.ps1 -InputFile <input-file-path>
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    [int]$ChunkSize = 4096
)

# 確認輸入檔案存在
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "找不到輸入檔案：$InputFile"
    exit 1
}

$pureFileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
$projectDir = [System.IO.Path]::Combine($PSScriptRoot, "work", $pureFileName)
# 確保輸出目錄存在
if (-not (Test-Path -Path $projectDir)) {
    New-Item -ItemType Directory -Path $projectDir | Out-Null
}
# 讀取完整內容
$content = Get-Content -Path $InputFile -Raw -Encoding UTF8

# 以連續空行（一行以上）分割成段落，並過濾空項目
$paragraphs = $content -split '(?:\r?\n){2,}' |
    Where-Object { $_.Trim() -ne '' } |
    ForEach-Object { $_.Trim() }

if ($paragraphs.Count -eq 0) {
    Write-Error "輸入檔案為空或無有效段落。"
    exit 1
}

$chunkIndex = 1
$currentParagraphs = [System.Collections.Generic.List[string]]::new()
$currentSize = 0
$fileList = @()

foreach ($para in $paragraphs) {
    # +2 代表段落間分隔空行的字元數
    $paraSize = $para.Length + 2

    # 若加入此段落會超過上限，且已有內容，先儲存現有區塊
    if ($currentParagraphs.Count -gt 0 -and ($currentSize + $paraSize) -gt $ChunkSize) {
        $chunkFile = Join-Path $projectDir ("chunk_{0:D3}.txt" -f $chunkIndex)
        ($currentParagraphs -join "`n`n") | Set-Content -Path $chunkFile -Encoding UTF8
        # Write-Host "已建立：$chunkFile（$currentSize 字元，$($currentParagraphs.Count) 段落）"
        $fileList += $chunkFile
        $chunkIndex++
        $currentParagraphs = [System.Collections.Generic.List[string]]::new()
        $currentSize = 0
    }

    $currentParagraphs.Add($para)
    $currentSize += $paraSize
}

# 儲存最後一個區塊
if ($currentParagraphs.Count -gt 0) {
    $chunkFile = Join-Path $projectDir ("chunk_{0:D3}.txt" -f $chunkIndex)
    ($currentParagraphs -join "`n`n") | Set-Content -Path $chunkFile -Encoding UTF8
    # Write-Host "已建立：$chunkFile（$currentSize 字元，$($currentParagraphs.Count) 段落）"
    $fileList += $chunkFile
}

# Write-Host "完成。共產生 $chunkIndex 個區塊檔案於 '$projectDir'。"
Write-Output "區塊檔案清單："
$fileList | ForEach-Object { Write-Host $_ }

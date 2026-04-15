# AI組織 セットアップスクリプト
# Windows PowerShell 5.1+ 対応
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================
# 1. 必要なソフトのインストール確認
# ============================================

Write-Host ""
Write-Host "--- 必要なソフトの確認 ---" -ForegroundColor Cyan
Write-Host ""

# --- winget の確認 ---
$hasWinget = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
if (-not $hasWinget) {
    Write-Host "[!] winget が見つかりません。" -ForegroundColor Yellow
    Write-Host "    Microsoft Store から 'アプリ インストーラー' を更新してください。"
    Read-Host "Enterキーで終了"
    exit 1
}

# --- Node.js ---
$hasNode = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
if ($hasNode) {
    $nodeVer = node --version 2>$null
    Write-Host "[OK] Node.js $nodeVer" -ForegroundColor Green
} else {
    Write-Host "[  ] Node.js をインストール中..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[NG] Node.js のインストールに失敗。https://nodejs.org/ から手動で。" -ForegroundColor Red
        Read-Host "Enterキーで終了"
        exit 1
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "[OK] Node.js インストール完了" -ForegroundColor Green
}

# --- Claude Code ---
$hasClaude = $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
if ($hasClaude) {
    Write-Host "[OK] Claude Code" -ForegroundColor Green
} else {
    Write-Host "[  ] Claude Code をインストール中..." -ForegroundColor Yellow
    npm install -g @anthropic-ai/claude-code
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[NG] Claude Code のインストールに失敗。" -ForegroundColor Red
        Read-Host "Enterキーで終了"
        exit 1
    }
    Write-Host "[OK] Claude Code インストール完了" -ForegroundColor Green
}

Write-Host ""

# ============================================
# 2. ユーザー情報の入力
# ============================================

Write-Host "============================================" -ForegroundColor Yellow
Write-Host "  あなたの情報を入力してください" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""

do { $userName = Read-Host "名前（例: 山田太郎）" } while ([string]::IsNullOrWhiteSpace($userName))
do { $userTitle = Read-Host "肩書き（例: Webマーケター）" } while ([string]::IsNullOrWhiteSpace($userTitle))

$userType = Read-Host "事業形態（例: 個人事業主）[Enter で「個人事業主」]"
if ([string]::IsNullOrWhiteSpace($userType)) { $userType = "個人事業主" }

do { $businessDesc = Read-Host "事業内容を一言で（例: 起業家向けにSNS集客を支援する）" } while ([string]::IsNullOrWhiteSpace($businessDesc))

Write-Host ""
Write-Host "作業フォルダのパス（ai-organizationの1つ上のフォルダ）" -ForegroundColor Cyan
$defaultBase = (Split-Path $scriptDir -Parent) -replace '\\','/'
Write-Host "（Enterで: $defaultBase）" -ForegroundColor Gray
$basePath = Read-Host "パス"
if ([string]::IsNullOrWhiteSpace($basePath)) { $basePath = $defaultBase }
$basePath = $basePath.TrimEnd('/').TrimEnd('\') -replace '\\','/'

Write-Host ""
Write-Host "Obsidian vault のパス（使っていなければEnterでスキップ）" -ForegroundColor Cyan
$obsidianPath = Read-Host "パス"
if ([string]::IsNullOrWhiteSpace($obsidianPath)) {
    $obsidianPath = "$basePath/obsidian"
    Write-Host "  → $obsidianPath に設定" -ForegroundColor Gray
} else {
    $obsidianPath = $obsidianPath.TrimEnd('/').TrimEnd('\') -replace '\\','/'
}

# ============================================
# 3. 確認
# ============================================

Write-Host ""
Write-Host "  名前:       $userName"
Write-Host "  肩書:       $userTitle"
Write-Host "  事業形態:   $userType"
Write-Host "  事業内容:   $businessDesc"
Write-Host "  作業フォルダ: $basePath"
Write-Host "  Obsidian:   $obsidianPath"
Write-Host ""

$confirm = Read-Host "これでよければ Enter、やり直すなら n"
if ($confirm -eq 'n') {
    Write-Host "中止しました。"
    exit 0
}

# ============================================
# 4. ファイルの書き換え
# ============================================

Write-Host ""
Write-Host "--- ファイルを書き換え中 ---" -ForegroundColor Cyan

$targetFiles = @(
    "$scriptDir\CLAUDE.md",
    "$scriptDir\プロジェクト\業務概要.md",
    "$scriptDir\プロジェクト\接続情報.md",
    "$scriptDir\組織\スキル\秘書.md"
)

$replacements = @{
    '{{USER_NAME}}'     = $userName
    '{{USER_TITLE}}'    = $userTitle
    '{{USER_TYPE}}'     = $userType
    '{{BUSINESS_DESC}}' = $businessDesc
    '{{BASE_PATH}}'     = $basePath
    '{{OBSIDIAN_PATH}}' = $obsidianPath
}

foreach ($file in $targetFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -Encoding UTF8
        $changed = $false
        foreach ($key in $replacements.Keys) {
            if ($content.Contains($key)) {
                $content = $content.Replace($key, $replacements[$key])
                $changed = $true
            }
        }
        if ($changed) {
            [System.IO.File]::WriteAllText($file, $content, [System.Text.UTF8Encoding]::new($false))
            $shortName = $file.Replace($scriptDir, '').TrimStart('\')
            Write-Host "  [OK] $shortName" -ForegroundColor Green
        }
    }
}

# ============================================
# 5. 完了
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  セットアップ完了!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "次にやること:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Claude Code を起動"
Write-Host "     cd `"$scriptDir`" && claude"
Write-Host ""
Write-Host "  2. Gmail/Calendar/YouTube/Canva を使うなら各サービスを認証"
Write-Host ""
Write-Host "  3. Chatwork を使うなら環境変数 CHATWORK_API_TOKEN を設定"
Write-Host ""
Write-Host "  4. プロジェクト/業務概要.md を自分用に書き換える"
Write-Host ""
Write-Host "準備ができたら、Claude Code に話しかけるだけで使えます。"
Write-Host ""

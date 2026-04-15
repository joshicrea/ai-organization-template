# AI Organization セットアップスクリプト
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
    Write-Host "    更新後、このスクリプトを再実行してください。"
    Write-Host ""
    Read-Host "Enterキーで終了"
    exit 1
}

# --- Node.js ---
$hasNode = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
if ($hasNode) {
    $nodeVer = node --version 2>$null
    Write-Host "[OK] Node.js $nodeVer インストール済み" -ForegroundColor Green
} else {
    Write-Host "[  ] Node.js が見つかりません。インストールします..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[NG] Node.js のインストールに失敗しました。手動でインストールしてください。" -ForegroundColor Red
        Write-Host "    https://nodejs.org/"
        Read-Host "Enterキーで終了"
        exit 1
    }
    # PATHを更新
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "[OK] Node.js インストール完了" -ForegroundColor Green
}

# --- Claude Code ---
$hasClaude = $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
if ($hasClaude) {
    Write-Host "[OK] Claude Code インストール済み" -ForegroundColor Green
} else {
    Write-Host "[  ] Claude Code が見つかりません。インストールします..." -ForegroundColor Yellow
    npm install -g @anthropic-ai/claude-code
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[NG] Claude Code のインストールに失敗しました。" -ForegroundColor Red
        Read-Host "Enterキーで終了"
        exit 1
    }
    Write-Host "[OK] Claude Code インストール完了" -ForegroundColor Green
}

Write-Host ""
Write-Host "--- ソフトの確認完了 ---" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 2. ユーザー情報の入力
# ============================================

Write-Host "============================================" -ForegroundColor Yellow
Write-Host "  あなたの情報を入力してください" -ForegroundColor Yellow
Write-Host "  （後からファイルを直接編集して変更もできます）" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""

# --- 名前 ---
do {
    $userName = Read-Host "あなたの名前（例: 山田太郎）"
} while ([string]::IsNullOrWhiteSpace($userName))

# --- 肩書 ---
do {
    $userTitle = Read-Host "肩書き（例: Webマーケター、コンサルタント等）"
} while ([string]::IsNullOrWhiteSpace($userTitle))

# --- 事業形態 ---
$userType = Read-Host "事業形態（例: 個人事業主、法人等）[Enter で「個人事業主」]"
if ([string]::IsNullOrWhiteSpace($userType)) { $userType = "個人事業主" }

# --- 事業内容 ---
do {
    $businessDesc = Read-Host "事業内容を一言で（例: 起業家向けにSNS集客を支援する）"
} while ([string]::IsNullOrWhiteSpace($businessDesc))

# --- ベースパス ---
Write-Host ""
Write-Host "作業フォルダのパスを指定してください。" -ForegroundColor Cyan
Write-Host "ai-organization フォルダの【1つ上】のフォルダです。" -ForegroundColor Cyan
Write-Host "例: c:/Users/tanaka/Documents/work" -ForegroundColor Gray
Write-Host "    この場合 ai-organization は" -ForegroundColor Gray
Write-Host "    c:/Users/tanaka/Documents/work/ai-organization/ に置く想定です" -ForegroundColor Gray
Write-Host ""

# 現在の場所から推測
$defaultBase = (Split-Path $scriptDir -Parent) -replace '\\','/'
Write-Host "（何も入力せずEnterを押すと: $defaultBase）" -ForegroundColor Gray

$basePath = Read-Host "作業フォルダのパス"
if ([string]::IsNullOrWhiteSpace($basePath)) { $basePath = $defaultBase }
$basePath = $basePath.TrimEnd('/').TrimEnd('\') -replace '\\','/'

# --- Obsidianパス ---
Write-Host ""
Write-Host "Obsidian（メモアプリ）を使っていますか？" -ForegroundColor Cyan
Write-Host "使っていなければ空のままEnterでOK（後で設定できます）" -ForegroundColor Gray
$obsidianPath = Read-Host "Obsidian vault のパス（例: c:/Users/tanaka/Documents/obsidian）"
if ([string]::IsNullOrWhiteSpace($obsidianPath)) {
    $obsidianPath = "$basePath/obsidian"
    Write-Host "  → $obsidianPath に設定しました（後で変更可能）" -ForegroundColor Gray
} else {
    $obsidianPath = $obsidianPath.TrimEnd('/').TrimEnd('\') -replace '\\','/'
}

# ============================================
# 3. 確認
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "  以下の内容で設定します" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  名前:       $userName"
Write-Host "  肩書:       $userTitle"
Write-Host "  事業形態:   $userType"
Write-Host "  事業内容:   $businessDesc"
Write-Host "  作業フォルダ: $basePath"
Write-Host "  Obsidian:   $obsidianPath"
Write-Host ""

$confirm = Read-Host "これでよければ Enter、やり直すなら n を入力"
if ($confirm -eq 'n') {
    Write-Host "中止しました。もう一度 setup.bat を実行してください。"
    exit 0
}

# ============================================
# 4. ファイルの書き換え
# ============================================

Write-Host ""
Write-Host "--- ファイルを書き換え中 ---" -ForegroundColor Cyan

# 書き換え対象ファイル一覧
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
    } else {
        Write-Host "  [--] $file が見つかりません（スキップ）" -ForegroundColor Gray
    }
}

# ============================================
# 5. ナレッジフォルダの初期化（オプション）
# ============================================

Write-Host ""
$resetKnowledge = Read-Host "ナレッジ（過去の学習メモ）を初期化しますか？ (y/n) [n]"
if ($resetKnowledge -eq 'y') {
    $knowledgeDir = "$scriptDir\ナレッジ"
    if (Test-Path $knowledgeDir) {
        Get-ChildItem $knowledgeDir -File | ForEach-Object {
            Remove-Item $_.FullName -Force
            Write-Host "  [削除] $($_.Name)" -ForegroundColor Gray
        }
    }
    Write-Host "  ナレッジを初期化しました。使っていくうちに自動で溜まります。" -ForegroundColor Green
} else {
    Write-Host "  ナレッジはそのまま残します。" -ForegroundColor Gray
}

# ============================================
# 6. 完了
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  セットアップ完了!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "次にやること:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Claude Code を起動して、このフォルダを開く"
Write-Host "     → ターミナルで: cd `"$scriptDir`" && claude"
Write-Host ""
Write-Host "  2. Gmail/Google Calendar/YouTube/Canva を使うなら"
Write-Host "     → Claude Code の設定で各サービスを認証する"
Write-Host "     （Claude Code を起動した後に案内が出ます）"
Write-Host ""
Write-Host "  3. Chatwork を使うなら"
Write-Host "     → 環境変数 CHATWORK_API_TOKEN を設定する"
Write-Host "     （管理画面 → API設定 からトークンを取得）"
Write-Host ""
Write-Host "  4. 業務概要.md を開いて、優先事項やツールを自分用に書き換える"
Write-Host "     → $scriptDir\プロジェクト\業務概要.md"
Write-Host ""
Write-Host "準備ができたら、Claude Code に話しかけるだけで使えます。"
Write-Host ""

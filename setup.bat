@echo off
chcp 65001 >nul
title AI Organization セットアップ
echo.
echo ============================================
echo   AI Organization セットアップ
echo   ダブルクリックで起動 → 質問に答えるだけ
echo ============================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

echo.
pause

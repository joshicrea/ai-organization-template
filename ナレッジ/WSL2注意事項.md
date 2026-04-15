# WSL2環境での注意事項

## NTFS問題
- /mnt/c/（NTFS）上での大量ファイル���作は遅���・不安定
- 対策: 一時ファイルはLinux FS側（/tmp, /home/）に置く。完成後にNTFSへコピー

## inotifywait
- WSL2上ではinotifywaitが不安定（ファイルシステムイベントが欠落する）
- 対策: ファイル監視にはポーリングのフォールバックを入れる

## パス
- WSL2からWindowsのパスは /mnt/c/Users/... で参照
- OneDriveフォルダは同期の影響でファイルロックが発生することがある

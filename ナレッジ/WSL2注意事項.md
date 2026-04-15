# WSL2環境での注意事項

## 将軍システム運用から学んだ教訓

### NTFS問題
- /mnt/c/（NTFS）上での大量ファイル操作は遅い・不安定
- ffmpegでNTFS上に出力するとmoov atomが不完全になることがある
- 対策: 一時ファイルはLinux FS側（/tmp, /home/）に置く。完成後にNTFSへコピー

### inotifywait
- WSL2上ではinotifywaitが不安定（ファイルシステムイベントが欠落する）
- 対策: ファイル監視にはポーリングのフォールバックを入れる。または監視に依存しない設計にする

### パス
- WSL2からWindowsのパスは /mnt/c/Users/... で参照
- OneDriveフォルダは同期の影響でファイルロックが発生することがある
- /mnt/c/Windows/, /mnt/c/Program Files/ は変更しない

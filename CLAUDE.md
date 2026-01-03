# Part2 プロジェクト固有ルール

## Xcode プロジェクト管理

### 新規ファイル作成時の注意
**重要**: 新しい`.swift`ファイルを作成した場合、Xcodeプロジェクトへの手動追加が必要です。

ファイル作成後、必ず以下を案内すること：

```
📁 Xcodeへの手動追加が必要

作成したファイル: [ファイルパス]

追加手順:
1. Xcode左のナビゲーターで該当フォルダを右クリック
2. 「Add Files to "Part2"...」を選択
3. 作成したファイルを選択して「Add」
```

## プロジェクト構成

- `Models/`: データモデル（Alarm, SavedCode, SavedRecording）
- `Views/`: SwiftUI ビュー
- `Managers/`: シングルトンマネージャー（Audio, Alarm, Notification, Volume等）

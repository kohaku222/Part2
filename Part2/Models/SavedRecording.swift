//
//  SavedRecording.swift
//  Part2
//
//  Created by Claude on 2025/12/24.
//

import Foundation

struct SavedRecording: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String           // ユーザーが付ける名前（例: "朝のモチベーション"）
    var fileName: String       // Documents内のファイル名
    var duration: TimeInterval // 録音時間（秒）
    var createdAt: Date = Date()

    // Documentsディレクトリ内のファイルURLを取得
    var fileURL: URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsPath.appendingPathComponent(fileName)
        // ファイルが存在する場合のみURLを返す
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }

    // 録音時間の表示用文字列
    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // 作成日時の表示用文字列
    var createdAtString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: createdAt)
    }
}

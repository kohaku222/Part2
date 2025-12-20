//
//  Alarm.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import Foundation

struct Alarm: Identifiable, Codable {
    var id: UUID = UUID()
    var time: Date
    var isEnabled: Bool = true
    var voiceRecordingURL: URL?
    var qrCode: String?
    var label: String?

    // 時刻を "HH:mm" 形式の文字列で取得
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    // 時と分を個別に取得
    var hour: Int {
        Calendar.current.component(.hour, from: time)
    }

    var minute: Int {
        Calendar.current.component(.minute, from: time)
    }

    // 音声録音が設定されているか
    var hasVoiceRecording: Bool {
        voiceRecordingURL != nil
    }

    // QRコードが設定されているか
    var hasQRCode: Bool {
        qrCode != nil && !qrCode!.isEmpty
    }
}

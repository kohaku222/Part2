//
//  AlarmStorage.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import Foundation

class AlarmStorage: ObservableObject {
    static let shared = AlarmStorage()

    private let key = "savedAlarm"
    private let ringingKey = "alarmIsRinging"

    @Published var alarm: Alarm? {
        didSet {
            saveAlarm()
        }
    }

    // アラームが鳴っている状態（タスクキルしても保持）
    @Published var isRinging: Bool = false {
        didSet {
            UserDefaults.standard.set(isRinging, forKey: ringingKey)
            print("アラーム鳴動状態: \(isRinging)")
        }
    }

    private init() {
        loadAlarm()
        // 鳴動状態を復元
        isRinging = UserDefaults.standard.bool(forKey: ringingKey)
        if isRinging {
            print("前回のアラームが未解除です")
        }
    }

    // MARK: - アラーム発火
    func triggerAlarm() {
        isRinging = true
    }

    // MARK: - アラーム解除（QRスキャン成功時のみ呼ぶ）
    func dismissAlarm() {
        isRinging = false
        // 通知をキャンセル
        NotificationManager.shared.cancelAllAlarms()
        NotificationManager.shared.clearBadge()
        print("アラームを正式に解除しました")
    }

    // MARK: - 保存

    private func saveAlarm() {
        if let alarm = alarm {
            do {
                let data = try JSONEncoder().encode(alarm)
                UserDefaults.standard.set(data, forKey: key)
                print("アラームを保存しました")
            } catch {
                print("アラーム保存エラー: \(error.localizedDescription)")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: key)
            print("アラームを削除しました")
        }
    }

    // MARK: - 読み込み

    private func loadAlarm() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("保存されたアラームがありません")
            return
        }

        do {
            alarm = try JSONDecoder().decode(Alarm.self, from: data)
            print("アラームを読み込みました: \(alarm?.timeString ?? "")")
        } catch {
            print("アラーム読み込みエラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 更新

    func updateAlarm(_ update: (inout Alarm) -> Void) {
        if var current = alarm {
            update(&current)
            alarm = current
        }
    }

    // MARK: - 削除

    func deleteAlarm() {
        if let currentAlarm = alarm {
            // 録音ファイルも削除
            if let url = currentAlarm.voiceRecordingURL {
                AudioManager.shared.deleteRecording(url: url)
            }
            // 通知をキャンセル
            NotificationManager.shared.cancelAlarm(id: currentAlarm.id.uuidString)
        }
        alarm = nil
    }
}

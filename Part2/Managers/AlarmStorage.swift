//
//  AlarmStorage.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import Foundation

class AlarmStorage: ObservableObject {
    static let shared = AlarmStorage()

    private let key = "savedAlarms"
    private let ringingKey = "ringingAlarmId"

    @Published var alarms: [Alarm] = [] {
        didSet {
            saveAlarms()
        }
    }

    // 鳴動中のアラームID（タスクキルしても保持）
    @Published var ringingAlarmId: UUID? = nil {
        didSet {
            if let id = ringingAlarmId {
                UserDefaults.standard.set(id.uuidString, forKey: ringingKey)
            } else {
                UserDefaults.standard.removeObject(forKey: ringingKey)
            }
            print("鳴動中アラームID: \(ringingAlarmId?.uuidString ?? "なし")")
        }
    }

    // 鳴動中のアラームを取得
    var ringingAlarm: Alarm? {
        guard let id = ringingAlarmId else { return nil }
        return alarms.first { $0.id == id }
    }

    // 鳴動状態かどうか（後方互換性のため）
    var isRinging: Bool {
        ringingAlarmId != nil
    }

    // 設定画面を開いているかどうか（設定中はアラームをスキップ）
    @Published var isConfiguring = false

    private init() {
        loadAlarms()
        // 鳴動状態を復元
        if let idString = UserDefaults.standard.string(forKey: ringingKey),
           let id = UUID(uuidString: idString) {
            ringingAlarmId = id
            print("前回のアラームが未解除です: \(idString)")
        }
    }

    // MARK: - アラーム発火
    func triggerAlarm(id: UUID) {
        ringingAlarmId = id
    }

    // MARK: - アラーム解除（QRスキャン成功時のみ呼ぶ）
    func dismissAlarm() {
        if let id = ringingAlarmId {
            NotificationManager.shared.cancelAlarm(id: id.uuidString)
        }
        ringingAlarmId = nil
        NotificationManager.shared.clearBadge()
        print("アラームを正式に解除しました")
    }

    // MARK: - 保存

    private func saveAlarms() {
        do {
            let data = try JSONEncoder().encode(alarms)
            UserDefaults.standard.set(data, forKey: key)
            print("アラームを保存しました（\(alarms.count)件）")
        } catch {
            print("アラーム保存エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 読み込み

    private func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("保存されたアラームがありません")
            return
        }

        do {
            alarms = try JSONDecoder().decode([Alarm].self, from: data)
            print("アラームを読み込みました（\(alarms.count)件）")
        } catch {
            print("アラーム読み込みエラー: \(error.localizedDescription)")
            // 旧形式からのマイグレーション試行
            migrateFromSingleAlarm()
        }
    }

    // 旧形式（単一アラーム）からのマイグレーション
    private func migrateFromSingleAlarm() {
        let oldKey = "savedAlarm"
        guard let data = UserDefaults.standard.data(forKey: oldKey) else { return }

        do {
            let oldAlarm = try JSONDecoder().decode(Alarm.self, from: data)
            alarms = [oldAlarm]
            // 旧キーを削除
            UserDefaults.standard.removeObject(forKey: oldKey)
            print("旧形式からマイグレーションしました")
        } catch {
            print("マイグレーションエラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 追加

    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
    }

    // MARK: - 更新

    func updateAlarm(id: UUID, _ update: (inout Alarm) -> Void) {
        if let index = alarms.firstIndex(where: { $0.id == id }) {
            update(&alarms[index])
        }
    }

    // MARK: - 削除

    func deleteAlarm(id: UUID) {
        if let index = alarms.firstIndex(where: { $0.id == id }) {
            let alarm = alarms[index]
            // 録音ファイルも削除
            if let url = alarm.voiceRecordingURL {
                AudioManager.shared.deleteRecording(url: url)
            }
            // 通知をキャンセル
            NotificationManager.shared.cancelAlarm(id: alarm.id.uuidString)
            // 配列から削除
            alarms.remove(at: index)
        }
    }

    // MARK: - アラーム取得

    func getAlarm(id: UUID) -> Alarm? {
        alarms.first { $0.id == id }
    }
}

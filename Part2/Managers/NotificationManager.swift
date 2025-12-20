//
//  NotificationManager.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - UNUserNotificationCenterDelegate

    // アプリがフォアグラウンドの時も通知を表示
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // アラーム画面を表示
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .alarmTriggered, object: nil)
        }
        completionHandler([.banner, .sound, .badge])
    }

    // 通知をタップした時
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // アラーム画面を表示
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .alarmTriggered, object: nil)
        }
        completionHandler()
    }

    // MARK: - 通知許可の確認

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - 通知許可をリクエスト

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("通知許可エラー: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - アラーム通知をスケジュール

    func scheduleAlarm(for alarm: Alarm) {
        // 既存の通知をキャンセル
        cancelAlarm(id: alarm.id.uuidString)

        guard alarm.isEnabled else { return }

        // 時刻からトリガーを作成
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarm.time)
        let minute = calendar.component(.minute, from: alarm.time)

        // メインのアラーム通知
        scheduleMainAlarm(alarmId: alarm.id.uuidString, hour: hour, minute: minute, label: alarm.label)

        // 繰り返し通知（1分おきに10回）- タスクキルされても通知が届く
        scheduleRepeatedNotifications(alarmId: alarm.id.uuidString, hour: hour, minute: minute)

        print("アラームをスケジュール: \(hour):\(minute)（繰り返し通知含む）")
    }

    // メインのアラーム通知
    private func scheduleMainAlarm(alarmId: String, hour: Int, minute: Int, label: String?) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ 起きまsho"
        content.body = label ?? "起きる時間です！"
        content.sound = UNNotificationSound.default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: alarmId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("メイン通知スケジュールエラー: \(error.localizedDescription)")
            }
        }
    }

    // 繰り返し通知をスケジュール（しつこく通知を送り続ける - 30秒間隔で60回 = 30分間）
    private func scheduleRepeatedNotifications(alarmId: String, hour: Int, minute: Int) {
        let messages = [
            "まだ寝てる？起きて！",
            "QRをスキャンして！",
            "起きないと止まりません！",
            "おーい！起きろー！",
            "二度寝禁止！",
            "今日も頑張ろう！",
            "起きてスキャン！",
            "まだ？？",
            "起きまsho！！",
            "本当に起きて！",
            "しつこいよ〜",
            "まだ寝てるの？",
            "QRスキャンまで止まらない！",
            "起きて起きて！",
            "目を開けて！"
        ]

        // テスト用: 5秒間隔で60通知 = 5分間
        // 本番用: 30秒間隔に戻す
        let intervalSeconds = 5.0  // TODO: 本番では30.0に変更

        // アラーム時刻を計算（次の発火時刻）
        let calendar = Calendar.current
        var alarmDateComponents = DateComponents()
        alarmDateComponents.hour = hour
        alarmDateComponents.minute = minute
        alarmDateComponents.second = 0

        guard let alarmDate = calendar.nextDate(after: Date(), matching: alarmDateComponents, matchingPolicy: .nextTime) else {
            print("アラーム時刻の計算に失敗")
            return
        }

        // アラーム時刻までの秒数を計算
        let secondsUntilAlarm = alarmDate.timeIntervalSince(Date())
        print("アラームまで \(Int(secondsUntilAlarm)) 秒")

        for i in 1...60 {
            let content = UNMutableNotificationContent()
            content.title = "⏰ 起きまsho (\(i)/60)"
            content.body = messages[i % messages.count]
            content.sound = UNNotificationSound.default
            content.badge = NSNumber(value: i)

            // アラーム時刻 + (i * 間隔) 秒後に通知
            let totalSecondsFromNow = secondsUntilAlarm + (Double(i) * intervalSeconds)

            // 最低1秒以上必要
            guard totalSecondsFromNow > 1 else {
                print("通知\(i)はスキップ（時間が過ぎている）")
                continue
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: totalSecondsFromNow, repeats: false)

            let request = UNNotificationRequest(
                identifier: "\(alarmId)_repeat_\(i)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("繰り返し通知\(i)エラー: \(error.localizedDescription)")
                }
            }
        }

        print("繰り返し通知60回（\(Int(intervalSeconds))秒間隔）をスケジュール完了")
    }

    // MARK: - アラーム通知をキャンセル

    func cancelAlarm(id: String) {
        // メイン通知と繰り返し通知（60回）を全てキャンセル
        var identifiers = [id]
        for i in 1...60 {
            identifiers.append("\(id)_repeat_\(i)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        print("アラームをキャンセル: \(id)（繰り返し通知60回含む）")
    }

    // MARK: - 全ての通知をキャンセル

    func cancelAllAlarms() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("全てのアラームをキャンセル")
    }

    // MARK: - バッジをクリア

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("バッジクリアエラー: \(error.localizedDescription)")
            }
        }
    }
}

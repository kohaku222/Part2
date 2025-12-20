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

    // 繰り返し通知をスケジュール（しつこく通知を送り続ける）
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
            "本当に起きて！"
        ]

        for i in 1...10 {
            let content = UNMutableNotificationContent()
            content.title = "⏰ 起きまsho"
            content.body = messages[i - 1]
            content.sound = UNNotificationSound.default
            content.badge = NSNumber(value: i)

            // 1分ごとに通知
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            let newMinute = (minute + i) % 60
            let hourOffset = (minute + i) / 60
            dateComponents.minute = newMinute
            dateComponents.hour = (hour + hourOffset) % 24

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

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
    }

    // MARK: - アラーム通知をキャンセル

    func cancelAlarm(id: String) {
        // メイン通知と繰り返し通知を全てキャンセル
        var identifiers = [id]
        for i in 1...10 {
            identifiers.append("\(id)_repeat_\(i)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("アラームをキャンセル: \(id)（繰り返し通知含む）")
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

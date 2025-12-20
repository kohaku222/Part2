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

        let content = UNMutableNotificationContent()
        content.title = "⏰ モチベーション目覚まし"
        content.body = alarm.label ?? "起きる時間です！"
        content.sound = UNNotificationSound.default
        content.badge = 1

        // 時刻からトリガーを作成
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarm.time)
        let minute = calendar.component(.minute, from: alarm.time)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知スケジュールエラー: \(error.localizedDescription)")
            } else {
                print("アラームをスケジュール: \(hour):\(minute)")
            }
        }
    }

    // MARK: - アラーム通知をキャンセル

    func cancelAlarm(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        print("アラームをキャンセル: \(id)")
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

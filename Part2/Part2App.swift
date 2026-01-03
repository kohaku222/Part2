//
//  Part2App.swift
//  Part2
//
//  Created by 池田　聖 on 2025/12/20.
//

import SwiftUI

@main
struct Part2App: App {
    // 通知マネージャーをアプリ全体で共有
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var alarmStorage = AlarmStorage.shared

    // モチベーション再生状態
    @State private var showMotivationPlayback = false
    @State private var dismissedAlarmAudioURL: URL? = nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(notificationManager)

                // アラーム鳴動画面（フルスクリーンオーバーレイ）
                // ringingAlarmIdがあればタスクキル後も表示
                if let alarm = alarmStorage.ringingAlarm {
                    AlarmRingingView(alarm: alarm) {
                        // アラームが正式に解除された時
                        let hasVoice = alarm.hasVoiceRecording
                        let voiceURL = alarm.voiceRecordingURL
                        alarmStorage.dismissAlarm()
                        // 音声が録音されている場合はモチベーション再生へ
                        if hasVoice, let url = voiceURL {
                            dismissedAlarmAudioURL = url
                            showMotivationPlayback = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }

                // モチベーション再生画面
                if showMotivationPlayback,
                   let audioURL = dismissedAlarmAudioURL {
                    MotivationPlaybackView(audioURL: audioURL) {
                        showMotivationPlayback = false
                        dismissedAlarmAudioURL = nil
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .animation(.easeInOut, value: alarmStorage.isRinging)
            .animation(.easeInOut, value: showMotivationPlayback)
            .onAppear {
                // アプリ起動時に通知許可をリクエスト
                notificationManager.requestAuthorization()
                // 前回の未解除アラームがあればログ出力
                if alarmStorage.isRinging {
                    print("アプリ起動: 未解除のアラームがあります")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .alarmTriggered)) { notification in
                // アラームがトリガーされた時 - 状態を保存
                if let alarmId = notification.userInfo?["alarmId"] as? String,
                   let uuid = UUID(uuidString: alarmId) {
                    alarmStorage.triggerAlarm(id: uuid)
                } else if let firstAlarm = alarmStorage.alarms.first(where: { $0.isEnabled }) {
                    // フォールバック: 有効な最初のアラームを鳴動
                    alarmStorage.triggerAlarm(id: firstAlarm.id)
                }
            }
        }
    }
}

// 通知名の拡張
extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
}

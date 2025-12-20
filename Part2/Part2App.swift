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

    // アラームフロー状態管理
    @State private var showAlarmRinging = false
    @State private var showMotivationPlayback = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(notificationManager)

                // アラーム鳴動画面（フルスクリーンオーバーレイ）
                if showAlarmRinging, let alarm = alarmStorage.alarm {
                    AlarmRingingView(alarm: alarm) {
                        showAlarmRinging = false
                        // 音声が録音されている場合はモチベーション再生へ
                        if alarm.hasVoiceRecording {
                            showMotivationPlayback = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }

                // モチベーション再生画面
                if showMotivationPlayback,
                   let alarm = alarmStorage.alarm,
                   let audioURL = alarm.voiceRecordingURL {
                    MotivationPlaybackView(audioURL: audioURL) {
                        showMotivationPlayback = false
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .animation(.easeInOut, value: showAlarmRinging)
            .animation(.easeInOut, value: showMotivationPlayback)
            .onAppear {
                // アプリ起動時に通知許可をリクエスト
                notificationManager.requestAuthorization()
            }
            .onReceive(NotificationCenter.default.publisher(for: .alarmTriggered)) { _ in
                // アラームがトリガーされた時
                showAlarmRinging = true
            }
        }
    }
}

// 通知名の拡張
extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
}

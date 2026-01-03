//
//  Part2App.swift
//  Part2
//
//  Created by 池田　聖 on 2025/12/20.
//

import SwiftUI
import AVFoundation

@main
struct Part2App: App {
    // 通知マネージャーをアプリ全体で共有
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var alarmStorage = AlarmStorage.shared

    // モチベーション再生状態
    @State private var showMotivationPlayback = false
    @State private var dismissedAlarmAudioURL: URL? = nil

    // ライブラリ保存確認
    @State private var showSaveToLibraryPrompt = false
    @State private var recordingToSaveURL: URL? = nil
    @State private var recordingSaveName = ""

    // 初回セットアップガイド
    @State private var showSetupGuide = false

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
                        print("🔔 アラーム解除: hasVoice=\(hasVoice), voiceURL=\(voiceURL?.absoluteString ?? "nil")")
                        alarmStorage.dismissAlarm()
                        // 音声が録音されている場合はモチベーション再生へ
                        if hasVoice, let url = voiceURL {
                            print("🎵 モチベーション再生開始: \(url.lastPathComponent)")
                            dismissedAlarmAudioURL = url
                            showMotivationPlayback = true
                        } else {
                            print("⚠️ 音声なし、またはURLがnil - セッション終了")
                            // モチベーション再生がないのでここでセッション終了
                            do {
                                try AVAudioSession.sharedInstance().setActive(false)
                            } catch {
                                print("⚠️ セッション非アクティブ化エラー: \(error.localizedDescription)")
                            }
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
                        // ライブラリに未保存の場合は保存確認を表示
                        checkAndPromptToSave(url: audioURL)
                        dismissedAlarmAudioURL = nil
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .alert("ライブラリに保存しますか？", isPresented: $showSaveToLibraryPrompt) {
                TextField("録音の名前", text: $recordingSaveName)
                Button("保存") {
                    saveRecordingToLibrary()
                }
                Button("保存しない", role: .cancel) {
                    recordingToSaveURL = nil
                    recordingSaveName = ""
                }
            } message: {
                Text("この録音をライブラリに保存して再利用できるようにしますか？")
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
                // 初回起動時はセットアップガイドを表示
                if !UserDefaults.standard.bool(forKey: "hasCompletedSetup") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSetupGuide = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showSetupGuide) {
                SetupGuideView {
                    showSetupGuide = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .alarmTriggered)) { notification in
                // アラームがトリガーされた時 - 状態を保存
                print("📲 alarmTriggered通知受信")
                if let alarmId = notification.userInfo?["alarmId"] as? String,
                   let uuid = UUID(uuidString: alarmId) {
                    print("📲 アラームID指定: \(alarmId)")
                    alarmStorage.triggerAlarm(id: uuid)
                } else if let firstAlarm = alarmStorage.alarms.first(where: { $0.isEnabled }) {
                    // フォールバック: 有効な最初のアラームを鳴動
                    print("📲 フォールバック: \(firstAlarm.id), hasVoice=\(firstAlarm.hasVoiceRecording)")
                    alarmStorage.triggerAlarm(id: firstAlarm.id)
                } else {
                    print("⚠️ 有効なアラームが見つからない")
                }
            }
        }
    }

    // 録音がライブラリに未保存かチェックして保存確認を表示
    private func checkAndPromptToSave(url: URL) {
        let fileName = url.lastPathComponent
        // 既にライブラリに保存されている場合はスキップ
        if SavedRecordingStorage.shared.findRecording(by: fileName) != nil {
            print("この録音は既にライブラリに保存されています")
            return
        }
        // 保存確認を表示
        recordingToSaveURL = url
        recordingSaveName = ""
        showSaveToLibraryPrompt = true
    }

    // 録音をライブラリに保存
    private func saveRecordingToLibrary() {
        guard let url = recordingToSaveURL else { return }

        let duration = AudioManager.shared.getAudioDuration(url: url)
        let name = recordingSaveName.isEmpty
            ? "録音 \(SavedRecordingStorage.shared.savedRecordings.count + 1)"
            : recordingSaveName

        _ = SavedRecordingStorage.shared.addRecording(name: name, url: url, duration: duration)
        print("ライブラリに保存: \(name)")

        recordingToSaveURL = nil
        recordingSaveName = ""
    }
}

// 通知名の拡張
extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
}

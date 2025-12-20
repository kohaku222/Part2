//
//  ContentView.swift
//  Part2
//
//  Created by 池田　聖 on 2025/12/20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var alarmStorage = AlarmStorage.shared

    @State private var showSetAlarm = false
    @State private var showRecordVoice = false
    @State private var showQRScanner = false

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                // 通知許可の警告（許可されていない場合）
                if !notificationManager.isAuthorized {
                    notificationWarningView
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }

                // 現在時刻
                VStack(spacing: 16) {
                    TimeDisplayView(size: .extraLarge)

                    Text(currentDateString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 40)

                // アラーム表示エリア
                ScrollView {
                    VStack(spacing: 20) {
                        if let alarm = alarmStorage.alarm {
                            AlarmCardView(
                                alarm: alarm,
                                onToggle: toggleAlarm,
                                onDelete: deleteAlarm,
                                onRecordVoice: { showRecordVoice = true },
                                onSetupQR: { showQRScanner = true }
                            )
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
            }

            // 追加ボタン（アラームがない場合のみ表示）
            if alarmStorage.alarm == nil {
                VStack {
                    Spacer()
                    addButton
                        .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showSetAlarm) {
            SetAlarmView(onSave: createAlarm)
        }
        .sheet(isPresented: $showRecordVoice) {
            VoiceRecorderView(existingURL: alarmStorage.alarm?.voiceRecordingURL) { url in
                saveVoiceRecording(url: url)
            }
        }
        .sheet(isPresented: $showQRScanner) {
            CodeScannerView(
                isSetup: true,
                registeredCode: nil
            ) { code in
                saveQRCode(code: code)
            }
        }
    }

    // MARK: - Views

    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .foregroundColor(.blue)
                Text("モチベーション目覚まし")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "sparkles")
                .foregroundColor(.orange)
        }
    }

    private var notificationWarningView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("通知が許可されていません")
                .font(.caption)
            Spacer()
            Button("設定") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("アラームがありません")
                .font(.headline)

            Text("下のボタンから新しいアラームを作成しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var addButton: some View {
        Button(action: { showSetAlarm = true }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)

                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Computed Properties

    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（EEEE）"
        return formatter.string(from: Date())
    }

    // MARK: - Actions

    private func createAlarm(time: Date) {
        let newAlarm = Alarm(time: time)
        alarmStorage.alarm = newAlarm
        // 通知をスケジュール
        NotificationManager.shared.scheduleAlarm(for: newAlarm)
        showSetAlarm = false
    }

    private func toggleAlarm() {
        alarmStorage.updateAlarm { alarm in
            alarm.isEnabled.toggle()

            if alarm.isEnabled {
                NotificationManager.shared.scheduleAlarm(for: alarm)
            } else {
                NotificationManager.shared.cancelAlarm(id: alarm.id.uuidString)
            }
        }
    }

    private func deleteAlarm() {
        alarmStorage.deleteAlarm()
    }

    private func saveVoiceRecording(url: URL) {
        alarmStorage.updateAlarm { alarm in
            alarm.voiceRecordingURL = url
        }
    }

    private func saveQRCode(code: String) {
        alarmStorage.updateAlarm { alarm in
            alarm.qrCode = code
        }
    }
}

// MARK: - アラーム設定画面

struct SetAlarmView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTime = Date()
    var onSave: (Date) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("アラームを設定")
                    .font(.title2)
                    .fontWeight(.semibold)

                DatePicker(
                    "時刻",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button(action: {
                    onSave(selectedTime)
                }) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotificationManager.shared)
}

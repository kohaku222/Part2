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
    @State private var showEditAlarm = false
    @State private var showQRScanner = false

    // 編集中のアラームIDを追跡
    @State private var editingAlarmId: UUID? = nil

    // 録音UX改善: 選択シート・アクションシート用状態
    @State private var showVoiceActionSheet = false      // 未録音時の選択
    @State private var showRecordedActionSheet = false   // 録音済み時の選択
    @State private var showDirectRecorder = false        // 新規録音（名前なし）
    @State private var showRecordingLibrary = false      // ライブラリから選択
    @State private var showSaveToLibraryDialog = false   // ライブラリ保存ダイアログ
    @State private var recordingNameInput = ""           // 保存時の名前入力

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
                        if alarmStorage.alarms.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(alarmStorage.alarms) { alarm in
                                AlarmCardView(
                                    alarm: alarm,
                                    onToggle: { toggleAlarm(id: alarm.id) },
                                    onDelete: { deleteAlarm(id: alarm.id) },
                                    onRecordVoice: {
                                        editingAlarmId = alarm.id
                                        if alarm.hasVoiceRecording {
                                            showRecordedActionSheet = true   // 録音済み → 管理メニュー
                                        } else {
                                            showVoiceActionSheet = true      // 未録音 → 新規/選択
                                        }
                                    },
                                    onSetupQR: {
                                        editingAlarmId = alarm.id
                                        showQRScanner = true
                                    },
                                    onEditTime: {
                                        editingAlarmId = alarm.id
                                        showEditAlarm = true
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // 追加ボタンの余白
                }

                Spacer()
            }

            // 追加ボタン（常に表示）
            VStack {
                Spacer()
                addButton
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showSetAlarm) {
            SetAlarmView(onSave: createAlarm)
        }
        .sheet(isPresented: $showDirectRecorder) {
            // 新規録音（名前なしで直接アラームに紐づける）
            VoiceRecorderView(existingURL: editingAlarmVoiceURL) { url in
                saveVoiceRecording(url: url)
            }
        }
        .sheet(isPresented: $showRecordingLibrary) {
            // ライブラリから選択
            SavedRecordingListView { url in
                saveVoiceRecording(url: url)
            }
        }
        .sheet(isPresented: $showQRScanner) {
            SavedCodeListView { code in
                saveQRCode(code: code)
            }
        }
        .sheet(isPresented: $showEditAlarm) {
            if let id = editingAlarmId,
               let alarm = alarmStorage.getAlarm(id: id) {
                EditAlarmView(currentTime: alarm.time, onSave: updateAlarmTime)
            }
        }
        // 未録音時の選択シート
        .confirmationDialog("録音方法を選択", isPresented: $showVoiceActionSheet, titleVisibility: .visible) {
            Button("新規録音") {
                showDirectRecorder = true
            }
            Button("保存済みから選択") {
                showRecordingLibrary = true
            }
            Button("キャンセル", role: .cancel) {}
        }
        // 録音済み時のアクションシート
        .confirmationDialog("録音の管理", isPresented: $showRecordedActionSheet, titleVisibility: .visible) {
            Button("再録音") {
                showDirectRecorder = true
            }
            Button("ライブラリに保存") {
                recordingNameInput = ""
                showSaveToLibraryDialog = true
            }
            Button("別の録音を選択") {
                showRecordingLibrary = true
            }
            Button("削除", role: .destructive) {
                deleteVoiceRecording()
            }
            Button("キャンセル", role: .cancel) {}
        }
        // ライブラリ保存ダイアログ
        .alert("ライブラリに保存", isPresented: $showSaveToLibraryDialog) {
            TextField("録音の名前", text: $recordingNameInput)
            Button("保存") {
                saveCurrentRecordingToLibrary()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この録音に名前をつけて保存します")
        }
        // 設定画面が開いている間はアラームをスキップ
        .onChange(of: isAnySheetPresented) { _, isPresented in
            alarmStorage.isConfiguring = isPresented
            print("設定画面状態: \(isPresented ? "開いている" : "閉じた")")
        }
    }

    // 編集中アラームの録音URL
    private var editingAlarmVoiceURL: URL? {
        guard let id = editingAlarmId else { return nil }
        return alarmStorage.getAlarm(id: id)?.voiceRecordingURL
    }

    // いずれかの設定画面が開いているかどうか
    private var isAnySheetPresented: Bool {
        showSetAlarm || showEditAlarm || showDirectRecorder ||
        showRecordingLibrary || showQRScanner ||
        showVoiceActionSheet || showRecordedActionSheet
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
        alarmStorage.addAlarm(newAlarm)
        // 通知をスケジュール
        NotificationManager.shared.scheduleAlarm(for: newAlarm)
        showSetAlarm = false
    }

    private func toggleAlarm(id: UUID) {
        alarmStorage.updateAlarm(id: id) { alarm in
            alarm.isEnabled.toggle()

            if alarm.isEnabled {
                NotificationManager.shared.scheduleAlarm(for: alarm)
            } else {
                NotificationManager.shared.cancelAlarm(id: alarm.id.uuidString)
            }
        }
    }

    private func deleteAlarm(id: UUID) {
        alarmStorage.deleteAlarm(id: id)
    }

    private func saveVoiceRecording(url: URL) {
        guard let id = editingAlarmId else { return }
        alarmStorage.updateAlarm(id: id) { alarm in
            alarm.voiceRecordingURL = url
        }
        editingAlarmId = nil
    }

    private func saveQRCode(code: String) {
        guard let id = editingAlarmId else { return }
        alarmStorage.updateAlarm(id: id) { alarm in
            alarm.qrCode = code
        }
        editingAlarmId = nil
    }

    private func updateAlarmTime(newTime: Date) {
        guard let id = editingAlarmId else { return }
        alarmStorage.updateAlarm(id: id) { alarm in
            alarm.time = newTime
        }
        // 通知を再スケジュール
        if let alarm = alarmStorage.getAlarm(id: id), alarm.isEnabled {
            NotificationManager.shared.scheduleAlarm(for: alarm)
        }
        showEditAlarm = false
        editingAlarmId = nil
    }

    // 録音を削除（アラームとの紐づけを解除）
    private func deleteVoiceRecording() {
        guard let id = editingAlarmId,
              let alarm = alarmStorage.getAlarm(id: id),
              let url = alarm.voiceRecordingURL else { return }

        // ライブラリに保存されていない録音のみファイルを削除
        let fileName = url.lastPathComponent
        let isInLibrary = SavedRecordingStorage.shared.findRecording(by: fileName) != nil
        if !isInLibrary {
            AudioManager.shared.deleteRecording(url: url)
            print("録音ファイルを削除: \(url)")
        } else {
            print("ライブラリの録音なのでファイルは保持: \(fileName)")
        }

        // アラームとの紐づけを解除
        alarmStorage.updateAlarm(id: id) { alarm in
            alarm.voiceRecordingURL = nil
        }
        editingAlarmId = nil
    }

    // 現在の録音をライブラリに保存
    private func saveCurrentRecordingToLibrary() {
        guard let id = editingAlarmId,
              let alarm = alarmStorage.getAlarm(id: id),
              let url = alarm.voiceRecordingURL else {
            editingAlarmId = nil
            return
        }

        // 既にライブラリに存在するか確認
        let fileName = url.lastPathComponent
        if SavedRecordingStorage.shared.findRecording(by: fileName) != nil {
            print("既にライブラリに保存されています: \(fileName)")
            editingAlarmId = nil
            return
        }

        // 録音時間を取得
        let duration = AudioManager.shared.getAudioDuration(url: url)
        let name = recordingNameInput.isEmpty ? "録音 \(SavedRecordingStorage.shared.savedRecordings.count + 1)" : recordingNameInput

        _ = SavedRecordingStorage.shared.addRecording(name: name, url: url, duration: duration)
        print("ライブラリに保存: \(name)")
        editingAlarmId = nil
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

// MARK: - アラーム編集画面

struct EditAlarmView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTime: Date
    var onSave: (Date) -> Void

    init(currentTime: Date, onSave: @escaping (Date) -> Void) {
        _selectedTime = State(initialValue: currentTime)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("時間を変更")
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
                    Text("変更を保存")
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

//
//  SavedRecordingListView.swift
//  Part2
//
//  Created by Claude on 2025/12/24.
//

import SwiftUI

struct SavedRecordingListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var recordingStorage = SavedRecordingStorage.shared
    @StateObject private var audioManager = AudioManager.shared

    var onSelect: (URL) -> Void  // 選択時にURLを返す

    @State private var showRecorder = false
    @State private var editingRecording: SavedRecording?
    @State private var newRecordingName: String = ""
    @State private var showDeleteConfirm = false
    @State private var recordingToDelete: SavedRecording?
    @State private var playingRecordingId: UUID?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if recordingStorage.savedRecordings.isEmpty {
                    // 空の状態
                    emptyStateView
                } else {
                    // 録音一覧
                    List {
                        ForEach(recordingStorage.savedRecordings) { recording in
                            SavedRecordingRow(
                                recording: recording,
                                isPlaying: playingRecordingId == recording.id && audioManager.isPlaying,
                                onSelect: {
                                    if let url = recording.fileURL {
                                        onSelect(url)
                                        dismiss()
                                    }
                                },
                                onPlay: {
                                    togglePlayback(recording: recording)
                                },
                                onEdit: {
                                    editingRecording = recording
                                    newRecordingName = recording.name
                                },
                                onDelete: {
                                    recordingToDelete = recording
                                    showDeleteConfirm = true
                                }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("保存済み録音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        stopPlaybackIfNeeded()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showRecorder = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showRecorder) {
                VoiceRecorderView(existingURL: nil) { url in
                    // 録音完了後、名前入力ダイアログを表示
                    newRecordingName = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // 一時的にURLを保存
                        temporaryURL = url
                        showNameInputForNew = true
                    }
                }
            }
            .alert("録音に名前を付ける", isPresented: $showNameInputForNew) {
                TextField("例: 朝のモチベーション", text: $newRecordingName)
                Button("保存") {
                    if let url = temporaryURL {
                        let duration = audioManager.recordingTime
                        let name = newRecordingName.isEmpty ? "録音 \(recordingStorage.savedRecordings.count + 1)" : newRecordingName
                        let savedRecording = recordingStorage.addRecording(name: name, url: url, duration: duration)
                        // 保存後すぐに選択
                        if let fileURL = savedRecording.fileURL {
                            onSelect(fileURL)
                            dismiss()
                        }
                    }
                    temporaryURL = nil
                }
                Button("キャンセル", role: .cancel) {
                    // キャンセル時は録音ファイルを削除
                    if let url = temporaryURL {
                        audioManager.deleteRecording(url: url)
                    }
                    temporaryURL = nil
                }
            } message: {
                Text("この録音を識別するための名前を入力してください")
            }
            .alert("名前を変更", isPresented: Binding(
                get: { editingRecording != nil },
                set: { if !$0 { editingRecording = nil } }
            )) {
                TextField("新しい名前", text: $newRecordingName)
                Button("保存") {
                    if let recording = editingRecording {
                        recordingStorage.updateRecording(id: recording.id, newName: newRecordingName)
                    }
                    editingRecording = nil
                }
                Button("キャンセル", role: .cancel) {
                    editingRecording = nil
                }
            }
            .alert("削除の確認", isPresented: $showDeleteConfirm) {
                Button("削除", role: .destructive) {
                    if let recording = recordingToDelete {
                        // 再生中なら停止
                        if playingRecordingId == recording.id {
                            audioManager.stopPlaying()
                            playingRecordingId = nil
                        }
                        recordingStorage.deleteRecording(id: recording.id)
                    }
                    recordingToDelete = nil
                }
                Button("キャンセル", role: .cancel) {
                    recordingToDelete = nil
                }
            } message: {
                Text("「\(recordingToDelete?.name ?? "")」を削除しますか？\n録音ファイルも削除されます。")
            }
            .onDisappear {
                stopPlaybackIfNeeded()
            }
        }
    }

    @State private var showNameInputForNew = false
    @State private var temporaryURL: URL?

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "mic.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("保存された録音がありません")
                .font(.headline)

            Text("新しいモチベーションメッセージを\n録音して保存しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showRecorder = true }) {
                HStack {
                    Image(systemName: "mic.fill")
                    Text("録音して追加")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 10)

            Spacer()
        }
    }

    private func togglePlayback(recording: SavedRecording) {
        if playingRecordingId == recording.id && audioManager.isPlaying {
            audioManager.stopPlaying()
            playingRecordingId = nil
        } else {
            // 他の再生を停止
            audioManager.stopPlaying()
            if let url = recording.fileURL {
                audioManager.startPlaying(url: url)
                playingRecordingId = recording.id
            }
        }
    }

    private func stopPlaybackIfNeeded() {
        if audioManager.isPlaying {
            audioManager.stopPlaying()
            playingRecordingId = nil
        }
    }
}

// MARK: - 録音行

struct SavedRecordingRow: View {
    let recording: SavedRecording
    let isPlaying: Bool
    var onSelect: () -> Void
    var onPlay: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var showActionSheet = false

    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }

            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(recording.durationString)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)

                    Text(recording.createdAtString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 再生ボタン
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isPlaying ? .red : .green)
            }
            .buttonStyle(.plain)

            // 操作ボタン（タップで即座に反応）
            Button(action: { showActionSheet = true }) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .confirmationDialog("操作を選択", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("この録音を使用", action: onSelect)
            Button("名前を変更", action: onEdit)
            Button("削除", role: .destructive, action: onDelete)
            Button("キャンセル", role: .cancel) {}
        }
    }
}

#Preview {
    SavedRecordingListView { url in
        print("Selected: \(url)")
    }
}

//
//  VoiceRecorderView.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI
import AVFoundation

struct VoiceRecorderView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioManager = AudioManager.shared

    var existingURL: URL?
    var onSave: (URL) -> Void

    @State private var hasRecording = false
    @State private var currentURL: URL?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // タイトル
                VStack(spacing: 8) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("モチベーションメッセージ")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("朝起きた自分に向けて\n応援メッセージを録音しましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // 録音時間表示
                Text(audioManager.formatTime(audioManager.recordingTime))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(audioManager.isRecording ? .red : .primary)

                // 波形アニメーション（録音中）
                if audioManager.isRecording {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            WaveBar(index: index)
                        }
                    }
                    .frame(height: 40)
                }

                Spacer()

                // コントロールボタン
                HStack(spacing: 40) {
                    // 再生ボタン（録音済みの場合）
                    if hasRecording || existingURL != nil {
                        Button(action: togglePlayback) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 60, height: 60)

                                Image(systemName: audioManager.isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }
                        }
                        .disabled(audioManager.isRecording)
                    }

                    // 録音ボタン
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(audioManager.isRecording ? Color.red : Color.red.opacity(0.2))
                                .frame(width: 80, height: 80)

                            if audioManager.isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    .disabled(audioManager.isPlaying)

                    // 削除ボタン（録音済みの場合）
                    if hasRecording || existingURL != nil {
                        Button(action: { showDeleteConfirm = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                        }
                        .disabled(audioManager.isRecording || audioManager.isPlaying)
                    }
                }

                // 保存ボタン
                if hasRecording, let url = currentURL {
                    Button(action: {
                        onSave(url)
                        dismiss()
                    }) {
                        Text("この録音を保存")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        // 録音中なら停止
                        if audioManager.isRecording {
                            audioManager.stopRecording()
                        }
                        if audioManager.isPlaying {
                            audioManager.stopPlaying()
                        }
                        dismiss()
                    }
                }
            }
            .alert("録音を削除", isPresented: $showDeleteConfirm) {
                Button("削除", role: .destructive) {
                    deleteRecording()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この録音を削除しますか？")
            }
            .onAppear {
                // 既存の録音があれば設定
                if let url = existingURL {
                    currentURL = url
                    hasRecording = true
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        if audioManager.isRecording {
            audioManager.stopRecording()
            if let url = audioManager.recordingURL {
                currentURL = url
                hasRecording = true
            }
        } else {
            // 既存の録音があれば削除
            if let url = currentURL, existingURL == nil {
                audioManager.deleteRecording(url: url)
            }
            hasRecording = false
            audioManager.startRecording()
        }
    }

    private func togglePlayback() {
        if audioManager.isPlaying {
            audioManager.stopPlaying()
        } else {
            if let url = currentURL ?? existingURL {
                audioManager.startPlaying(url: url)
            }
        }
    }

    private func deleteRecording() {
        if audioManager.isPlaying {
            audioManager.stopPlaying()
        }

        if let url = currentURL {
            audioManager.deleteRecording(url: url)
        }

        currentURL = nil
        hasRecording = false
        audioManager.recordingTime = 0
    }
}

// MARK: - 波形アニメーション

struct WaveBar: View {
    let index: Int
    @State private var animating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.red)
            .frame(width: 4, height: animating ? 40 : 10)
            .animation(
                Animation.easeInOut(duration: 0.4)
                    .repeatForever()
                    .delay(Double(index) * 0.1),
                value: animating
            )
            .onAppear {
                animating = true
            }
    }
}

#Preview {
    VoiceRecorderView(existingURL: nil) { url in
        print("Saved: \(url)")
    }
}

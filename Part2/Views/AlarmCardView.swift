//
//  AlarmCardView.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI

struct AlarmCardView: View {
    let alarm: Alarm
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onRecordVoice: () -> Void
    var onSetupQR: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 上部: アラーム時刻とトグルボタン
            HStack {
                // アイコンと時刻
                HStack(spacing: 16) {
                    // ベルアイコン
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(alarm.isEnabled ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .frame(width: 50, height: 50)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 24))
                            .foregroundColor(alarm.isEnabled ? .blue : .gray)
                    }

                    // 時刻表示
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alarm.timeString)
                            .font(.system(size: 36, weight: .light, design: .rounded))
                            .monospacedDigit()

                        if let label = alarm.label {
                            Text(label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // ON/OFF ボタン
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(alarm.isEnabled ? Color.blue : Color.gray.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: "power")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(alarm.isEnabled ? .white : .gray)
                    }
                }
            }

            // 中部: 機能ボタン
            HStack(spacing: 12) {
                // 声を録音ボタン
                Button(action: onRecordVoice) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14))
                        Text(alarm.hasVoiceRecording ? "録音済み" : "声を録音")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(alarm.hasVoiceRecording ? Color.blue : Color.gray.opacity(0.1))
                    .foregroundColor(alarm.hasVoiceRecording ? .white : .primary)
                    .cornerRadius(10)
                }

                // QRを登録ボタン
                Button(action: onSetupQR) {
                    HStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 14))
                        Text(alarm.hasQRCode ? "QR設定済み" : "QRを登録")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(alarm.hasQRCode ? Color.blue : Color.gray.opacity(0.1))
                    .foregroundColor(alarm.hasQRCode ? .white : .primary)
                    .cornerRadius(10)
                }

                // 削除ボタン
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
            }

            // 下部: 設定が足りない場合のメッセージ
            if !alarm.hasVoiceRecording || !alarm.hasQRCode {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }

    // 設定状態に応じたメッセージ
    private var statusMessage: String {
        if !alarm.hasVoiceRecording && !alarm.hasQRCode {
            return "声の録音とQRコードの登録が必要です"
        } else if alarm.hasVoiceRecording && !alarm.hasQRCode {
            return "QRコードを登録してください"
        } else if !alarm.hasVoiceRecording && alarm.hasQRCode {
            return "声を録音してください"
        }
        return ""
    }
}

#Preview {
    VStack(spacing: 20) {
        // 全て未設定
        AlarmCardView(
            alarm: Alarm(time: Date(), isEnabled: true),
            onToggle: {},
            onDelete: {},
            onRecordVoice: {},
            onSetupQR: {}
        )

        // 全て設定済み
        AlarmCardView(
            alarm: Alarm(
                time: Date(),
                isEnabled: false,
                voiceRecordingURL: URL(string: "file://test"),
                qrCode: "test-qr",
                label: "朝の目覚まし"
            ),
            onToggle: {},
            onDelete: {},
            onRecordVoice: {},
            onSetupQR: {}
        )
    }
    .padding()
    .background(Color(.systemGray6))
}

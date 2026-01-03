//
//  AlarmRingingView.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct AlarmRingingView: View {
    let alarm: Alarm
    var onStop: () -> Void

    @State private var isAnimating = false
    @State private var showScanner = false

    // 共有アラーム音プレーヤー
    @ObservedObject private var soundPlayer = AlarmSoundPlayer.shared

    var body: some View {
        ZStack {
            // 背景（パルスアニメーション）
            Color.red
                .opacity(isAnimating ? 0.3 : 0.1)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)

            VStack(spacing: 40) {
                Spacer()

                // ベルアイコン（揺れるアニメーション）
                Image(systemName: "bell.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(isAnimating ? 15 : -15))
                    .animation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true), value: isAnimating)

                // 時刻表示
                Text(alarm.timeString)
                    .font(.system(size: 72, weight: .light, design: .rounded))

                Text("アラーム")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Spacer()

                // QRコードが登録されている場合
                if alarm.hasQRCode {
                    VStack(spacing: 20) {
                        Text("QR/バーコードをスキャンして解除")
                            .font(.headline)

                        Button(action: {
                            soundPlayer.pauseAlarm()
                            showScanner = true
                        }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 24))
                                Text("スキャンして解除")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    // QRコードが登録されていない場合は直接停止
                    Button(action: {
                        soundPlayer.stopAlarm()
                        onStop()
                    }) {
                        Text("アラームを停止")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            // 共有プレーヤーでアラーム開始（既に再生中なら何もしない）
            soundPlayer.startAlarm()
        }
        .onDisappear {
            // タスクキル時は音声のみ停止（通知は継続）
            soundPlayer.stopAlarm()
        }
        .sheet(isPresented: $showScanner, onDismiss: {
            // スキャナーが閉じたらアラーム再開（成功時以外）
            if soundPlayer.isPlaying {
                soundPlayer.resumeAlarm()
            }
        }) {
            CodeScannerView(
                isSetup: false,
                registeredCode: alarm.qrCode,
                timeLimit: 30
            ) { code, _ in
                if code == alarm.qrCode {
                    soundPlayer.stopAlarm()
                    onStop()
                }
            }
        }
    }
}

#Preview {
    AlarmRingingView(
        alarm: Alarm(time: Date(), isEnabled: true, qrCode: "test")
    ) {
        print("Stopped")
    }
}

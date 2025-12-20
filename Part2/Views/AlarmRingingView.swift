//
//  AlarmRingingView.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI
import AVFoundation

struct AlarmRingingView: View {
    let alarm: Alarm
    var onStop: () -> Void

    @State private var isAnimating = false
    @State private var showScanner = false

    // アラーム音
    @State private var audioPlayer: AVAudioPlayer?

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

                        Button(action: { showScanner = true }) {
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
                        stopAlarm()
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
            playAlarmSound()
        }
        .onDisappear {
            // タスクキル時は音声のみ停止（通知は継続）
            // 正式解除時はonStopコールバック経由でdismissAlarm()が呼ばれる
            stopAudioOnly()
        }
        .sheet(isPresented: $showScanner) {
            CodeScannerView(
                isSetup: false,
                registeredCode: alarm.qrCode
            ) { code, _ in
                if code == alarm.qrCode {
                    stopAlarm()
                    onStop()
                }
            }
        }
    }

    private func playAlarmSound() {
        // オーディオセッションを設定（バックグラウンド再生 + サイレントモード無視）
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("オーディオセッション設定完了")
        } catch {
            print("オーディオセッション設定エラー: \(error.localizedDescription)")
        }

        // アラーム音を再生
        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
            // デフォルトのシステム音を繰り返し再生
            playSystemSoundLoop()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // 無限ループ
            audioPlayer?.volume = 1.0 // 最大音量
            audioPlayer?.play()
            print("アラーム音再生開始")
        } catch {
            print("アラーム音再生エラー: \(error.localizedDescription)")
            playSystemSoundLoop()
        }
    }

    // システム音を繰り返し再生（alarm.mp3がない場合のフォールバック）
    private func playSystemSoundLoop() {
        // 1秒ごとにシステム音を鳴らす
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.isAnimating {
                AudioServicesPlaySystemSound(SystemSoundID(1005))
            } else {
                timer.invalidate()
            }
        }
    }

    // 音声のみ停止（通知はキャンセルしない - タスクキル対策）
    private func stopAudioOnly() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAnimating = false

        // オーディオセッションを非アクティブに
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("オーディオセッション停止エラー: \(error.localizedDescription)")
        }
        print("音声停止（通知は継続）")
    }

    // 完全停止（QRスキャン成功時 or QR未設定時の停止ボタン）
    private func stopAlarm() {
        stopAudioOnly()
        // 通知のキャンセルはPart2App側のdismissAlarm()で行う
        print("アラーム完全停止")
    }
}

#Preview {
    AlarmRingingView(
        alarm: Alarm(time: Date(), isEnabled: true, qrCode: "test")
    ) {
        print("Stopped")
    }
}

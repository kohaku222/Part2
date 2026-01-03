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

    // アラーム音（AVAudioPlayer - メディア音量で再生、強制MAX）
    @State private var audioPlayer: AVAudioPlayer?
    @State private var vibrationTimer: Timer?

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
                            pauseAlarmSound()
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
        .sheet(isPresented: $showScanner, onDismiss: {
            // スキャナーが閉じたらアラーム再開（成功時以外）
            // 注: stopAlarm()が呼ばれた場合はaudioPlayerがnilになっている
            if audioPlayer != nil {
                resumeAlarmSound()
            }
        }) {
            CodeScannerView(
                isSetup: false,
                registeredCode: alarm.qrCode,
                timeLimit: 30
            ) { code, _ in
                if code == alarm.qrCode {
                    stopAlarm()
                    onStop()
                }
            }
        }
    }

    private func playAlarmSound() {
        // オーディオセッションを設定（メディア音量で再生）
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("オーディオセッション設定完了")
        } catch {
            print("オーディオセッション設定エラー: \(error.localizedDescription)")
        }

        // 🔊 強制的に音量をMAXに設定（ユーザーが下げても即座に戻す）
        VolumeManager.shared.startForceMaxVolume()

        // AVAudioPlayerでメディア音量として再生（CAF形式を使用）
        if let url = Bundle.main.url(forResource: "alarm", withExtension: "caf") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1  // 無限ループ
                audioPlayer?.volume = 1.0  // プレイヤー音量もMAX
                audioPlayer?.play()
                print("アラーム音再生開始（AVAudioPlayer - メディア音量MAX強制）")
            } catch {
                print("AVAudioPlayer作成エラー: \(error.localizedDescription)")
                playSystemSoundLoop()
            }
        } else {
            print("alarm.cafが見つからないためシステム音を使用")
            playSystemSoundLoop()
        }

        // バイブレーションを定期的に実行
        startVibration()
    }

    // バイブレーションを定期的に実行
    private func startVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            if self.isAnimating {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }

    // システム音を繰り返し再生（alarm.cafがない場合のフォールバック）
    private func playSystemSoundLoop() {
        // 1秒ごとにシステム音 + バイブを鳴らす
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.isAnimating {
                AudioServicesPlayAlertSound(SystemSoundID(1005))
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            } else {
                timer.invalidate()
            }
        }
    }

    // 音声のみ停止（通知はキャンセルしない - タスクキル対策）
    private func stopAudioOnly() {
        // 音声停止
        audioPlayer?.stop()
        audioPlayer = nil

        // バイブレーションタイマー停止
        vibrationTimer?.invalidate()
        vibrationTimer = nil

        // 🔊 強制音量MAX監視を停止（元の音量に戻す）
        VolumeManager.shared.stopForceMaxVolume(restoreVolume: true)

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

    // 一時停止（QRスキャン中）
    private func pauseAlarmSound() {
        audioPlayer?.pause()
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        VolumeManager.shared.stopForceMaxVolume(restoreVolume: false)
        print("アラーム一時停止")
    }

    // 再開（QRスキャン失敗/タイムアウト時）
    private func resumeAlarmSound() {
        VolumeManager.shared.startForceMaxVolume()
        audioPlayer?.play()
        startVibration()
        print("アラーム再開")
    }
}

#Preview {
    AlarmRingingView(
        alarm: Alarm(time: Date(), isEnabled: true, qrCode: "test")
    ) {
        print("Stopped")
    }
}

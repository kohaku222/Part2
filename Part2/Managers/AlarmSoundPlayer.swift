//
//  AlarmSoundPlayer.swift
//  Part2
//
//  アラーム音再生を管理するシングルトン
//  通知受信時に即座に再生を開始し、AlarmRingingViewと共有する
//

import Foundation
import AVFoundation
import AudioToolbox

class AlarmSoundPlayer: NSObject, ObservableObject {
    static let shared = AlarmSoundPlayer()

    @Published var isPlaying = false

    private var audioPlayer: AVAudioPlayer?
    private var vibrationTimer: Timer?

    private override init() {
        super.init()
    }

    // MARK: - 再生開始（即座に）

    func startAlarm() {
        // 既に再生中なら何もしない
        guard !isPlaying else {
            print("アラーム既に再生中")
            return
        }

        print("🔊 AlarmSoundPlayer: 即座に再生開始")

        // オーディオセッションを設定
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("オーディオセッション設定エラー: \(error.localizedDescription)")
        }

        // 強制的に音量をMAXに設定
        VolumeManager.shared.startForceMaxVolume()

        // AVAudioPlayerで再生（CAF形式を使用）
        if let url = Bundle.main.url(forResource: "alarm", withExtension: "caf") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = 1.0
                audioPlayer?.play()
                isPlaying = true
                print("▶️ アラーム音再生開始")
            } catch {
                print("AVAudioPlayer作成エラー: \(error.localizedDescription)")
                playSystemSoundLoop()
            }
        } else {
            print("alarm.cafが見つからないためシステム音を使用")
            playSystemSoundLoop()
        }

        // バイブレーション開始
        startVibration()
    }

    // MARK: - 一時停止（QRスキャン中）

    func pauseAlarm() {
        audioPlayer?.pause()
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        VolumeManager.shared.stopForceMaxVolume(restoreVolume: false)
        print("⏸ アラーム一時停止")
    }

    // MARK: - 再開（QRスキャン失敗/タイムアウト時）

    func resumeAlarm() {
        guard isPlaying else { return }
        VolumeManager.shared.startForceMaxVolume()
        audioPlayer?.play()
        startVibration()
        print("▶️ アラーム再開")
    }

    // MARK: - 完全停止

    /// アラーム音を停止する
    /// - Parameter deactivateSession: trueの場合、オーディオセッションも非アクティブにする（デフォルトfalse）
    func stopAlarm(deactivateSession: Bool = false) {
        audioPlayer?.stop()
        audioPlayer = nil

        vibrationTimer?.invalidate()
        vibrationTimer = nil

        VolumeManager.shared.stopForceMaxVolume(restoreVolume: true)

        isPlaying = false

        // 明示的に指定された場合のみセッションを非アクティブに
        // （モチベーション再生に移行する場合はセッションを維持する必要がある）
        if deactivateSession {
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("オーディオセッション停止エラー: \(error.localizedDescription)")
            }
        }

        print("⏹ アラーム完全停止")
    }

    // MARK: - Private

    private func startVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            if self?.isPlaying == true {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }

    private func playSystemSoundLoop() {
        isPlaying = true
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if self?.isPlaying == true {
                AudioServicesPlayAlertSound(SystemSoundID(1005))
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            } else {
                timer.invalidate()
            }
        }
    }
}

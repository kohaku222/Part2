//
//  VolumeManager.swift
//  Part2
//
//  Created by Claude on 2025/01/04.
//

import Foundation
import MediaPlayer
import AVFoundation

/// メディア音量を強制的に制御するマネージャー
class VolumeManager {
    static let shared = VolumeManager()

    private var volumeView: MPVolumeView?
    private var previousVolume: Float = 0.5

    private init() {
        // 非表示のMPVolumeViewを作成（音量スライダーへのアクセス用）
        volumeView = MPVolumeView(frame: .zero)
        volumeView?.isHidden = true
    }

    /// 現在のメディア音量を取得
    var currentVolume: Float {
        return AVAudioSession.sharedInstance().outputVolume
    }

    /// メディア音量を設定（0.0〜1.0）
    func setVolume(_ volume: Float) {
        // 音量スライダーを取得して値を設定
        guard let volumeView = volumeView else { return }

        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                DispatchQueue.main.async {
                    slider.value = max(0, min(1, volume))
                    print("音量設定: \(volume)")
                }
                return
            }
        }

        // スライダーが見つからない場合のフォールバック
        print("音量スライダーが見つかりません")
    }

    /// 音量をMAXに設定
    func setMaxVolume() {
        previousVolume = currentVolume
        setVolume(1.0)
        print("音量をMAXに設定（元の音量: \(previousVolume)）")
    }

    /// 音量を元に戻す
    func restorePreviousVolume() {
        setVolume(previousVolume)
        print("音量を元に戻す: \(previousVolume)")
    }

    /// 音量監視を開始（ユーザーが音量を下げたら即座にMAXに戻す）
    private var volumeObserver: NSKeyValueObservation?
    private var isForceMaxEnabled = false

    func startForceMaxVolume() {
        isForceMaxEnabled = true
        previousVolume = currentVolume
        setVolume(1.0)

        // オーディオセッションのoutputVolumeを監視
        volumeObserver = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let self = self, self.isForceMaxEnabled else { return }

            if let newVolume = change.newValue, newVolume < 1.0 {
                // ユーザーが音量を下げたら即座にMAXに戻す
                print("音量変更検知: \(newVolume) → 強制的にMAXに戻す")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.setVolume(1.0)
                }
            }
        }

        print("強制音量MAX監視開始")
    }

    func stopForceMaxVolume(restoreVolume: Bool = true) {
        isForceMaxEnabled = false
        volumeObserver?.invalidate()
        volumeObserver = nil

        if restoreVolume {
            setVolume(previousVolume)
        }

        print("強制音量MAX監視停止")
    }
}

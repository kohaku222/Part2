//
//  AudioManager.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import Foundation
import AVFoundation

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()

    // 録音関連
    private var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var recordingURL: URL?

    // 再生関連
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false

    // 録音時間
    @Published var recordingTime: TimeInterval = 0
    private var recordingTimer: Timer?

    private override init() {
        super.init()
    }

    // MARK: - 録音ファイルのパス

    private func getRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "motivation_\(Date().timeIntervalSince1970).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }

    // MARK: - オーディオセッションの設定

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("オーディオセッション設定エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 録音開始

    func startRecording() {
        setupAudioSession()

        let url = getRecordingURL()
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            recordingTime = 0
            startRecordingTimer()
            print("録音開始: \(url)")
        } catch {
            print("録音開始エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 録音停止

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopRecordingTimer()
        print("録音停止")
    }

    // MARK: - 録音タイマー

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            self.recordingTime = recorder.currentTime
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - 再生開始

    func startPlaying(url: URL) {
        setupAudioSession()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            print("再生開始: \(url)")
        } catch {
            print("再生開始エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 再生停止

    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
        print("再生停止")
    }

    // MARK: - 録音ファイルの削除

    func deleteRecording(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("録音ファイル削除: \(url)")
        } catch {
            print("録音ファイル削除エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 録音時間のフォーマット

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("録音完了")
        } else {
            print("録音失敗")
            recordingURL = nil
        }
        isRecording = false
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("再生完了")
    }
}

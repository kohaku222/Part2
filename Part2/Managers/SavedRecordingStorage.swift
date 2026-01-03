//
//  SavedRecordingStorage.swift
//  Part2
//
//  Created by Claude on 2025/12/24.
//

import Foundation

class SavedRecordingStorage: ObservableObject {
    static let shared = SavedRecordingStorage()

    private let key = "savedRecordings"

    @Published var savedRecordings: [SavedRecording] = [] {
        didSet {
            saveRecordings()
        }
    }

    private init() {
        loadRecordings()
    }

    // MARK: - 保存

    private func saveRecordings() {
        do {
            let data = try JSONEncoder().encode(savedRecordings)
            UserDefaults.standard.set(data, forKey: key)
            print("録音を保存しました: \(savedRecordings.count)件")
        } catch {
            print("録音保存エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 読み込み

    private func loadRecordings() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("保存された録音がありません")
            return
        }

        do {
            savedRecordings = try JSONDecoder().decode([SavedRecording].self, from: data)
            print("録音を読み込みました: \(savedRecordings.count)件")
            // 存在しないファイルを削除
            cleanupMissingFiles()
        } catch {
            print("録音読み込みエラー: \(error.localizedDescription)")
        }
    }

    // MARK: - ファイルが存在しない録音を削除

    private func cleanupMissingFiles() {
        let validRecordings = savedRecordings.filter { $0.fileURL != nil }
        if validRecordings.count != savedRecordings.count {
            let removed = savedRecordings.count - validRecordings.count
            savedRecordings = validRecordings
            print("存在しないファイルの録音を\(removed)件削除しました")
        }
    }

    // MARK: - CRUD操作

    /// 録音を追加
    func addRecording(name: String, url: URL, duration: TimeInterval) -> SavedRecording {
        let fileName = url.lastPathComponent
        let newRecording = SavedRecording(
            name: name,
            fileName: fileName,
            duration: duration
        )
        savedRecordings.append(newRecording)
        print("録音を追加: \(name) (\(fileName))")
        return newRecording
    }

    /// 録音を更新（名前変更）
    func updateRecording(id: UUID, newName: String) {
        if let index = savedRecordings.firstIndex(where: { $0.id == id }) {
            savedRecordings[index].name = newName
            print("録音名を変更: \(newName)")
        }
    }

    /// 録音を削除（ファイルも削除）
    func deleteRecording(id: UUID) {
        if let index = savedRecordings.firstIndex(where: { $0.id == id }) {
            let recording = savedRecordings[index]
            // ファイルを削除
            if let url = recording.fileURL {
                do {
                    try FileManager.default.removeItem(at: url)
                    print("録音ファイル削除: \(url)")
                } catch {
                    print("録音ファイル削除エラー: \(error.localizedDescription)")
                }
            }
            savedRecordings.remove(at: index)
            print("録音を削除: \(recording.name)")
        }
    }

    /// IDで録音を取得
    func getRecording(by id: UUID) -> SavedRecording? {
        return savedRecordings.first { $0.id == id }
    }

    /// ファイル名で録音を検索
    func findRecording(by fileName: String) -> SavedRecording? {
        return savedRecordings.first { $0.fileName == fileName }
    }
}

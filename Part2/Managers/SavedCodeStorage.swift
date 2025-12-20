//
//  SavedCodeStorage.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import Foundation

class SavedCodeStorage: ObservableObject {
    static let shared = SavedCodeStorage()

    private let key = "savedCodes"

    @Published var savedCodes: [SavedCode] = [] {
        didSet {
            saveCodes()
        }
    }

    private init() {
        loadCodes()
    }

    // MARK: - 保存

    private func saveCodes() {
        do {
            let data = try JSONEncoder().encode(savedCodes)
            UserDefaults.standard.set(data, forKey: key)
            print("コードを保存しました: \(savedCodes.count)件")
        } catch {
            print("コード保存エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - 読み込み

    private func loadCodes() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("保存されたコードがありません")
            return
        }

        do {
            savedCodes = try JSONDecoder().decode([SavedCode].self, from: data)
            print("コードを読み込みました: \(savedCodes.count)件")
        } catch {
            print("コード読み込みエラー: \(error.localizedDescription)")
        }
    }

    // MARK: - CRUD操作

    /// コードを追加
    func addCode(name: String, code: String, codeType: String) -> SavedCode {
        let newCode = SavedCode(name: name, code: code, codeType: codeType)
        savedCodes.append(newCode)
        return newCode
    }

    /// コードを更新（名前変更）
    func updateCode(id: UUID, newName: String) {
        if let index = savedCodes.firstIndex(where: { $0.id == id }) {
            savedCodes[index].name = newName
        }
    }

    /// コードを削除
    func deleteCode(id: UUID) {
        savedCodes.removeAll { $0.id == id }
    }

    /// IDでコードを取得
    func getCode(by id: UUID) -> SavedCode? {
        return savedCodes.first { $0.id == id }
    }

    /// コード値でコードを検索
    func findCode(by codeValue: String) -> SavedCode? {
        return savedCodes.first { $0.code == codeValue }
    }
}

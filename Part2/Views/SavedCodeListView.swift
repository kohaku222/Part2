//
//  SavedCodeListView.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI

struct SavedCodeListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var codeStorage = SavedCodeStorage.shared

    var onSelect: (String) -> Void  // 選択時にコード値を返す

    @State private var showScanner = false
    @State private var showNameInput = false
    @State private var scannedCode: String = ""
    @State private var scannedCodeType: String = ""
    @State private var newCodeName: String = ""
    @State private var editingCode: SavedCode?
    @State private var showDeleteConfirm = false
    @State private var codeToDelete: SavedCode?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if codeStorage.savedCodes.isEmpty {
                    // 空の状態
                    emptyStateView
                } else {
                    // コード一覧
                    List {
                        ForEach(codeStorage.savedCodes) { savedCode in
                            SavedCodeRow(
                                savedCode: savedCode,
                                onSelect: {
                                    onSelect(savedCode.code)
                                    dismiss()
                                },
                                onEdit: {
                                    editingCode = savedCode
                                    newCodeName = savedCode.name
                                },
                                onDelete: {
                                    codeToDelete = savedCode
                                    showDeleteConfirm = true
                                }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("保存済みコード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showScanner = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                CodeScannerView(
                    isSetup: true,
                    registeredCode: nil
                ) { code, codeType in
                    scannedCode = code
                    scannedCodeType = codeType
                    showScanner = false
                    newCodeName = ""
                    showNameInput = true
                }
            }
            .alert("コードに名前を付ける", isPresented: $showNameInput) {
                TextField("例: 冷蔵庫のバーコード", text: $newCodeName)
                Button("保存") {
                    let name = newCodeName.isEmpty ? "コード \(codeStorage.savedCodes.count + 1)" : newCodeName
                    let savedCode = codeStorage.addCode(name: name, code: scannedCode, codeType: scannedCodeType)
                    // 保存後すぐに選択
                    onSelect(savedCode.code)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このコードを識別するための名前を入力してください")
            }
            .alert("名前を変更", isPresented: Binding(
                get: { editingCode != nil },
                set: { if !$0 { editingCode = nil } }
            )) {
                TextField("新しい名前", text: $newCodeName)
                Button("保存") {
                    if let code = editingCode {
                        codeStorage.updateCode(id: code.id, newName: newCodeName)
                    }
                    editingCode = nil
                }
                Button("キャンセル", role: .cancel) {
                    editingCode = nil
                }
            }
            .alert("削除の確認", isPresented: $showDeleteConfirm) {
                Button("削除", role: .destructive) {
                    if let code = codeToDelete {
                        codeStorage.deleteCode(id: code.id)
                    }
                    codeToDelete = nil
                }
                Button("キャンセル", role: .cancel) {
                    codeToDelete = nil
                }
            } message: {
                Text("「\(codeToDelete?.name ?? "")」を削除しますか？")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "qrcode")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("保存されたコードがありません")
                .font(.headline)

            Text("新しいQRコードやバーコードをスキャンして保存しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showScanner = true }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("スキャンして追加")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 10)

            Spacer()
        }
    }
}

// MARK: - コード行

struct SavedCodeRow: View {
    let savedCode: SavedCode
    var onSelect: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: savedCode.codeType.contains("QR") ? "qrcode" : "barcode")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }

            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(savedCode.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(savedCode.codeTypeDisplayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)

                    Text(savedCode.createdAtString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 操作ボタン
            Menu {
                Button(action: onSelect) {
                    Label("このコードを使用", systemImage: "checkmark.circle")
                }
                Button(action: onEdit) {
                    Label("名前を変更", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("削除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    SavedCodeListView { code in
        print("Selected: \(code)")
    }
}

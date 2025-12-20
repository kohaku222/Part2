//
//  SavedCode.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import Foundation

struct SavedCode: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String           // ユーザーが付ける名前（例: "冷蔵庫のバーコード"）
    var code: String           // スキャンしたコードの値
    var codeType: String       // QR, EAN13, Code128 など
    var createdAt: Date = Date()

    // コードタイプの表示名
    var codeTypeDisplayName: String {
        switch codeType {
        case "org.iso.QRCode":
            return "QRコード"
        case "org.gs1.EAN-13":
            return "EAN-13"
        case "org.gs1.EAN-8":
            return "EAN-8"
        case "org.iso.Code128":
            return "Code128"
        case "org.iso.Code39":
            return "Code39"
        case "org.iso.Code93":
            return "Code93"
        case "org.gs1.UPC-E":
            return "UPC-E"
        case "org.iso.PDF417":
            return "PDF417"
        case "org.iso.Aztec":
            return "Aztec"
        case "org.iso.DataMatrix":
            return "DataMatrix"
        default:
            return "バーコード"
        }
    }

    // 作成日時の表示用文字列
    var createdAtString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: createdAt)
    }
}

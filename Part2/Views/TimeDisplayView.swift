//
//  TimeDisplayView.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI

struct TimeDisplayView: View {
    @State private var currentTime = Date()
    var showSeconds: Bool = false
    var size: TimeDisplaySize = .large

    // 1秒ごとに時刻を更新するタイマー
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            Text(timeString)
                .font(.system(size: fontSize, weight: .light, design: .rounded))
                .monospacedDigit()

            if showSeconds {
                Text(":\(secondsString)")
                    .font(.system(size: fontSize, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    // 時:分 の文字列
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }

    // 秒の文字列
    private var secondsString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: currentTime)
    }

    // サイズに応じたフォントサイズ
    private var fontSize: CGFloat {
        switch size {
        case .small:
            return 32
        case .medium:
            return 48
        case .large:
            return 72
        case .extraLarge:
            return 96
        }
    }
}

enum TimeDisplaySize {
    case small
    case medium
    case large
    case extraLarge
}

#Preview {
    VStack(spacing: 40) {
        TimeDisplayView(size: .extraLarge)
        TimeDisplayView(showSeconds: true, size: .medium)
        TimeDisplayView(size: .small)
    }
    .padding()
}

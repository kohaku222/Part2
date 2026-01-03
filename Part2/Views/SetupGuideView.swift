//
//  SetupGuideView.swift
//  Part2
//
//  Created by Claude on 2025/01/04.
//

import SwiftUI

struct SetupGuideView: View {
    @Environment(\.dismiss) var dismiss
    var onComplete: () -> Void

    @State private var currentStep = 0

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Spacer()
                Button("スキップ") {
                    completeSetup()
                }
                .foregroundColor(.secondary)
            }
            .padding()

            // コンテンツ
            TabView(selection: $currentStep) {
                // ステップ1: ようこそ
                welcomeStep
                    .tag(0)

                // ステップ2: 集中モードの設定
                focusModeStep
                    .tag(1)

                // ステップ3: 完了
                completeStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // 次へボタン
            Button(action: nextStep) {
                Text(currentStep == 2 ? "はじめる" : "次へ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - ステップ1: ようこそ

    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "alarm.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("起きまshoへようこそ！")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("確実に起きるためのアラームアプリです。\nQRコードをスキャンしないと止められません！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - ステップ2: 集中モードの設定

    private var focusModeStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "moon.fill")
                .font(.system(size: 60))
                .foregroundColor(.indigo)

            Text("集中モードの設定")
                .font(.title)
                .fontWeight(.bold)

            Text("おやすみモードや集中モード中でも\nアラームが届くように設定してください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // 設定手順
            VStack(alignment: .leading, spacing: 16) {
                SetupStepRow(number: 1, text: "設定 → 集中モード を開く")
                SetupStepRow(number: 2, text: "使用中のモードを選択")
                SetupStepRow(number: 3, text: "「App」→「追加」→「起きまsho」を選択")
                SetupStepRow(number: 4, text: "または「即時通知を許可」をオン")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)

            // 設定を開くボタン
            Button(action: openSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("設定を開く")
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - ステップ3: 完了

    private var completeStep: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("準備完了！")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                FeatureRow(icon: "mic.fill", color: .blue, text: "自分の声でモチベーションUP")
                FeatureRow(icon: "qrcode", color: .orange, text: "QRスキャンで確実に起床")
                FeatureRow(icon: "bell.badge.fill", color: .red, text: "しつこい通知で二度寝防止")
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Actions

    private func nextStep() {
        if currentStep < 2 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeSetup()
        }
    }

    private func completeSetup() {
        UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
        onComplete()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 設定手順の行

struct SetupStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

// MARK: - 機能紹介の行

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)

            Text(text)
                .font(.body)

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    SetupGuideView {
        print("Setup completed")
    }
}

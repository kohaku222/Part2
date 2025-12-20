//
//  MotivationPlaybackView.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI
import AVFoundation

struct MotivationPlaybackView: View {
    let audioURL: URL
    var onComplete: () -> Void

    @StateObject private var audioManager = AudioManager.shared
    @State private var isPlaying = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.3),
                    Color.yellow.opacity(0.2),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // タイトル
                VStack(spacing: 12) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("おはようございます！")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("あなたからのメッセージです")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 再生コントロール
                VStack(spacing: 20) {
                    // 再生ボタン
                    Button(action: togglePlayback) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: .orange.opacity(0.5), radius: 20, x: 0, y: 10)

                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }

                    Text(audioManager.isPlaying ? "再生中..." : "タップして再生")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 完了ボタン
                Button(action: {
                    audioManager.stopPlaying()
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onComplete()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("今日も頑張ろう！")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }

            // 紙吹雪エフェクト
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            // 自動再生
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                audioManager.startPlaying(url: audioURL)
            }
        }
        .onDisappear {
            audioManager.stopPlaying()
        }
    }

    private func togglePlayback() {
        if audioManager.isPlaying {
            audioManager.stopPlaying()
        } else {
            audioManager.startPlaying(url: audioURL)
        }
    }
}

// MARK: - 紙吹雪エフェクト

struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ForEach(confetti) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(piece.position)
                    .opacity(piece.opacity)
            }
        }
        .onAppear {
            createConfetti()
        }
    }

    private func createConfetti() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

        for _ in 0..<50 {
            let piece = ConfettiPiece(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 5...15),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -50
                ),
                opacity: 1.0
            )
            confetti.append(piece)
        }

        // アニメーション
        for i in 0..<confetti.count {
            let delay = Double.random(in: 0...0.5)
            withAnimation(.easeIn(duration: 2).delay(delay)) {
                confetti[i].position.y = UIScreen.main.bounds.height + 50
                confetti[i].position.x += CGFloat.random(in: -100...100)
                confetti[i].opacity = 0
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var position: CGPoint
    var opacity: Double
}

#Preview {
    MotivationPlaybackView(audioURL: URL(string: "file://test")!) {
        print("Completed")
    }
}

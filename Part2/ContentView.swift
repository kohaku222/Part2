//
//  ContentView.swift
//  Part2
//
//  Created by 池田　聖 on 2025/12/20.
//

import SwiftUI

struct ContentView: View {
    @State private var alarm: Alarm?
    @State private var showSetAlarm = false

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                // 現在時刻
                VStack(spacing: 16) {
                    TimeDisplayView(size: .extraLarge)

                    Text(currentDateString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 40)

                // アラーム表示エリア
                ScrollView {
                    VStack(spacing: 20) {
                        if let alarm = alarm {
                            AlarmCardView(
                                alarm: alarm,
                                onToggle: toggleAlarm,
                                onDelete: deleteAlarm,
                                onRecordVoice: { /* TODO: 音声録音画面へ */ },
                                onSetupQR: { /* TODO: QR設定画面へ */ }
                            )
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
            }

            // 追加ボタン（アラームがない場合のみ表示）
            if alarm == nil {
                VStack {
                    Spacer()
                    addButton
                        .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showSetAlarm) {
            SetAlarmView(onSave: createAlarm)
        }
    }

    // MARK: - Views

    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .foregroundColor(.blue)
                Text("モチベーション目覚まし")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "sparkles")
                .foregroundColor(.orange)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("アラームがありません")
                .font(.headline)

            Text("下のボタンから新しいアラームを作成しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var addButton: some View {
        Button(action: { showSetAlarm = true }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)

                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Computed Properties

    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（EEEE）"
        return formatter.string(from: Date())
    }

    // MARK: - Actions

    private func createAlarm(time: Date) {
        alarm = Alarm(time: time)
        showSetAlarm = false
    }

    private func toggleAlarm() {
        alarm?.isEnabled.toggle()
    }

    private func deleteAlarm() {
        alarm = nil
    }
}

// MARK: - アラーム設定画面（仮）

struct SetAlarmView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTime = Date()
    var onSave: (Date) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("アラームを設定")
                    .font(.title2)
                    .fontWeight(.semibold)

                DatePicker(
                    "時刻",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button(action: {
                    onSave(selectedTime)
                }) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

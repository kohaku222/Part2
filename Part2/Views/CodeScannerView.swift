//
//  CodeScannerView.swift
//  Part2
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI
import AVFoundation

struct CodeScannerView: View {
    @Environment(\.dismiss) var dismiss

    var isSetup: Bool // true: 登録モード, false: 解除モード
    var registeredCode: String? // 登録済みのコード（解除モード時に使用）
    var onScan: (String, String) -> Void  // (code, codeType)

    @State private var scannedCode: String?
    @State private var scannedCodeType: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // カメラプレビュー（全画面）
            CameraPreviewView(scannedCode: $scannedCode, scannedCodeType: $scannedCodeType)
                .ignoresSafeArea()

            // オーバーレイ
            VStack {
                // キャンセルボタン
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // スキャンエリアのガイド（横長の長方形）
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 280, height: 180)
                    .background(Color.clear)

                Spacer()

                // 説明テキスト
                VStack(spacing: 12) {
                    Text("スキャンするバーコードまたはQRコードを\n四角に入るように合わせてください。")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    if let code = scannedCode {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("検出: \(code.prefix(20))...")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    }
                }
                .padding(.bottom, 40)

                // 確認ボタン（登録モード時）
                if isSetup, let code = scannedCode {
                    Button(action: {
                        onScan(code, scannedCodeType)
                        dismiss()
                    }) {
                        Text("このコードを登録")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            // 解除モードの場合、登録コードと一致したら自動で閉じる
            if !isSetup, let code = newValue, let registered = registeredCode {
                if code == registered {
                    onScan(code, scannedCodeType)
                    dismiss()
                }
            }
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - カメラプレビュー

struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var scannedCodeType: String

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraPreviewView

        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }

        func didScanCode(_ code: String, codeType: String) {
            DispatchQueue.main.async {
                self.parent.scannedCode = code
                self.parent.scannedCodeType = codeType
            }
        }
    }
}

// MARK: - カメラViewController

protocol CameraViewControllerDelegate: AnyObject {
    func didScanCode(_ code: String, codeType: String)
}

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: CameraViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video) else {
            print("カメラが利用できません")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                // QRコードとバーコードの両方をサポート
                output.metadataObjectTypes = [
                    .qr,           // QRコード
                    .ean13,        // JANコード（13桁）
                    .ean8,         // JANコード（8桁）
                    .code128,      // Code128
                    .code39,       // Code39
                    .code93,       // Code93
                    .upce,         // UPC-E
                    .pdf417,       // PDF417
                    .aztec,        // Aztec
                    .dataMatrix    // DataMatrix
                ]
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer

            captureSession = session

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }

        } catch {
            print("カメラ設定エラー: \(error.localizedDescription)")
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else {
            return
        }

        // バイブレーション
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        // コードタイプを取得（例: org.iso.QRCode, org.gs1.EAN-13 など）
        let codeType = metadataObject.type.rawValue

        delegate?.didScanCode(code, codeType: codeType)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

#Preview {
    CodeScannerView(isSetup: true, registeredCode: nil) { code, codeType in
        print("Scanned: \(code), Type: \(codeType)")
    }
}

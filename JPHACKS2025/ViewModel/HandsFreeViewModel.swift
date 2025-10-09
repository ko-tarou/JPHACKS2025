import SwiftUI // @Publishedを使うために必要
import Vision
import AVFoundation

/// スクロール要求を表現する構造体
struct ScrollRequest: Identifiable, Equatable { // Equatableを追加しました
    let id = UUID()
    let direction: ScrollDirection
}

enum ScrollDirection {
    case up, down
}

/// ウィンクの状態を管理するenum
private enum WinkState {
    case notWinking
    case winkStarted(eye: WinkedEye, timestamp: Date)
    
    enum WinkedEye {
        case left, right
    }
}

class HandsFreeViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties for View
    @Published var isHandsFreeModeOn = false
    @Published var isFaceDetected = false
    @Published var scrollRequest: ScrollRequest?

    // MARK: - Camera and Vision Properties
    let cameraService = CameraService()
    private let visionQueue = DispatchQueue(label: "vision.queue", qos: .userInitiated)

    // MARK: - Wink Detection State
    private var winkState: WinkState = .notWinking
    private var lastScrollTime: Date?
    
    // 修正1: overrideキーワードを追加
    override init() {
        super.init() // NSObjectのinitを呼び出す
        // CameraServiceからのフレーム更新を受け取るために自身をdelegateに設定
        cameraService.setDelegate(self)
    }

    func toggleHandsFreeMode() {
        // UIに関わるプロパティなのでメインスレッドで更新
        DispatchQueue.main.async {
            self.isHandsFreeModeOn.toggle()
            if self.isHandsFreeModeOn {
                self.cameraService.startSession()
            } else {
                self.cameraService.stopSession()
                self.isFaceDetected = false
            }
        }
    }
    
    private func processFrame(_ buffer: CMSampleBuffer) {
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            // 修正2: 最初にselfを安全にアンラップする
            guard let self = self else { return }
            
            guard let observations = request.results as? [VNFaceObservation], let observation = observations.first else {
                // 顔が検出されなかった場合
                DispatchQueue.main.async { self.isFaceDetected = false }
                self.resetWinkState()
                return
            }
            // 顔が検出された場合
            DispatchQueue.main.async { self.isFaceDetected = true }
            self.updateWinkState(with: observation)
        }
        
        // CVPixelBufferを使ってリクエストハンドラを実行
        let handler = VNImageRequestHandler(cmSampleBuffer: buffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
    
    private func updateWinkState(with observation: VNFaceObservation) {
        guard let landmarks = observation.landmarks else { return }
        
        let leftEyeOpenness = self.calculateEyeOpenness(for: landmarks.leftEye)
        let rightEyeOpenness = self.calculateEyeOpenness(for: landmarks.rightEye)
        let winkThreshold: CGFloat = 0.4

        var currentWink: WinkState.WinkedEye?
        if rightEyeOpenness / leftEyeOpenness < winkThreshold {
            currentWink = .right // 右目ウィンク（スクロール上）
        } else if leftEyeOpenness / rightEyeOpenness < winkThreshold {
            currentWink = .left // 左目ウィンク（スクロール下）
        }

        // --- ウィンク状態管理（State Machine）---
        switch winkState {
        case .notWinking:
            if let winkEye = currentWink {
                // ウィンクが開始された
                winkState = .winkStarted(eye: winkEye, timestamp: Date())
            }
            
        case .winkStarted(let eye, let timestamp):
            if currentWink == eye {
                // ウィンクが継続している
                let duration = Date().timeIntervalSince(timestamp)
                
                if let lastScroll = lastScrollTime {
                    // 2回目以降のスクロール
                    if Date().timeIntervalSince(lastScroll) >= 1.5 {
                        triggerScroll(for: eye)
                    }
                } else if duration >= 1.0 {
                    // 最初のスクロール
                    triggerScroll(for: eye)
                }
            } else {
                // ウィンクが終了した
                resetWinkState()
            }
        }
    }
    
    private func triggerScroll(for eye: WinkState.WinkedEye) {
        lastScrollTime = Date()
        let direction: ScrollDirection = (eye == .left) ? .down : .up
        
        // UIに関わるプロパティなのでメインスレッドで更新
        DispatchQueue.main.async {
            self.scrollRequest = ScrollRequest(direction: direction)
        }
    }
    
    private func resetWinkState() {
        winkState = .notWinking
        lastScrollTime = nil
    }
    
    private func calculateEyeOpenness(for eye: VNFaceLandmarkRegion2D?) -> CGFloat {
        // (以前の回答と同じロジック)
        guard let eye = eye else { return 0 }
        let points = eye.normalizedPoints
        guard points.count >= 4 else { return 0 }
        let topPoints = [points[1], points[2]]
        let bottomPoints = [points[5], points[4]]
        let avgTopY = topPoints.reduce(0) { $0 + $1.y } / CGFloat(topPoints.count)
        let avgBottomY = bottomPoints.reduce(0) { $0 + $1.y } / CGFloat(bottomPoints.count)
        return abs(avgTopY - avgBottomY)
    }
}

// ViewModelがカメラのフレームを受け取るための準拠
extension HandsFreeViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        visionQueue.async {
            self.processFrame(sampleBuffer)
        }
    }
}

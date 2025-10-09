import AVFoundation
import Vision
import VideoToolbox // kCVPixelFormatType_32BGRA を使うためにインポート

/// AVFoundationを管理し、カメラセッションをセットアップするクラス
class CameraService: NSObject {
    private let captureSession = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer
    private weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    private let captureQueue = DispatchQueue(label: "camera.queue")
    private var videoOutput: AVCaptureVideoDataOutput?

    override init() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init()
        setupSession()
    }
    
    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.delegate = delegate
        // セッション生成後でもデリゲートを安全に差し替える
        if let videoOutput = self.videoOutput {
            videoOutput.setSampleBufferDelegate(delegate, queue: captureQueue)
        }
    }

    private func setupSession() {
        captureSession.beginConfiguration()
        // 品質/レイテンシのバランス。顔ランドマークには十分
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            print("カメラのセットアップに失敗しました。")
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(videoDeviceInput)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        // 初期化時点では delegate は未設定の可能性があるため、保持のみしておく
        if let delegate = self.delegate {
            output.setSampleBufferDelegate(delegate, queue: captureQueue)
        }
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        self.videoOutput = output
        
        // 出力コネクションの基本設定（フロントカメラは鏡像に）
        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        
        previewLayer.videoGravity = .resizeAspect
        captureSession.commitConfiguration()
    }
    
    func startSession() {
        let start = {
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    #if DEBUG
                    print("[Camera] captureSession started")
                    #endif
                }
            }
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            start()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { start() }
                else { print("[Camera] カメラ権限が拒否されました") }
            }
        default:
            print("[Camera] カメラ権限がありません。設定から許可してください。")
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

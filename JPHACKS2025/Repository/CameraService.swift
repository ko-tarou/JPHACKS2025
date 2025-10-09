import AVFoundation
import Vision

/// AVFoundationを管理し、カメラセッションをセットアップするクラス
class CameraService: NSObject {
    private let captureSession = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer
    private weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    override init() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init()
        setupSession()
    }
    
    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.delegate = delegate
    }

    private func setupSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            print("カメラのセットアップに失敗しました。")
            return
        }
        captureSession.addInput(videoDeviceInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "camera.queue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        previewLayer.videoGravity = .resizeAspect
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
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


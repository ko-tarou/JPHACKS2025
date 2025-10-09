import SwiftUI
import AVFoundation

/// UIViewControllerRepresentableに準拠した、SwiftUIで使えるカメラView
struct CameraView: UIViewControllerRepresentable {
    var cameraService: CameraService

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CameraViewController()
        viewController.view.backgroundColor = .black
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let viewController = uiViewController as? CameraViewController else { return }
        viewController.addPreviewLayer(cameraService.previewLayer)
    }
}

/// UIKitのUIViewControllerを継承したクラス
private class CameraViewController: UIViewController {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    func addPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = layer
        view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        view.layer.addSublayer(layer)
    }
}

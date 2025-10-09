import SwiftUI
import AVFoundation

// UIViewControllerRepresentableに準拠した、SwiftUIで使えるカメラView
struct CameraView: UIViewControllerRepresentable {
    // 期待する型をHandsFreeViewModelからCameraServiceに変更
    var cameraService: CameraService

    // UIViewControllerを作成する
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CameraViewController()
        viewController.view.backgroundColor = .black
        return viewController
    }

    // UIViewControllerが更新されたときに呼ばれる
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // cameraServiceのpreviewLayerをviewControllerのviewのレイヤーとして設定
        guard let viewController = uiViewController as? CameraViewController else { return }
        viewController.addPreviewLayer(cameraService.previewLayer)
    }
}

// UIKitのUIViewControllerを継承したクラス
private class CameraViewController: UIViewController {
    var previewLayer: AVCaptureVideoPreviewLayer?

    // このViewのレイアウトが変更された「後」に呼ばれるメソッド
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // previewLayerのサイズを親Viewのサイズに合わせる
        previewLayer?.frame = view.bounds
    }
    
    // 渡されたpreviewLayerを自分のviewに追加するメソッド
    func addPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = layer
        
        // 既存のサブレイヤーを一旦削除
        view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // 新しいレイヤーを追加
        view.layer.addSublayer(layer)
    }
}

import Vision
import SwiftUI

@MainActor
class WinkDetectorViewModel: ObservableObject {
    
    // UIに表示するための状態プロパティ
    @Published var faceBoundingBox: CGRect?
    @Published var winkStatus: String = "画像を解析してください"
    
    /// 画像を受け取り、顔とウィンクを検出するメインの関数
    func detectWink(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            winkStatus = "画像の変換に失敗しました。"
            return
        }
        
        // 顔のランドマーク（目、鼻、口など）を検出するリクエストを作成
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            // エラーハンドリング
            if let error = error {
                self?.winkStatus = "ランドマークの検出に失敗: \(error.localizedDescription)"
                return
            }
            
            // 検出結果をVNFaceObservationの配列として取得
            guard let observations = request.results as? [VNFaceObservation], let observation = observations.first else {
                DispatchQueue.main.async {
                    self?.winkStatus = "顔が検出されませんでした。"
                }
                self?.faceBoundingBox = nil
                return
            }
            
            // 顔のバウンディングボックス（位置と大きさ）をUI用に変換して保存
            let imageSize = image.size
            self?.faceBoundingBox = self?.convertBoundingBox(observation.boundingBox, to: imageSize)
            
            // ウィンクの判定ロジックを実行
            self?.analyzeWink(from: observation)
        }
        
        // リクエストハンドラを作成して実行
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            self.winkStatus = "リクエストの実行に失敗: \(error.localizedDescription)"
        }
    }
    
    /// ランドマーク情報からウィンクを判定する
    private func analyzeWink(from observation: VNFaceObservation) {
        // 顔のランドマーク（特徴点）を取得
        guard let landmarks = observation.landmarks else { return }
        
        // 左右の目のランドマークから「目の開き具合」を計算
        let leftEyeOpenness = calculateEyeOpenness(for: landmarks.leftEye)
        let rightEyeOpenness = calculateEyeOpenness(for: landmarks.rightEye)
        
        // ウィンク判定のしきい値（この値は調整が必要な場合があります）
        let winkThreshold: CGFloat = 0.4
        
        // 判定ロジック
        if leftEyeOpenness / rightEyeOpenness < winkThreshold {
            winkStatus = "右目でウィンク 😉 (Left eye closed)"
        } else if rightEyeOpenness / leftEyeOpenness < winkThreshold {
            winkStatus = "左目でウィンク 😉 (Right eye closed)"
        } else {
            winkStatus = "両目は開いています 👀"
        }
    }
    
    /// 目のランドマークから「目の開き具合」を計算するヘルパー関数
    private func calculateEyeOpenness(for eye: VNFaceLandmarkRegion2D?) -> CGFloat {
        guard let eye = eye else { return 0 }
        
        // 目の中心線にある上下の点を取得
        let points = eye.normalizedPoints
        guard points.count >= 4 else { return 0 }
        
        let topPoints = [points[1], points[2]]
        let bottomPoints = [points[5], points[4]]
        
        let avgTopY = topPoints.reduce(0) { $0 + $1.y } / CGFloat(topPoints.count)
        let avgBottomY = bottomPoints.reduce(0) { $0 + $1.y } / CGFloat(bottomPoints.count)
        
        // 上下のまぶたの距離を返す
        return abs(avgTopY - avgBottomY)
    }

    /// Visionの座標系からUIKitの座標系に変換する
    private func convertBoundingBox(_ box: CGRect, to imageSize: CGSize) -> CGRect {
        return CGRect(
            x: box.origin.x * imageSize.width,
            y: (1 - box.origin.y - box.height) * imageSize.height,
            width: box.width * imageSize.width,
            height: box.height * imageSize.height
        )
    }
}

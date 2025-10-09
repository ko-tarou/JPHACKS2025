import SwiftUI
import Vision
import AVFoundation

/// メインのレシピ表示View
struct RecipeViewSample: View {
    @StateObject private var viewModel = HandsFreeViewModel()
    @State private var currentScrollID = 0
    private let itemCount = 20 // スクロールする項目数を増やしてテストしやすくする

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                // 背景のスクロールビュー
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("料理名").font(.largeTitle).fontWeight(.bold)
                        ForEach(0..<itemCount, id: \.self) { num in
                            VStack(alignment: .leading) {
                                Text("手順 \(num + 1)")
                                    .font(.headline)
                                    .padding(.top)
                                    .id(num) // スクロールするためのID
                                Text("ここに\(num + 1)番目のレシピの手順が入ります。\n材料を混ぜて、オーブンで焼きます。美味しい料理を作りましょう。")
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }

                // 前面の操作UI
                VStack {
                    HStack {
                        // カメラプレビュー
                        if viewModel.isHandsFreeModeOn {
                            CameraView(cameraService: viewModel.cameraService)
                                .frame(width: 100, height: 150)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.isFaceDetected ? Color.green : Color.red, lineWidth: 3)
                                )
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                    HandsFreeControlView(
                        isHandsFreeModeOn: $viewModel.isHandsFreeModeOn,
                        isFaceDetected: viewModel.isFaceDetected,
                        onToggle: {
                            viewModel.toggleHandsFreeMode()
                        }
                    )
                }
            }
            // ViewModelからのスクロール要求を監視
            .onChange(of: viewModel.scrollRequest) { _, newRequest in
                guard let request = newRequest else { return }
                
                var nextID = currentScrollID
                switch request.direction {
                case .up:
                    nextID = max(0, currentScrollID - 1)
                case .down:
                    nextID = min(itemCount - 1, currentScrollID + 1)
                }
                
                if nextID != currentScrollID {
                    currentScrollID = nextID
                    withAnimation {
                        proxy.scrollTo(currentScrollID, anchor: .top)
                    }
                }
            }
        }
    }
}

/// ハンズフリーモードの操作パネル
struct HandsFreeControlView: View {
    @Binding var isHandsFreeModeOn: Bool
    let isFaceDetected: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack {
            Text(isFaceDetected ? "顔を認識中👀" : "顔を認識できません")
                .font(.headline)
                .padding(8)
                .background(.thinMaterial)
                .cornerRadius(8)
                .opacity(isHandsFreeModeOn ? 1.0 : 0.0)
            
            Button(action: onToggle) {
                Text(isHandsFreeModeOn ? "ハンズフリーモード OFF" : "ハンズフリーモード ON")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isHandsFreeModeOn ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview{
    RecipeViewSample()
}

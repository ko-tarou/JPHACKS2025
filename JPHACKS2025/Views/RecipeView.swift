import SwiftUI

struct RecipeView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var showCommandAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // タイトル
            Text("音声文字起こし")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // 最後に検出したコマンド表示
            lastCommandView
            
            Spacer()
            
            // 文字起こしと履歴エリア
            transcriptArea
            
            // 下部のコントロールエリア
            controlsArea
            
            Spacer()
        }
        .padding(.bottom, 40)
    }
}

// MARK: - View Components (ビューの部品)
// このようにextensionでビューを分割すると、本体のコードがスッキリします
private extension RecipeView {
    
    /// 最後に検出したコマンドを表示するビュー
    @ViewBuilder
    var lastCommandView: some View {
        if let lastCommand = speechRecognizer.lastDetectedCommand {
            VStack(spacing: 10) {
                Text("検出中")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green))
                
                Text(lastCommand)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                    )
                    .scaleEffect(showCommandAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showCommandAnimation)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                showCommandAnimation = true
            }
        }
    }
    
    /// 文字起こしとコマンド履歴を表示するエリア
    var transcriptArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                if speechRecognizer.transcript.isEmpty {
                    Text("音声ボタンを押して話し始めてください")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("リアルタイム文字起こし")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(speechRecognizer.transcript)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
                
                if !speechRecognizer.detectedCommands.isEmpty {
                    commandHistoryList
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    /// コマンド履歴のリスト
    var commandHistoryList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.horizontal)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("確定したコマンド履歴")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(speechRecognizer.detectedCommands.count)件")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue))
            }
            .padding(.horizontal)
            
            ForEach(Array(speechRecognizer.detectedCommands.enumerated().reversed()), id: \.offset) { index, command in
                commandHistoryRow(index: index, command: command)
            }
        }
    }
    
    /// コマンド履歴の各行を生成するメソッド
    func commandHistoryRow(index: Int, command: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(speechRecognizer.detectedCommands.count - index)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue))
            
            Text(command)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    /// エラーメッセージ、インジケーター、ボタンを含むコントロールエリア
    var controlsArea: some View {
        VStack {
            // エラーメッセージ
            if let errorMessage = speechRecognizer.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // 録音中インジケーター
            if speechRecognizer.isRecording {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .opacity(0.8)
                    Text("録音中...")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 5)
            }
            
            // ボタンエリア
            HStack(spacing: 20) {
                // クリアボタン
                Button(action: {
                    speechRecognizer.clearTranscript()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.title2)
                        Text("クリア")
                            .font(.caption2)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(speechRecognizer.isRecording)
                
                // コマンドクリアボタン
                Button(action: {
                    speechRecognizer.clearCommands()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title2)
                        Text("コマンド")
                            .font(.caption2)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(speechRecognizer.isRecording || speechRecognizer.detectedCommands.isEmpty)
                
                // 音声入力ボタン
                Button(action: {
                    speechRecognizer.toggleRecording()
                }) {
                    Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(speechRecognizer.isRecording ? .red : .blue)
                }
                .padding(.vertical, 10)
            }
        }
    }
}


#Preview {
    RecipeView()
}

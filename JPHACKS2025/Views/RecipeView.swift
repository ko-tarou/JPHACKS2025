import SwiftUI

struct RecipeView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        VStack(spacing: 20) {
            // タイトル
            Text("音声文字起こし")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Spacer()
            
            // 文字起こし表示エリア
            ScrollView {
                VStack {
                    if speechRecognizer.transcript.isEmpty {
                        Text("音声ボタンを押して話し始めてください")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        Text(speechRecognizer.transcript)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                    Image(systemName: "trash")
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                }
                .disabled(speechRecognizer.isRecording)
                
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
            
            Spacer()
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    RecipeView()
}

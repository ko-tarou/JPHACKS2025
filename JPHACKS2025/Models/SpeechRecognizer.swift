import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    
    init() {
        requestPermission()
    }
    
    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("音声認識が許可されました")
                case .denied:
                    self.errorMessage = "音声認識が拒否されました"
                case .restricted:
                    self.errorMessage = "音声認識が制限されています"
                case .notDetermined:
                    self.errorMessage = "音声認識の許可が未定です"
                @unknown default:
                    self.errorMessage = "音声認識のステータスが不明です"
                }
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        // 既存のタスクがあればキャンセル
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // オーディオセッションの設定
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "オーディオセッションのセットアップに失敗しました: \(error.localizedDescription)"
            return
        }
        
        // オーディオエンジンの初期化
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            errorMessage = "オーディオエンジンの初期化に失敗しました"
            return
        }
        
        let inputNode = audioEngine.inputNode
        
        // 認識リクエストの作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "認識リクエストの作成に失敗しました"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 認識タスクの開始
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                Task { @MainActor in
                    self.errorMessage = "認識エラー: \(error.localizedDescription)"
                    self.stopRecording()
                }
            }
        }
        
        // オーディオ入力の設定
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // オーディオエンジンの開始
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = "オーディオエンジンの起動に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
    }
    
    func clearTranscript() {
        transcript = ""
    }
}

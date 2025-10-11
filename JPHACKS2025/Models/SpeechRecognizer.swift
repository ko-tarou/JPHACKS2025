import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var detectedCommands: [String] = []  // 抽出したコマンド文章
    @Published var lastDetectedCommand: String?  // 最後に検出したコマンド（ハイライト用）
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var timeoutCheckTask: Task<Void, Never>?  // タイムアウトチェック用タスク
    
    // トリガーワードのバリエーション（より広い判定）
    private let triggerWords = [
        "うぃんくん", "ウィンくん", "ウィン君", "うぃん君",
        "winくん", "win君", "ういんくん", "ウイン君", "Wink", "ウィンク",
        "ウインくん", "ういん君", "りんくん", "りん君", "林くん", "君", "ピンク"
    ]
    
    // コマンド検出の状態管理
    private var lastProcessedTriggerEndIndex: String.Index?  // 最後に処理したトリガーワードの終了位置
    private var currentTriggerWord: String?  // 現在処理中のトリガーワード
    private var currentCommandText: String?  // 現在検出中のコマンドテキスト
    private var processedCommandTexts: Set<String> = []  // 処理済みのコマンドテキスト（重複防止）
    
    // タイムアウト管理
    private var lastTranscriptUpdateTime: Date?  // 最後にtranscriptが更新された時刻
    private var currentTriggerPosition: (range: Range<String.Index>, triggerWord: String)?  // 現在処理中のトリガー位置
    private let commandTimeout: TimeInterval = 2.0  // コマンド確定までのタイムアウト時間（秒）
    
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
        
        // 新しい録音セッションの開始時に状態をリセット
        lastProcessedTriggerEndIndex = nil
        currentTriggerWord = nil
        currentCommandText = nil
        processedCommandTexts = []
        lastTranscriptUpdateTime = nil
        currentTriggerPosition = nil
        
        // タイムアウトチェックタスクを開始
        startTimeoutCheck()
        
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
                    self.detectAndExtractCommand()
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
        
        // タイムアウトチェックタスクを停止
        timeoutCheckTask?.cancel()
        timeoutCheckTask = nil
        
        // 録音停止時に状態をリセット
        lastProcessedTriggerEndIndex = nil
        currentTriggerWord = nil
        currentCommandText = nil
        processedCommandTexts = []
        lastTranscriptUpdateTime = nil
        currentTriggerPosition = nil
    }
    
    func clearTranscript() {
        transcript = ""
        lastProcessedTriggerEndIndex = nil
        currentTriggerWord = nil
        currentCommandText = nil
        processedCommandTexts = []
        lastTranscriptUpdateTime = nil
        currentTriggerPosition = nil
    }
    
    private func detectAndExtractCommand() {
        guard !transcript.isEmpty else { return }
        
        // transcriptが更新されたので時刻を記録
        lastTranscriptUpdateTime = Date()
        
        // 全てのトリガーワードの位置を検索
        var allTriggerPositions: [(range: Range<String.Index>, triggerWord: String)] = []
        
        for triggerWord in triggerWords {
            var searchStart = transcript.startIndex
            while searchStart < transcript.endIndex {
                if let range = transcript.range(
                    of: triggerWord,
                    options: [.caseInsensitive],
                    range: searchStart..<transcript.endIndex
                ) {
                    allTriggerPositions.append((range: range, triggerWord: triggerWord))
                    searchStart = range.upperBound
                } else {
                    break
                }
            }
        }
        
        // 位置でソート
        allTriggerPositions.sort { $0.range.lowerBound < $1.range.lowerBound }
        
        // 重複除去（近い位置は同一とみなす）
        var uniqueTriggers: [(range: Range<String.Index>, triggerWord: String)] = []
        for pos in allTriggerPositions {
            let isDuplicate = uniqueTriggers.contains { existing in
                abs(transcript.distance(from: existing.range.lowerBound, to: pos.range.lowerBound)) < 3
            }
            if !isDuplicate {
                uniqueTriggers.append(pos)
            }
        }
        
        // 処理開始位置を決定
        let startSearchIndex = lastProcessedTriggerEndIndex ?? transcript.startIndex
        
        // まだ処理していないトリガーワードを見つける
        guard let currentTrigger = uniqueTriggers.first(where: { 
            $0.range.lowerBound >= startSearchIndex 
        }) else {
            return
        }
        
        // 現在のトリガー位置を保存（タイムアウト時に使用）
        currentTriggerPosition = currentTrigger
        
        // トリガーワードの後のテキストを取得
        let afterTrigger = String(transcript[currentTrigger.range.upperBound...])
        let trimmed = afterTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            // トリガーワードの後に何もない場合は待機
            lastDetectedCommand = "..." 
            currentCommandText = nil
            return
        }
        
        // コマンドの終了位置を決定
        var commandEndIndex: String.Index?
        var shouldFinalize = false
        
        // 1. 次のトリガーワードを探す
        let nextTrigger = uniqueTriggers.first { trigger in
            trigger.range.lowerBound > currentTrigger.range.upperBound
        }
        
        if let next = nextTrigger {
            // 次のトリガーワードが見つかった場合、その直前まで
            commandEndIndex = next.range.lowerBound
            shouldFinalize = true
        } else {
            // 次のトリガーワードがない場合、句点などを探す
            let textToSearch = String(transcript[currentTrigger.range.upperBound...])
            
            if let range = textToSearch.range(of: "。") {
                commandEndIndex = transcript.index(currentTrigger.range.upperBound,
                    offsetBy: transcript.distance(from: textToSearch.startIndex, to: range.upperBound))
                shouldFinalize = true
            } else if let range = textToSearch.range(of: "！") {
                commandEndIndex = transcript.index(currentTrigger.range.upperBound,
                    offsetBy: transcript.distance(from: textToSearch.startIndex, to: range.upperBound))
                shouldFinalize = true
            } else if let range = textToSearch.range(of: "？") {
                commandEndIndex = transcript.index(currentTrigger.range.upperBound,
                    offsetBy: transcript.distance(from: textToSearch.startIndex, to: range.upperBound))
                shouldFinalize = true
            } else {
                // 句点もなく、次のトリガーもない場合は仮表示
                // ある程度の長さがあれば仮表示（2秒のタイムアウトで確定される）
                if trimmed.count >= 2 {
                    lastDetectedCommand = trimmed
                    currentCommandText = trimmed
                }
                return
            }
        }
        
        // コマンドを確定
        if let endIdx = commandEndIndex, shouldFinalize {
            var command = String(transcript[currentTrigger.range.upperBound..<endIdx])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "、,"))
            
            // 句点などを除去
            command = command.replacingOccurrences(of: "。", with: "")
            command = command.replacingOccurrences(of: "！", with: "")
            command = command.replacingOccurrences(of: "？", with: "")
            
            if !command.isEmpty && command.count >= 2 {
                // 重複チェック
                if !processedCommandTexts.contains(command) {
                    // ログに記録
                    detectedCommands.append(command)
                    lastDetectedCommand = command
                    processedCommandTexts.insert(command)
                    
                    print("━━━━━━━━━━━━━━━━━━━━━━")
                    print("✅ コマンド確定: \(command)")
                    print("   トリガー: \(currentTrigger.triggerWord)")
                    print("   コマンド番号: \(detectedCommands.count)")
                    print("━━━━━━━━━━━━━━━━━━━━━━")
                }
                
                // 次のトリガーワードを処理できるように位置を更新
                lastProcessedTriggerEndIndex = currentTrigger.range.upperBound
                
                // 確定したので状態をクリア
                currentCommandText = nil
                currentTriggerPosition = nil
            }
        }
    }
    
    func clearCommands() {
        detectedCommands = []
        lastDetectedCommand = nil
        lastProcessedTriggerEndIndex = nil
        currentTriggerWord = nil
        currentCommandText = nil
        processedCommandTexts = []
        lastTranscriptUpdateTime = nil
        currentTriggerPosition = nil
    }
    
    // MARK: - タイムアウト処理
    
    /// タイムアウトチェックを開始
    private func startTimeoutCheck() {
        timeoutCheckTask?.cancel()
        
        timeoutCheckTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒ごとにチェック
                
                guard !Task.isCancelled else { break }
                
                // タイムアウトをチェック
                if let lastUpdate = lastTranscriptUpdateTime,
                   let commandText = currentCommandText,
                   !commandText.isEmpty {
                    
                    let elapsed = Date().timeIntervalSince(lastUpdate)
                    
                    if elapsed >= commandTimeout {
                        // 2秒経過したのでコマンドを確定
                        finalizeCurrentCommand()
                    }
                }
            }
        }
    }
    
    /// 現在の仮表示コマンドを確定してログに記録
    private func finalizeCurrentCommand() {
        guard let commandText = currentCommandText,
              !commandText.isEmpty,
              commandText != "...",
              let triggerPos = currentTriggerPosition else {
            return
        }
        
        // トリミングと整形
        var command = commandText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "、,"))
        
        // 句点などを除去
        command = command.replacingOccurrences(of: "。", with: "")
        command = command.replacingOccurrences(of: "！", with: "")
        command = command.replacingOccurrences(of: "？", with: "")
        
        guard command.count >= 2 else { return }
        
        // 重複チェック
        if !processedCommandTexts.contains(command) {
            // ログに記録
            detectedCommands.append(command)
            lastDetectedCommand = command
            processedCommandTexts.insert(command)
            
            print("━━━━━━━━━━━━━━━━━━━━━━")
            print("⏱️ コマンド確定（タイムアウト）: \(command)")
            print("   トリガー: \(triggerPos.triggerWord)")
            print("   コマンド番号: \(detectedCommands.count)")
            print("━━━━━━━━━━━━━━━━━━━━━━")
            
            // 次のトリガーワードを処理できるように位置を更新
            lastProcessedTriggerEndIndex = triggerPos.range.upperBound
        }
        
        // 状態をクリア
        currentCommandText = nil
        currentTriggerPosition = nil
        lastTranscriptUpdateTime = nil
    }
}

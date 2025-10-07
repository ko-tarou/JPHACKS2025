import Observation

@Observable final class AIChatViewModel {
    private let ai = AIChatService()
    private let speaker = Speaker()
    let speech = SpeechRecognizer()

    var availability: AIAvailabilityState = .other("未判定")
    var messages: [Message] = []
    var isListening = false
    var isProcessing = false
    var errorMessage: String?

    func onAppear() {
        availability = ai.availability()
        Task { try? await speech.requestAuthorization() }
        if availability != .available {
            messages.append(.init(role: .system, text: availabilityLabel()))
        }
    }

    func toggleMic() {
        if isListening { stopListening() } else { startListening() }
    }

    private func startListening() {
        do {
            try speech.start()
            isListening = true
            errorMessage = nil
        } catch {
            errorMessage = "音声入力を開始できませんでした"
        }
    }

    private func stopListening() {
        speech.stop()
        isListening = false
        let text = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(.init(role: .user, text: text))
        Task { await askAI(text) }
    }

    @MainActor
    private func askAI(_ text: String) async {
        guard availability == .available else { return }
        isProcessing = true
        do {
            let answer = try await ai.reply(text)
            messages.append(.init(role: .assistant, text: answer))
            speaker.stop(); speaker.speak(answer)
        } catch {
            errorMessage = "AI応答でエラー: \(error.localizedDescription)"
        }
        isProcessing = false
    }

    private func availabilityLabel() -> String {
        switch availability {
        case .available: return "利用可能"
        case .deviceNotEligible: return "非対応端末です"
        case .notEnabled: return "設定で Apple Intelligence を有効化してください"
        case .modelNotReady: return "モデル準備中…"
        case .other(let s): return "利用不可: \(s)"
        }
    }
}

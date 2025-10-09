import Foundation
import Observation

@Observable
final class AIChatViewModel {
    // Services
    private let ai: AIChatService
    private let tts: TTSService = AVSpeechTTSService()

    // DI
    init(ai: AIChatService = AIChatService()) { self.ai = ai }

    // State
    var messages: [Message] = [
        .init(role: .assistant, text: "こんにちは。Apple Intelligence と最小構成で会話できます。")
    ]
    var input = ""
    var isSending = false
    var errorMessage: String?
    var availability: AIAvailabilityState = .simulator

    // Lifecycle
    func onAppear() { availability = ai.availability() }

    // Actions
    @MainActor
    func send() async {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        input = ""
        messages.append(.init(role: .user, text: t))
        isSending = true
        defer { isSending = false }

        do {
            let a = try await ai.reply(t)
            messages.append(.init(role: .assistant, text: a))
            tts.speak(a)               // 返答を即読み上げ
        } catch {
            errorMessage = "AI応答エラー: \(error.localizedDescription)"
        }
    }

    // TTS（UI からも使える最小 API）
    func speak(_ text: String) {      // ← 追加：任意テキストを読み上げ
        tts.speak(text)
    }
    func stopTTS() { tts.stop() }
    func speakLastAIMessage() {
        if let last = messages.last(where: { $0.role == .assistant }) {
            tts.speak(last.text)
        }
    }

    // View 用表示
    var availabilityText: String {
        switch availability {
        case .available: "利用可能"
        case .deviceNotEligible: "非対応端末"
        case .notEnabled: "設定で有効化して下さい"
        case .modelNotReady: "モデル準備中"
        case .simulator: "シミュレーター（不可）"
        case .other(let t): t
        }
    }
}

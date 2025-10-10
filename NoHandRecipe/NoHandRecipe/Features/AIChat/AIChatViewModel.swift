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
                // 後で実データに差し替える
                let ctx = SystemPrompt.CookingContext(
                    recipeTitle: "基本のペペロンチーノ",
                    currentStep: "手順3: ニンニクを弱火で香りが出るまで（目安2分）",
                    servings: 2
                )
                let prompt = """
                \(SystemPrompt.cookingAssistant)

                \(SystemPrompt.buildContext(ctx, user: t))
                """

                let a = try await ai.reply(prompt)
            messages.append(.init(role: .assistant, text: a))
                tts.speak(a)
            } catch {
                errorMessage = "AI応答エラー: \(error.localizedDescription)"
            }
        }

    func speak(_ text: String) {
        tts.speak(text)
    }
    func stopTTS() { tts.stop() }
    func speakLastAIMessage() {
        if let last = messages.last(where: { $0.role == .assistant }) {
            tts.speak(last.text)
        }
    }
//view用
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

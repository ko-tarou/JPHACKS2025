import Foundation
import Observation

@Observable final class AIChatViewModel {
    private let ai: AIChatService
    init(ai: AIChatService = AIChatService()) { self.ai = ai }  // ← DI

    var messages: [Message] = [.init(role: .assistant, text: "こんにちは。Apple Intelligence と最小構成で会話できます。")]
    var input = ""
    var isSending = false
    var errorMessage: String?
    var availability: AIAvailabilityState = .simulator

    func onAppear() { availability = ai.availability() }

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
        } catch { errorMessage = "AI応答エラー: \(error.localizedDescription)" }
    }

    // ← Viewの stateText をこちらに吸収
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

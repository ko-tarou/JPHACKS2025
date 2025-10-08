import Foundation
import Observation

@Observable final class AIChatViewModel {
    private let ai = AIChatService()

    var availability: AIAvailabilityState = .other("未判定")
    var messages: [Message] = [
        .init(role: .assistant, text: "こんにちは。Apple Intelligence と最小構成で会話できます。")
    ]
    var input: String = ""
    var isSending = false
    var errorMessage: String?

    func onAppear() {
        availability = ai.availability()
        if availability != .available {
            messages.append(.init(role: .system, text: availabilityLabel()))
        }
    }

    @MainActor
    func send() async {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        input = ""
        messages.append(.init(role: .user, text: t))
        isSending = true
        defer { isSending = false }
        do {
            let answer = try await ai.reply(t)
            messages.append(.init(role: .assistant, text: answer))
        } catch {
            errorMessage = "AI応答エラー: \(error.localizedDescription)"
        }
    }

    private func availabilityLabel() -> String {
        switch availability {
        case .available: "利用可能"
        case .deviceNotEligible: "非対応端末です"
        case .notEnabled: "設定で Apple Intelligence を有効化してください"
        case .modelNotReady: "モデル準備中…"
        case .simulator: "（シミュレーター）Apple Intelligence は利用できません"
        case .other(let s): "利用不可: \(s)"
        }
    }
}

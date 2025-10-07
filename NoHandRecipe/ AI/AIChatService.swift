import Foundation
import FoundationModels

final class AIChatService {
    private let model = SystemLanguageModel.default
    private let session = LanguageModelSession()
    private let systemPrompt =
      "You are a concise cooking assistant. Answer briefly and clearly in Japanese."

    func availability() -> AIAvailabilityState {
        AIAvailabilityChecker().check()
    }

    // 単発応答（ストリーミング不要の最小）
    func reply(_ userText: String) async throws -> String {
        let prompt = "System: \(systemPrompt)\nUser:\n\(userText)"
        return try await session.respond(to: prompt)
    }
}

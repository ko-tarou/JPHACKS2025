import Foundation
#if !targetEnvironment(simulator)
import FoundationModels
#endif

#if targetEnvironment(simulator)
final class AIChatService {
    func availability() -> AIAvailabilityState { AIAvailabilityChecker.check() }
    func reply(_ userText: String) async throws -> String {
        try? await Task.sleep(for: .seconds(1))   // ← これを追加
        return "（シミュレーター）Apple Intelligence は利用できません。実機で試してください。"
    }
}

#else
import FoundationModels

final class AIChatService {
    private let session = LanguageModelSession()
    private let systemPrompt =
      "You are a concise cooking assistant. Answer briefly and clearly in Japanese."

    func availability() -> AIAvailabilityState { AIAvailabilityChecker.check() }

    /// 単発応答（ストリーミング無し）
    func reply(_ userText: String) async throws -> String {
        let prompt = "System: \(systemPrompt)\nUser:\n\(userText)"
        // 戻り値は Response<String>。本文は `content` に入っている
        let res: LanguageModelSession.Response<String> = try await session.respond(to: prompt)
        return res.content              // ← ここがポイント
        // もし環境差で `content` が空/無い場合は次のフォールバックでもOK:
        // return (res.content.isEmpty ? (res.rawContent) : res.content)
    }
}
#endif

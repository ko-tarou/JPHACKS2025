import Foundation

enum AIAvailabilityState: Equatable {
    case available, deviceNotEligible, notEnabled, modelNotReady, simulator, other(String)
}

#if targetEnvironment(simulator)
// シミュレーターは常に不可
struct AIAvailabilityChecker { static func check() -> AIAvailabilityState { .simulator } }
#else
import FoundationModels

struct AIAvailabilityChecker {
    static func check() -> AIAvailabilityState {
        switch SystemLanguageModel.default.availability {
        case .available: return .available
        case .unavailable(.deviceNotEligible): return .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled): return .notEnabled
        case .unavailable(.modelNotReady): return .modelNotReady
        case .unavailable(let reason): return .other("\(reason)")
        }
    }
}
#endif

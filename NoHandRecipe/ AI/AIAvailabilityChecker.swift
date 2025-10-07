import Foundation
import FoundationModels

enum AIAvailabilityState: Equatable {
    case available, deviceNotEligible, notEnabled, modelNotReady, other(String)
}
struct AIAvailabilityChecker {
    func check() -> AIAvailabilityState {
        switch SystemLanguageModel.default.availability {
        case .available: return .available
        case .unavailable(.deviceNotEligible): return .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled): return .notEnabled
        case .unavailable(.modelNotReady): return .modelNotReady
        case .unavailable(let reason): return .other("\(reason)")
        }
    }
}

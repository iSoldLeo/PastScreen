import SwiftUI

enum OnboardingCoordinator {
    static func showIfNeeded() {
        NSLog("🔍 [ONBOARDING] showIfNeeded called, hasSeenOnboarding = \(OnboardingState.shared.hasSeenOnboarding)")
        guard !OnboardingState.shared.hasSeenOnboarding else {
            NSLog("ℹ️ [ONBOARDING] Already seen, skipping")
            return
        }
        show()
    }

    static func show() {
        DispatchQueue.main.async {
            WindowRouter.shared.open("onboarding")
        }
    }

    static func dismiss(markSeen: Bool = true) {
        if markSeen {
            OnboardingState.shared.hasSeenOnboarding = true
        }
        DispatchQueue.main.async {
            WindowRouter.shared.dismiss("onboarding")
        }
    }
}

@MainActor
final class OnboardingState {
    static let shared = OnboardingState()
    private let key = "hasSeenOnboarding"

    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

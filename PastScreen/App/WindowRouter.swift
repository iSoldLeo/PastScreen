import SwiftUI
import Combine

// Shared window routing between SwiftUI windows and App-level actions
@MainActor
final class WindowRouter: @MainActor ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    static let shared = WindowRouter()
    private var openAction: OpenWindowAction?
    private var dismissAction: DismissWindowAction?
    private var pendingOpens: [String] = []
    private var pendingDismissals: [String] = []

    func register(open: OpenWindowAction, dismiss: DismissWindowAction) {
        openAction = open
        dismissAction = dismiss
        flushPending()
    }

    func open(_ id: String) {
        guard let openAction else {
            NSLog("⚠️ [WINDOW] openAction not registered for id=\(id)")
            pendingOpens.append(id)
            return
        }
        openAction(id: id)
    }

    func dismiss(_ id: String) {
        guard let dismissAction else {
            NSLog("⚠️ [WINDOW] dismissAction not registered for id=\(id)")
            pendingDismissals.append(id)
            return
        }
        dismissAction(id: id)
    }

    private func flushPending() {
        let opens = pendingOpens
        pendingOpens.removeAll()
        opens.forEach { openAction?(id: $0) }

        let dismissals = pendingDismissals
        pendingDismissals.removeAll()
        dismissals.forEach { dismissAction?(id: $0) }
    }
}

struct WindowActionRegistrar: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var windowRouter: WindowRouter

    var body: some View {
        Color.clear
            .onAppear {
                windowRouter.register(open: openWindow, dismiss: dismissWindow)
            }
    }
}

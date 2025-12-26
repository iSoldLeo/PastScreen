//
//  DynamicIslandView.swift
//  PastScreen
//
//  Lightweight toast window powered by SwiftUI (replaces ad-hoc NSStatusItem)
//

import SwiftUI
import Combine

@MainActor
final class DynamicIslandManager: ObservableObject {
    static let shared = DynamicIslandManager()

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let style: Style
        let duration: TimeInterval
    }

    enum Style {
        case success
        case failure
    }

    @Published private(set) var toast: Toast?
    private var dismissTask: Task<Void, Never>?

    func show(message: String, duration: TimeInterval = 3.0, style: Style = .success) {
        dismissTask?.cancel()
        toast = Toast(message: message, style: style, duration: duration)
        WindowRouter.shared.open("toast")

        dismissTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.toast = nil
            WindowRouter.shared.dismiss("toast")
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        toast = nil
        WindowRouter.shared.dismiss("toast")
    }
}

struct DynamicIslandToastWindow: View {
    @EnvironmentObject private var manager: DynamicIslandManager
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Group {
            if let toast = manager.toast {
                toastContent(toast)
            } else {
                Color.clear
                    .frame(width: 1, height: 1)
                    .onAppear {
                        WindowRouter.shared.dismiss("toast")
                    }
            }
        }
        .padding(10)
        .onChange(of: manager.toast) { _, newValue in
            if newValue == nil {
                WindowRouter.shared.dismiss("toast")
            }
        }
    }

    @ViewBuilder
    private func toastContent(_ toast: DynamicIslandManager.Toast) -> some View {
        HStack(spacing: 10) {
            Image(systemName: toast.style == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(toast.style == .success ? .green : .red)
                .imageScale(.large)

            Text(toast.message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(reduceTransparency ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor)) : AnyShapeStyle(.regularMaterial))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(reduceTransparency ? 0.06 : 0.14), lineWidth: 1)
        }
        .shadow(radius: 14, y: 6)
    }
}

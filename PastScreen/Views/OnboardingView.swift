//
//  OnboardingView.swift
//  PastScreen
//
//  Multi-page onboarding with liquid glass design and permission requests
//

import SwiftUI
import AppKit
import ScreenCaptureKit
import UniformTypeIdentifiers

// MARK: - OnboardingPage

enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case screenRecording = 1
    case accessibility = 2
    case autoCleanup = 3
    case appRules = 4
    case clipboard = 5

    var title: String {
        switch self {
        case .welcome: return NSLocalizedString("onboarding.page1.title", comment: "")
        case .screenRecording: return NSLocalizedString("onboarding.permissions.screen_recording.title", comment: "")
        case .accessibility: return NSLocalizedString("onboarding.permissions.accessibility.title", comment: "")
        case .autoCleanup: return NSLocalizedString("onboarding.page2.title", comment: "")
        case .appRules: return NSLocalizedString("onboarding.page_apps.title", comment: "")
        case .clipboard: return NSLocalizedString("onboarding.page3.title", comment: "")
        }
    }

    var description: String {
        switch self {
        case .welcome: return NSLocalizedString("onboarding.page1.description", comment: "")
        case .screenRecording: return NSLocalizedString("onboarding.permissions.screen_recording.description", comment: "")
        case .accessibility: return NSLocalizedString("onboarding.permissions.accessibility.description", comment: "")
        case .autoCleanup: return NSLocalizedString("onboarding.page2.description", comment: "")
        case .appRules: return NSLocalizedString("onboarding.page_apps.description", comment: "")
        case .clipboard: return NSLocalizedString("onboarding.page3.description", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "bolt.fill"
        case .screenRecording: return "video.fill"
        case .accessibility: return "keyboard.fill"
        case .autoCleanup: return "sparkles"
        case .appRules: return "macwindow"
        case .clipboard: return "doc.on.clipboard.fill"
        }
    }

    var color: Color {
        switch self {
        case .welcome: return .yellow
        case .screenRecording: return .red
        case .accessibility: return .blue
        case .autoCleanup: return .purple
        case .appRules: return .green
        case .clipboard: return .cyan
        }
    }
}

// MARK: - OnboardingContentView

struct OnboardingContentView: View {
    let onDismiss: () -> Void
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var permissionManager: PermissionManager
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var currentPage: OnboardingPage = .welcome
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    @State private var screenRecordingGranted = false
    @State private var accessibilityGranted = false
    @State private var isMovingForward = true
    @State private var screenRecordingPollTask: Task<Void, Never>?
    @State private var accessibilityPollTask: Task<Void, Never>?
    @State private var showingFolderPicker = false

    var body: some View {
        ZStack {
            Group {
                if reduceTransparency {
                    Color(nsColor: .windowBackgroundColor)
                        .ignoresSafeArea()
                } else {
                    // Background blur effect
                    BlurOverlay(material: .hudWindow, blendingMode: .behindWindow)
                        .ignoresSafeArea()
                }
            }

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)

                    Text("PastScreen-CN")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(NSLocalizedString("onboarding.subtitle", comment: ""))
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 72)
                .padding(.bottom, currentPage == .autoCleanup ? 10 : 40)

                // Page content
                pageContent
                    .frame(height: currentPage == .autoCleanup ? 360 : 270)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(OnboardingPage.allCases, id: \.self) { page in
                        Circle()
                            .fill(
                                reduceTransparency
                                    ? AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
                                    : AnyShapeStyle(.thinMaterial)
                            )
                            .overlay {
                                Circle()
                                    .fill(currentPage.color)
                                    .opacity(currentPage == page ? 0.85 : 0)
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        reduceTransparency
                                            ? AnyShapeStyle(Color(nsColor: .separatorColor).opacity(0.8))
                                            : AnyShapeStyle(Color.white.opacity(0.14)),
                                        lineWidth: 1
                                    )
                            }
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 48)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage != .welcome {
                        Button(NSLocalizedString("onboarding.button.previous", comment: ""), action: previousPage)
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                    }

                    Button(buttonTitle, action: nextPage)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(!canContinue)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 620, height: 800)
        .glassContainer(material: .ultraThinMaterial, cornerRadius: 20, borderOpacity: 0.18, shadowOpacity: 0.18)
        .tint(currentPage.color)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            refreshPermissionState()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissionState()
        }
        .onDisappear {
            screenRecordingPollTask?.cancel()
            accessibilityPollTask?.cancel()
        }
        .fileImporter(isPresented: $showingFolderPicker, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url):
                settings.applyFolderSelection(from: url)
            case .failure:
                DynamicIslandManager.shared.show(
                    message: NSLocalizedString("settings.storage.select_folder_failed", value: "选择文件夹失败", comment: ""),
                    duration: 2.0,
                    style: .failure
                )
            }
        }
        .alert(item: $permissionManager.pendingAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                primaryButton: .default(Text(alert.primaryTitle), action: alert.primaryAction),
                secondaryButton: .cancel(Text(alert.secondaryTitle), action: alert.secondaryAction)
            )
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        reduceTransparency
                            ? AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
                            : AnyShapeStyle(.thinMaterial)
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(
                                reduceTransparency
                                    ? AnyShapeStyle(Color(nsColor: .separatorColor).opacity(0.8))
                                    : AnyShapeStyle(Color.white.opacity(0.14)),
                                lineWidth: 1
                            )
                    }
                    .frame(width: 90, height: 90)

                Image(systemName: currentPage.icon)
                    .font(.system(size: 44))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
            }
            .padding(.top, 12)
            .padding(.bottom, 18)

            // Title
            Text(currentPage.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Description
            Text(currentPage.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 30)
                .padding(.bottom, 12)

            // Permission buttons for permission pages
            if currentPage == .screenRecording {
                permissionButton(
                    title: NSLocalizedString("onboarding.permissions.grant", comment: ""),
                    granted: screenRecordingGranted,
                    action: requestScreenRecordingPermission
                )
                .padding(.top, 24)
            } else if currentPage == .accessibility {
                permissionButton(
                    title: NSLocalizedString("onboarding.permissions.grant", comment: ""),
                    granted: accessibilityGranted,
                    action: requestAccessibilityPermission
                )
                .padding(.top, 24)
            } else if currentPage == .autoCleanup {
                VStack(spacing: 16) {
                    // ONLY user-selected folder option (Apple guideline 2.4.5(i) compliance)
                    storageOption(
                        title: NSLocalizedString("onboarding.storage.default.title", comment: ""),
                        description: "选择一个在 Finder 可访问的文件夹。\n你的截图将保存在这里。",
                        icon: "folder.circle.fill",
                        color: .blue,
                        isSelected: settings.hasValidBookmark,
                        action: {
                            showingFolderPicker = true
                        }
                    )

                    // Show selected folder path
                    if settings.hasValidBookmark {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(settings.saveFolderPath)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.asymmetric(
            insertion: isMovingForward
                ? .move(edge: .trailing).combined(with: .opacity)
                : .move(edge: .leading).combined(with: .opacity),
            removal: isMovingForward
                ? .move(edge: .leading).combined(with: .opacity)
                : .move(edge: .trailing).combined(with: .opacity)
        ))
        .id(currentPage)
    }

    private func storageOption(title: String, description: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.tint)
                }
            }
            .padding(12)
        }
        .buttonStyle(.plain)
        .tint(color)
        .glassContainer(material: isSelected ? .regularMaterial : .thinMaterial, cornerRadius: 12, borderOpacity: isSelected ? 0.22 : 0.14, shadowOpacity: 0.10)
    }

    private func permissionButton(title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Group {
            if granted {
                Button {
                    action()
                } label: {
                    Label(NSLocalizedString("onboarding.permissions.granted", comment: ""), systemImage: "checkmark.circle.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .disabled(true)
            } else {
                Button(title) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .tint(currentPage.color)
            }
        }
        .controlSize(.large)
    }

    private var buttonTitle: String {
        if currentPage == .clipboard {
            return NSLocalizedString("onboarding.button.start", comment: "")
        } else {
            return NSLocalizedString("onboarding.button.next", comment: "")
        }
    }

    /// Check if user can continue to next page (requires folder selection)
    private var canContinue: Bool {
        // Block progress on storage page until folder is selected
        if currentPage == .autoCleanup {
            return settings.hasValidBookmark
        }
        return true
    }

    private func nextPage() {
        if currentPage == .clipboard {
            onDismiss()
        } else {
            isMovingForward = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if let nextIndex = OnboardingPage(rawValue: currentPage.rawValue + 1) {
                    currentPage = nextIndex
                }
            }
        }
    }

    private func previousPage() {
        isMovingForward = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let prevIndex = OnboardingPage(rawValue: currentPage.rawValue - 1) {
                currentPage = prevIndex
            }
        }
    }

    private func refreshPermissionState() {
        permissionManager.checkAccessibilityPermission()
        permissionManager.checkScreenRecordingPermission()

        accessibilityGranted = permissionManager.accessibilityStatus == .authorized
        screenRecordingGranted = permissionManager.screenRecordingStatus == .authorized
    }

    private func requestScreenRecordingPermission() {
        // Trigger native macOS Screen Recording popup
        permissionManager.requestPermission(.screenRecording) { granted in
            if !granted {
                // Fallback: open system settings if popup doesn't appear or user denied
                DispatchQueue.main.async {
                    self.openSystemPreferences(pane: "ScreenCapture")
                }
            }
        }
        startScreenRecordingPoll()
    }

    private func requestAccessibilityPermission() {
        // Trigger native macOS Accessibility popup
        permissionManager.requestPermission(.accessibility) { granted in
            if !granted {
                // Fallback: open system settings if popup doesn't appear or user denied
                DispatchQueue.main.async {
                    self.openSystemPreferences(pane: "Accessibility")
                }
            }
        }
        startAccessibilityPoll()
    }

    private func openSystemPreferences(pane: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startScreenRecordingPoll() {
        screenRecordingPollTask?.cancel()
        screenRecordingPollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)

                if #available(macOS 14.0, *) {
                    do {
                        let content = try await SCShareableContent.current
                        if !content.displays.isEmpty {
                            screenRecordingGranted = true
                            permissionManager.checkScreenRecordingPermission()
                            break
                        }
                    } catch {
                        // Keep waiting
                    }
                } else if CGPreflightScreenCaptureAccess() {
                    screenRecordingGranted = true
                    permissionManager.checkScreenRecordingPermission()
                    break
                }
            }
        }
    }

    private func startAccessibilityPoll() {
        accessibilityPollTask?.cancel()
        accessibilityPollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)

                if AXIsProcessTrusted() {
                    accessibilityGranted = true
                    permissionManager.checkAccessibilityPermission()
                    break
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingContentView(onDismiss: {})
        .frame(width: 620, height: 560)
        .environmentObject(AppSettings.shared)
}

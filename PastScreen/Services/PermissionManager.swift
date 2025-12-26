//
//  PermissionManager.swift
//  PastScreen
//
//  Comprehensive permission management with retry logic and diagnostics
//

import Foundation
import AppKit
import UserNotifications
import Combine
import SwiftUI

struct PermissionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
}

enum PermissionType: CaseIterable {
    case screenRecording
    case accessibility
    case notifications

    var icon: String {
        switch self {
        case .screenRecording: return "📱"
        case .accessibility: return "♿️"
        case .notifications: return "🔔"
        }
    }

    var localizedName: String {
        switch self {
        case .screenRecording:
            return NSLocalizedString("permission.type.screen_recording", value: "屏幕录制", comment: "")
        case .accessibility:
            return NSLocalizedString("permission.type.accessibility", value: "辅助功能", comment: "")
        case .notifications:
            return NSLocalizedString("permission.type.notifications", value: "通知", comment: "")
        }
    }
}

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted

    var description: String {
        switch self {
        case .authorized: return "✅ Authorized"
        case .denied: return "❌ Denied"
        case .notDetermined: return "⏳ Not Determined"
        case .restricted: return "🚫 Restricted"
        }
    }
}

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var screenRecordingStatus: PermissionStatus = .notDetermined
    @Published var accessibilityStatus: PermissionStatus = .notDetermined
    @Published var notificationStatus: PermissionStatus = .notDetermined
    @Published var pendingAlert: PermissionAlert?

    private var retryCount: [PermissionType: Int] = [:]
    private let maxRetries = 3

    // MARK: - Permission Status Checking

    func checkAllPermissions() {
        checkScreenRecordingPermission()
        checkAccessibilityPermission()
        checkNotificationPermission()
    }

    func checkScreenRecordingPermission() {
        if #available(macOS 10.15, *) {
            let hasAccess = CGPreflightScreenCaptureAccess()
            screenRecordingStatus = hasAccess ? .authorized : .denied
        }
    }

    func checkAccessibilityPermission() {
        let hasAccess = AXIsProcessTrusted()
        accessibilityStatus = hasAccess ? .authorized : .denied
    }

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.notificationStatus = .authorized
                case .denied:
                    self.notificationStatus = .denied
                case .notDetermined:
                    self.notificationStatus = .notDetermined
                @unknown default:
                    self.notificationStatus = .restricted
                }
            }
        }
    }

    // MARK: - Permission Requests with Retry

    func requestPermission(_ type: PermissionType, completion: @escaping (Bool) -> Void) {
        let currentRetry = retryCount[type] ?? 0

        if currentRetry >= maxRetries {
            showMaxRetriesAlert(for: type)
            completion(false)
            return
        }

        retryCount[type] = currentRetry + 1

        switch type {
        case .screenRecording:
            requestScreenRecording(completion: completion)
        case .accessibility:
            requestAccessibility(completion: completion)
        case .notifications:
            requestNotifications(completion: completion)
        }
    }

    private func requestScreenRecording(completion: @escaping (Bool) -> Void) {
        if #available(macOS 10.15, *) {
            let wasAuthorized = CGPreflightScreenCaptureAccess()
            if !wasAuthorized {
                CGRequestScreenCaptureAccess()

                // Check again after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.checkScreenRecordingPermission()
                    completion(self.screenRecordingStatus == .authorized)
                }
            } else {
                completion(true)
            }
        }
    }

    private func requestAccessibility(completion: @escaping (Bool) -> Void) {
        let wasAuthorized = AXIsProcessTrusted()
        if !wasAuthorized {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

            // Check again after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkAccessibilityPermission()
                completion(self.accessibilityStatus == .authorized)
            }
        } else {
            completion(true)
        }
    }

    private func requestNotifications(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.checkNotificationPermission()
                completion(granted)
            }
        }
    }

    // MARK: - User Feedback

    func allPermissionsGranted() -> Bool {
        return screenRecordingStatus == .authorized &&
               accessibilityStatus == .authorized &&
               notificationStatus == .authorized
    }

    func getMissingPermissions() -> [PermissionType] {
        var missing: [PermissionType] = []

        if screenRecordingStatus != .authorized {
            missing.append(.screenRecording)
        }
        if accessibilityStatus != .authorized {
            missing.append(.accessibility)
        }
        if notificationStatus != .authorized {
            missing.append(.notifications)
        }

        return missing
    }

    func showPermissionAlert(for permissions: [PermissionType]) {
        let header = NSLocalizedString("permission.request.header", value: "PastScreen-CN 需要以下权限才能正常工作：", comment: "")
        let footer = NSLocalizedString("permission.request.footer", value: "请在“系统设置 → 隐私与安全性”中开启。", comment: "")
        let permissionsList = permissions.map { "\($0.icon) \($0.localizedName)" }.joined(separator: "\n")
        let composedMessage = "\(header)\n\n\(permissionsList)\n\n\(footer)"

        pendingAlert = PermissionAlert(
            title: NSLocalizedString("error.permission_denied", value: "需要权限", comment: ""),
            message: composedMessage,
            primaryTitle: NSLocalizedString("error.open_system_prefs", value: "打开系统设置", comment: ""),
            secondaryTitle: NSLocalizedString("error.later", value: "稍后", comment: ""),
            primaryAction: { [weak self] in
                self?.pendingAlert = nil
                self?.openSystemPreferences()
            },
            secondaryAction: { [weak self] in
                self?.pendingAlert = nil
            }
        )

        // Fallback UI path when no SwiftUI alert is currently presented (e.g., triggered from AppDelegate)
        DynamicIslandManager.shared.show(
            message: composedMessage,
            duration: 3.5,
            style: .failure
        )
    }

    private func showMaxRetriesAlert(for type: PermissionType) {
        let message = NSLocalizedString("permission.max_retries.message", value: "PastScreen-CN 已达到权限请求次数上限。\n\n请手动开启", comment: "")

        let info = """
        \(message) \(type.localizedName):
        系统设置 → 隐私与安全性 → \(type.localizedName)
        """

        pendingAlert = PermissionAlert(
            title: "\(type.icon) \(type.localizedName) " + NSLocalizedString("error.permission_denied", value: "需要权限", comment: ""),
            message: info,
            primaryTitle: NSLocalizedString("error.open_system_prefs", value: "打开系统设置", comment: ""),
            secondaryTitle: NSLocalizedString("common.ok", comment: ""),
            primaryAction: { [weak self] in
                self?.pendingAlert = nil
                self?.openSystemPreferences()
            },
            secondaryAction: { [weak self] in
                self?.pendingAlert = nil
            }
        )

        DynamicIslandManager.shared.show(
            message: info,
            duration: 3.5,
            style: .failure
        )
    }

    func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Reset

    func resetRetryCounters() {
        retryCount.removeAll()
    }

    // MARK: - Convenience Methods

    func requestAccessibilityPermission(completion: @escaping (Bool) -> Void) {
        requestPermission(.accessibility, completion: completion)
    }

    func requestScreenRecordingPermission(completion: @escaping (Bool) -> Void) {
        requestPermission(.screenRecording, completion: completion)
    }

    var hasAllPermissions: Bool {
        return screenRecordingStatus == .authorized && accessibilityStatus == .authorized
    }
}

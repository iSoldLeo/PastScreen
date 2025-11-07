//
//  WindowCaptureService.swift
//  ScreenSnap
//
//  Window capture service with live thumbnail previews
//  Uses ScreenCaptureKit and ThumbnailStreamManager for real-time video
//

import Foundation
import AppKit
import ScreenCaptureKit
import SwiftUI
import UserNotifications

@available(macOS 12.3, *)
class WindowCaptureService: NSObject {
    private var availableWindows: [SCWindow] = []
    var selectorWindow: NSWindow?

    // Thumbnail stream manager for live previews
    private var thumbnailManager: ThumbnailStreamManager?

    // Refresh timer for window list
    private var refreshTimer: Timer?

    override init() {
        super.init()
    }

    func showWindowSelector() {
        Task {
            await loadAvailableWindows()

            await MainActor.run {
                self.presentWindowSelector()
            }
        }
    }

    private func loadAvailableWindows() async {
        do {
            // Vérifier les permissions d'abord
            guard await checkScreenRecordingPermission() else {
                print("❌ [WINDOW] Screen recording permission not granted")
                availableWindows = []
                return
            }

            let content = try await SCShareableContent.current

            // Filter and sort windows
            var windows = content.windows.filter { window in
                guard let title = window.title,
                      let app = window.owningApplication else {
                    return false
                }

                // Filter criteria
                return !title.isEmpty &&
                       window.frame.width > 100 &&
                       window.frame.height > 100 &&
                       window.isOnScreen &&
                       app.applicationName != "Window Server" &&
                       app.applicationName != "ScreenSnap" // Don't show our own window
            }

            // Sort by app name, then by title
            windows.sort { window1, window2 in
                let app1 = window1.owningApplication?.applicationName ?? ""
                let app2 = window2.owningApplication?.applicationName ?? ""

                if app1 != app2 {
                    return app1 < app2
                }

                let title1 = window1.title ?? ""
                let title2 = window2.title ?? ""
                return title1 < title2
            }

            availableWindows = windows

            print("✅ [WINDOW] Found \(availableWindows.count) capturable windows")
        } catch {
            print("❌ [WINDOW] Error loading windows: \(error.localizedDescription)")
            availableWindows = []
        }
    }

    private func checkScreenRecordingPermission() async -> Bool {
        do {
            _ = try await SCShareableContent.current
            return true
        } catch {
            print("❌ [WINDOW] Permission check failed: \(error)")
            return false
        }
    }

    private func presentWindowSelector() {
        // Vérifier qu'on a des fenêtres à afficher
        guard !availableWindows.isEmpty else {
            print("⚠️ [WINDOW] No windows available to display")
            showNoWindowsAlert()
            return
        }

        // Create thumbnail manager
        let thumbnailManager = ThumbnailStreamManager()
        self.thumbnailManager = thumbnailManager

        // Create window selector UI
        let selectorView = WindowSelectorView(
            windows: availableWindows,
            thumbnailManager: thumbnailManager
        ) { [weak self] selectedWindow in
            Task {
                await self?.handleWindowSelection(selectedWindow)
            }
        } onClose: { [weak self] in
            Task {
                await self?.closeSelectorWindow()
            }
        }

        let hostingController = NSHostingController(rootView: selectorView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Sélectionner une fenêtre"
        window.titlebarAppearsTransparent = true
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.minSize = NSSize(width: 600, height: 500)
        self.selectorWindow = window

        // Start refresh timer (refresh list every 3 seconds)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshWindowList()
            }
        }

        NSApp.activate(ignoringOtherApps: true)

        print("✅ [WINDOW] Selector window presented")
    }

    private func refreshWindowList() async {
        // Reload windows without closing selector
        await loadAvailableWindows()

        // Update visible windows in thumbnail manager
        if let thumbnailManager = thumbnailManager {
            // Get currently visible windows from the scroll view
            // For now, just update all windows (optimization possible later)
            await thumbnailManager.updateVisibleWindows(availableWindows)
        }
    }

    private func handleWindowSelection(_ window: SCWindow) async {
        print("🎯 [WINDOW] Selected window: \(window.title ?? "Untitled")")

        await closeSelectorWindow()
        await captureWindow(window)
    }

    private func closeSelectorWindow() async {
        // Stop all thumbnail streams
        if let thumbnailManager = thumbnailManager {
            await thumbnailManager.stopAllStreams()
        }

        // Invalidate refresh timer
        await MainActor.run {
            refreshTimer?.invalidate()
            refreshTimer = nil

            selectorWindow?.close()
            selectorWindow = nil
            thumbnailManager = nil

            print("✅ [WINDOW] Selector window closed")
        }
    }

    private func showNoWindowsAlert() {
        let alert = NSAlert()
        alert.messageText = "Aucune fenêtre disponible"
        alert.informativeText = "Aucune fenêtre capturable n'a été trouvée. Assurez-vous que les applications sont ouvertes et visibles."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func captureWindow(_ window: SCWindow) async {
        do {
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let configuration = SCStreamConfiguration()

            configuration.width = Int(window.frame.width)
            configuration.height = Int(window.frame.height)
            configuration.scalesToFit = false
            configuration.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )

            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))

            await MainActor.run {
                self.processCapture(image: nsImage, window: window)
            }
        } catch {
            print("❌ [WINDOW] Error capturing window: \(error.localizedDescription)")
            await MainActor.run {
                self.showCaptureErrorAlert(error: error)
            }
        }
    }

    private func showCaptureErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Erreur de capture"
        alert.informativeText = "Impossible de capturer la fenêtre : \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func processCapture(image: NSImage, window: SCWindow) {
        // Play sound if enabled
        if AppSettings.shared.playSoundOnCapture {
            NSSound(named: "Pop")?.play()
        }

        // Copy to clipboard if enabled
        if AppSettings.shared.copyToClipboard {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
        }

        // Save to file if enabled
        if AppSettings.shared.saveToFile {
            saveToFile(image: image, windowTitle: window.title ?? "Window")
        }

        // Show Dynamic Island notification
        DynamicIslandManager.shared.show(message: "Fenêtre capturée", duration: 2.0)

        // Also show native notification
        showNotification(windowTitle: window.title ?? "Fenêtre")
    }

    private func saveToFile(image: NSImage, windowTitle: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return
        }

        let fileType: NSBitmapImageRep.FileType
        let fileExtension: String

        switch AppSettings.shared.imageFormat {
        case "jpeg":
            fileType = .jpeg
            fileExtension = "jpg"
        default:
            fileType = .png
            fileExtension = "png"
        }

        guard let data = bitmapImage.representation(using: fileType, properties: [:]) else {
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())

        // Sanitize window title for filename
        let sanitizedTitle = windowTitle
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .prefix(30)

        let filename = "Window-\(sanitizedTitle)-\(timestamp).\(fileExtension)"

        AppSettings.shared.ensureFolderExists()
        let filePath = AppSettings.shared.saveFolderPath + filename

        try? data.write(to: URL(fileURLWithPath: filePath))

        // Post notification for "Reveal last screenshot" feature
        NotificationCenter.default.post(
            name: .screenshotCaptured,
            object: nil,
            userInfo: ["filePath": filePath]
        )
    }

    private func showNotification(windowTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "ScreenSnap"
        content.body = "Fenêtre '\(windowTitle)' capturée"
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Window Selector View

@available(macOS 12.3, *)
struct WindowSelectorView: View {
    let windows: [SCWindow]
    @ObservedObject var thumbnailManager: ThumbnailStreamManager
    let onSelect: (SCWindow) -> Void
    let onClose: () -> Void

    @State private var searchText = ""
    @State private var hoveredWindow: UInt32?
    @State private var selectedGrouping: WindowGrouping = .byApp
    @State private var visibleWindowIDs: Set<UInt32> = []

    enum WindowGrouping {
        case byApp
        case all
    }

    // Group windows by application
    var groupedWindows: [String: [SCWindow]] {
        var groups: [String: [SCWindow]] = [:]

        for window in filteredWindows {
            let appName = window.owningApplication?.applicationName ?? "Sans application"
            groups[appName, default: []].append(window)
        }

        return groups
    }

    var sortedAppNames: [String] {
        groupedWindows.keys.sorted()
    }

    var filteredWindows: [SCWindow] {
        if searchText.isEmpty {
            return windows
        }
        return windows.filter { window in
            let title = window.title?.lowercased() ?? ""
            let appName = window.owningApplication?.applicationName.lowercased() ?? ""
            let query = searchText.lowercased()
            return title.contains(query) || appName.contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with search and controls
            VStack(spacing: 12) {
                HStack {
                    Text("Sélectionner une fenêtre")
                        .font(.title2.weight(.semibold))

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Rechercher par nom ou application...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // Grouping toggle
                Picker("Groupement", selection: $selectedGrouping) {
                    Label("Par application", systemImage: "square.grid.2x2")
                        .tag(WindowGrouping.byApp)
                    Label("Tout afficher", systemImage: "square.grid.3x3")
                        .tag(WindowGrouping.all)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
            }
            .padding(20)
            .background(.ultraThinMaterial)

            Divider()

            // Windows grid
            if filteredWindows.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    if selectedGrouping == .byApp {
                        groupedGridView
                    } else {
                        flatGridView
                    }
                }
                .onAppear {
                    startPreviewsForVisibleWindows()
                }
            }
        }
        .onChange(of: visibleWindowIDs) { _, newValue in
            updateVisiblePreviews(windowIDs: newValue)
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "macwindow.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Aucune fenêtre trouvée")
                .font(.headline)

            if searchText.isEmpty {
                Text("Ouvrez des applications pour capturer leurs fenêtres")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Essayez un autre terme de recherche")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var groupedGridView: some View {
        LazyVStack(alignment: .leading, spacing: 24, pinnedViews: []) {
            ForEach(sortedAppNames, id: \.self) { appName in
                if let appWindows = groupedWindows[appName] {
                    Section {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 240, maximum: 280), spacing: 16)
                        ], spacing: 16) {
                            ForEach(appWindows, id: \.windowID) { window in
                                windowThumbnailView(for: window)
                            }
                        }
                    } header: {
                        HStack {
                            Text(appName)
                                .font(.headline)

                            Text("\(appWindows.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)

                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .padding(20)
    }

    private var flatGridView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 240, maximum: 280), spacing: 16)
        ], spacing: 16) {
            ForEach(filteredWindows, id: \.windowID) { window in
                windowThumbnailView(for: window)
            }
        }
        .padding(20)
    }

    private func windowThumbnailView(for window: SCWindow) -> some View {
        LiveWindowThumbnailView(
            window: window,
            thumbnailManager: thumbnailManager,
            isHovered: hoveredWindow == window.windowID
        )
        .onTapGesture {
            onSelect(window)
        }
        .onHover { hovering in
            hoveredWindow = hovering ? window.windowID : nil
        }
        .onAppear {
            visibleWindowIDs.insert(window.windowID)
        }
        .onDisappear {
            visibleWindowIDs.remove(window.windowID)
        }
    }

    // MARK: - Preview Management

    private func startPreviewsForVisibleWindows() {
        Task {
            let visibleWindows = windows.filter { visibleWindowIDs.contains($0.windowID) }
            await thumbnailManager.updateVisibleWindows(visibleWindows)
        }
    }

    private func updateVisiblePreviews(windowIDs: Set<UInt32>) {
        Task {
            let visibleWindows = windows.filter { windowIDs.contains($0.windowID) }
            await thumbnailManager.updateVisibleWindows(visibleWindows)
        }
    }
}

// MARK: - Live Window Thumbnail View

@available(macOS 12.3, *)
struct LiveWindowThumbnailView: View {
    let window: SCWindow
    @ObservedObject var thumbnailManager: ThumbnailStreamManager
    let isHovered: Bool

    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Live preview or loading state
            Group {
                if let thumbnail = thumbnailManager.getThumbnail(for: window.windowID) {
                    Image(thumbnail, scale: 1.0, label: Text("Preview"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .onAppear {
                            isLoading = false
                        }
                } else {
                    // Loading skeleton
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Chargement...")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        )
                        .aspectRatio(16/10, contentMode: .fit)
                        .onAppear {
                            Task {
                                await thumbnailManager.startPreview(for: window)
                            }
                        }
                }
            }

            // Window info
            VStack(alignment: .leading, spacing: 6) {
                // Window title
                Text(window.title ?? "Sans titre")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // App name and dimensions
                HStack {
                    if let appName = window.owningApplication?.applicationName {
                        HStack(spacing: 4) {
                            Image(systemName: "app.fill")
                                .font(.caption2)
                            Text(appName)
                                .font(.caption)
                        }
                    }

                    Spacer()

                    Text("\(Int(window.frame.width))×\(Int(window.frame.height))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isHovered ? Color(nsColor: .controlAccentColor) : Color.clear, lineWidth: 2.5)
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .shadow(color: isHovered ? .black.opacity(0.15) : .clear, radius: 12, x: 0, y: 6)
        .animation(.quickSpring, value: isHovered)
    }
}

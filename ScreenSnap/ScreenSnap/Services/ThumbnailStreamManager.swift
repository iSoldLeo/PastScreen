//
//  ThumbnailStreamManager.swift
//  ScreenSnap
//
//  Manages live thumbnail streams for window preview
//  Uses ScreenCaptureKit SCStream for real-time video capture
//

import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreGraphics
import AppKit
import Combine

// MARK: - Thumbnail Stream Manager

@MainActor
class ThumbnailStreamManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Live thumbnails indexed by window ID
    @Published private(set) var thumbnails: [CGWindowID: CGImage] = [:]

    /// Stream status for each window
    @Published private(set) var streamStatus: [CGWindowID: StreamStatus] = [:]

    // MARK: - Configuration

    /// Maximum number of simultaneous streams (memory management)
    private let maxSimultaneousStreams = 12

    /// Thumbnail dimensions
    private let thumbnailWidth = 284
    private let thumbnailHeight = 182

    /// Target FPS for thumbnails (5fps sufficient for preview)
    private let targetFPS: Int32 = 5

    // MARK: - Private Properties

    /// Active streams indexed by window ID
    private var activeStreams: [CGWindowID: SCStream] = [:]

    /// Stream outputs indexed by window ID
    private var streamOutputs: [CGWindowID: ThumbnailStreamOutput] = [:]

    /// Queue for managing visible windows
    private var visibleWindowQueue: [CGWindowID] = []

    /// Processing queue for frame handling
    private let processingQueue = DispatchQueue(label: "com.screensnap.thumbnail.processing", qos: .userInteractive)

    // MARK: - Stream Status Enum

    enum StreamStatus {
        case idle
        case starting
        case streaming
        case error(String)
        case stopped
    }

    // MARK: - Public Methods

    /// Start preview for a specific window
    func startPreview(for window: SCWindow) async {
        let windowID = window.windowID

        // Skip if already streaming
        guard activeStreams[windowID] == nil else {
            print("🎥 [THUMBNAIL] Stream already active for window \(windowID)")
            return
        }

        // Check stream limit
        if activeStreams.count >= maxSimultaneousStreams {
            print("⚠️ [THUMBNAIL] Max streams reached (\(maxSimultaneousStreams)), stopping oldest")
            await stopOldestStream()
        }

        streamStatus[windowID] = .starting

        do {
            // Create content filter for this specific window
            let filter = SCContentFilter(desktopIndependentWindow: window)

            // Configure stream for thumbnail capture
            let config = SCStreamConfiguration()
            config.width = thumbnailWidth
            config.height = thumbnailHeight
            config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(targetFPS))
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = false
            config.queueDepth = 3
            config.backgroundColor = .clear

            // Create stream
            let stream = SCStream(filter: filter, configuration: config, delegate: self)

            // Create output handler
            let output = ThumbnailStreamOutput(windowID: windowID) { [weak self] image in
                await self?.updateThumbnail(windowID: windowID, image: image)
            }

            // Add output
            try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: processingQueue)

            // Start capture
            try await stream.startCapture()

            // Store stream and output
            activeStreams[windowID] = stream
            streamOutputs[windowID] = output
            visibleWindowQueue.append(windowID)

            streamStatus[windowID] = .streaming
            print("✅ [THUMBNAIL] Started stream for window \(windowID)")

        } catch {
            streamStatus[windowID] = .error(error.localizedDescription)
            print("❌ [THUMBNAIL] Failed to start stream for window \(windowID): \(error)")
        }
    }

    /// Stop preview for a specific window
    func stopPreview(for windowID: CGWindowID) async {
        guard let stream = activeStreams[windowID] else { return }

        do {
            try await stream.stopCapture()

            // Cleanup
            activeStreams.removeValue(forKey: windowID)
            streamOutputs.removeValue(forKey: windowID)
            thumbnails.removeValue(forKey: windowID)
            streamStatus.removeValue(forKey: windowID)
            visibleWindowQueue.removeAll { $0 == windowID }

            print("🛑 [THUMBNAIL] Stopped stream for window \(windowID)")

        } catch {
            print("⚠️ [THUMBNAIL] Error stopping stream for window \(windowID): \(error)")
        }
    }

    /// Update visible windows (for lazy loading)
    func updateVisibleWindows(_ windows: [SCWindow]) async {
        let newWindowIDs = Set(windows.map { $0.windowID })
        let currentWindowIDs = Set(activeStreams.keys)

        // Stop streams for windows no longer visible
        let toStop = currentWindowIDs.subtracting(newWindowIDs)
        for windowID in toStop {
            await stopPreview(for: windowID)
        }

        // Start streams for newly visible windows (up to limit)
        let toStart = newWindowIDs.subtracting(currentWindowIDs)
        let availableSlots = maxSimultaneousStreams - activeStreams.count

        for (index, window) in windows.enumerated() where toStart.contains(window.windowID) {
            guard index < availableSlots else { break }
            await startPreview(for: window)
        }
    }

    /// Stop all active streams
    func stopAllStreams() async {
        print("🗑️ [THUMBNAIL] Stopping all streams (\(activeStreams.count) active)")

        let windowIDs = Array(activeStreams.keys)
        for windowID in windowIDs {
            await stopPreview(for: windowID)
        }
    }

    /// Get thumbnail for window (returns nil if not available)
    func getThumbnail(for windowID: CGWindowID) -> CGImage? {
        return thumbnails[windowID]
    }

    // MARK: - Private Methods

    /// Update thumbnail image for a window
    private func updateThumbnail(windowID: CGWindowID, image: CGImage) async {
        thumbnails[windowID] = image
    }

    /// Stop the oldest stream to make room for new one
    private func stopOldestStream() async {
        guard let oldestWindowID = visibleWindowQueue.first else { return }
        await stopPreview(for: oldestWindowID)
    }
}

// MARK: - SCStreamDelegate

extension ThumbnailStreamManager: SCStreamDelegate {

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            // Find which window this stream belongs to
            if let windowID = activeStreams.first(where: { $0.value === stream })?.key {
                streamStatus[windowID] = .error(error.localizedDescription)
                print("❌ [THUMBNAIL] Stream stopped with error for window \(windowID): \(error)")
            }
        }
    }
}

// MARK: - Thumbnail Stream Output

class ThumbnailStreamOutput: NSObject, SCStreamOutput {

    private let windowID: CGWindowID
    private let onFrameReceived: (CGImage) async -> Void

    init(windowID: CGWindowID, onFrameReceived: @escaping (CGImage) async -> Void) {
        self.windowID = windowID
        self.onFrameReceived = onFrameReceived
        super.init()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Extract CGImage from sample buffer
        guard type == .screen,
              let imageBuffer = sampleBuffer.imageBuffer else {
            return
        }

        // Convert CVImageBuffer to CGImage
        guard let image = createCGImage(from: imageBuffer) else {
            return
        }

        // Call handler on main actor
        Task { @MainActor in
            await onFrameReceived(image)
        }
    }

    private func createCGImage(from imageBuffer: CVImageBuffer) -> CGImage? {
        // Lock the base address
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }

        // Get buffer information
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)

        // Create color space
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        // Create bitmap context
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }

        // Create CGImage
        return context.makeImage()
    }
}

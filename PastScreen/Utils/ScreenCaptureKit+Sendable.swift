#if canImport(ScreenCaptureKit)
import ScreenCaptureKit

extension SCShareableContent: @retroactive @unchecked Sendable {}
extension SCDisplay: @retroactive @unchecked Sendable {}
extension SCWindow: @retroactive @unchecked Sendable {}
#endif

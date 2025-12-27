//
//  Localization.swift
//  PastScreen
//
//  Runtime language switching without app restart.
//

import Foundation

// Keep a reference to the currently selected bundle.
private var activeLanguageBundle: Bundle?

private let _bundleSwizzleOnce: Void = {
    object_setClass(Bundle.main, SwizzledBundle.self)
}()

private class SwizzledBundle: Bundle, @unchecked Sendable {
    nonisolated override init?(path: String) {
        super.init(path: path)
    }

    nonisolated override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let bundle = MainActor.assumeIsolated { activeLanguageBundle }
        if let bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Switch localization bundle at runtime. Pass nil to use system.
    @MainActor
    static func setAppLanguage(_ code: String?) {
        _ = _bundleSwizzleOnce

        guard
            let code,
            let path = Bundle.main.path(forResource: code, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            activeLanguageBundle = nil
            return
        }

        activeLanguageBundle = bundle
    }
}

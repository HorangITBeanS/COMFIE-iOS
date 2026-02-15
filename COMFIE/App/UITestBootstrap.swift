//
//  UITestBootstrap.swift
//  COMFIE
//
//  Created by zaehorang on 2/13/26.
//

import Foundation

#if DEBUG
enum UITestBootstrap {
    private static let uiTestingArgument = "-ui-testing"

    static func applyIfNeeded(router: Router, userDefaults: UserDefaults = .standard) {
        guard ProcessInfo.processInfo.arguments.contains(uiTestingArgument) else { return }

        userDefaults.set(true, forKey: UserDefaultsConstants.Keys.hasEverOnboarded.rawValue)
        userDefaults.set(true, forKey: UserDefaultsConstants.Keys.hasSeenTutorial.rawValue)
        router.hasEverOnboarded = true
        router.isLoadingViewFinished = true
    }
}
#else
enum UITestBootstrap {
    static func applyIfNeeded(router _: Router, userDefaults _: UserDefaults = .standard) {}
}
#endif

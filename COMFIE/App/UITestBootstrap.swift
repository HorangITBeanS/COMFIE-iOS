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

        // UI 테스트 진입 안정화를 위해 로딩/온보딩/튜토리얼 상태를 고정한다.
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

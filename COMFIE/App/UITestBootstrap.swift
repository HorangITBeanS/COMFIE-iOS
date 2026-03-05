//
//  UITestBootstrap.swift
//  COMFIE
//
//  Created by zaehorang on 2/13/26.
//

import Foundation

enum UITestBootstrap {
    static func hasLaunchArgument(
        _ argument: UITestLaunchArgument,
        processInfo: ProcessInfo = .processInfo
    ) -> Bool {
#if DEBUG
        processInfo.arguments.contains(argument.rawValue)
#else
        _ = argument
        _ = processInfo
        return false
#endif
    }

    static func isUITesting(processInfo: ProcessInfo = .processInfo) -> Bool {
        hasLaunchArgument(.uiTesting, processInfo: processInfo)
    }

    static func applyIfNeeded(router: Router, userDefaults: UserDefaults = .standard) {
#if DEBUG
        // UITest일 때만 초기 라우팅 상태를 고정하고, 일반 실행 흐름은 건드리지 않는다.
        guard isUITesting() else { return }

        userDefaults.set(true, forKey: UserDefaultsConstants.Keys.hasEverOnboarded.rawValue)
        userDefaults.set(true, forKey: UserDefaultsConstants.Keys.hasSeenTutorial.rawValue)
        router.hasEverOnboarded = true
        router.isLoadingViewFinished = true
#else
        _ = router
        _ = userDefaults
#endif
    }
}

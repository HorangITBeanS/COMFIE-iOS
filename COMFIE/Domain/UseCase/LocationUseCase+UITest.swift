//
//  LocationUseCase+UITest.swift
//  COMFIE
//
//  Created by zaehorang on 2/14/26.
//

import CoreLocation
import Foundation

#if DEBUG

final class UITestLocationUseCase: LocationUseCase {
    override func isInComfieZone(_ location: CLLocation?) -> Bool {
        // UITest 강제값이 있으면 우선 적용하고, 없으면 실제 지오펜스 계산을 그대로 따른다.
        if let overrideResult = UITestBootstrap.resolveComfieZoneOverride() {
            return overrideResult
        }
        return super.isInComfieZone(location)
    }
}

extension UITestBootstrap {
    static func resolveComfieZoneOverride(processInfo: ProcessInfo = .processInfo) -> Bool? {
        guard isUITesting(processInfo: processInfo) else { return nil }
        if hasLaunchArgument(.forceInsideComfieZone, processInfo: processInfo) {
            return true
        }
        if hasLaunchArgument(.forceOutsideComfieZone, processInfo: processInfo) {
            return false
        }
        return nil
    }
}

#endif

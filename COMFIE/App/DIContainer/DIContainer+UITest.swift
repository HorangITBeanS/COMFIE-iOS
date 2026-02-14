//
//  DIContainer+UITest.swift
//  COMFIE
//
//  Created by zaehorang on 2/14/26.
//

#if DEBUG

extension DIContainer {
    func makeLocationUseCase() -> LocationUseCase {
        // Debug에서도 기본은 릴리즈 경로를 사용하고, UITest일 때만 테스트 전용 구현을 주입한다.
        guard UITestBootstrap.isUITesting() else {
            return makeReleaseLocationUseCase()
        }
        return UITestLocationUseCase(
            locationService: makeLocationService,
            comfiZoneRepository: comfieZoneRepository
        )
    }
}

#endif

//
//  LocalAuthenticationService.swift
//  COMFIE
//
//  Created by Anjin on 4/16/25.
//

import LocalAuthentication

struct LocalAuthenticationService {
    func request() async -> Result<Void, Error> {
        let context = LAContext()
        
        do {
            try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "암호 입력"  // 영어는 Enter Passcode
            )
            print("✅ 암호 인증 성공")
            return .success(())
            
        } catch let error {
            print("❌ 암호 인증 실패: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}

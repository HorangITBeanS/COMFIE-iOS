//
//  COMFIEUITestsLaunchTests.swift
//  COMFIEUITests
//
//  Created by Anjin on 3/5/25.
//

import XCTest

class COMFIEUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {

        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {

        let app = XCUIApplication()
        app.launch()
        enforcePortraitOrientationForUITests()
    }
}

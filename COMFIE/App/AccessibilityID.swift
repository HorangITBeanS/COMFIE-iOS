//
//  AccessibilityID.swift
//  COMFIE
//
//  Created by zaehorang on 2/13/26.
//

enum AccessibilityID {
    // 앱 타깃과 UITest 타깃이 같은 식별자 문자열을 공유하도록 중앙 관리한다.
    enum Memo {
        static let comfieZoneSettingButton = "memo.comfieZoneSettingButton"
        static let moreButton = "memo.moreButton"
        static let sendButton = "memo.sendButton"
        static let editingCancelButton = "memo.editingCancelButton"

        static let inputTextView = "memo.inputTextView"
        static let cellContentText = "memo.cell.contentText"
        static let cellMenuButton = "memo.cell.menuButton"
        static let cellMenuEditButton = "memo.cell.menu.editButton"
        static let cellMenuRetrospectionButton = "memo.cell.menu.retrospectionButton"
        static let cellMenuDeleteButton = "memo.cell.menu.deleteButton"
    }

    enum Popup {
        static let leftButton = "popup.leftButton"
        static let rightButton = "popup.rightButton"
    }
}

enum UITestLaunchArgument: String {
    // Debug 빌드에서 UITestBootstrap이 해석하는 런치 인자 목록이다.
    case uiTesting = "-ui-testing"
    case draftDebug = "-ui-testing-draft-debug"
    case forceInsideComfieZone = "-ui-testing-force-inside-comfie-zone"
    case forceOutsideComfieZone = "-ui-testing-force-outside-comfie-zone"
    case forceASCIIKeyboard = "-ui-testing-force-ascii-keyboard"
    case forceKoreanKeyboard = "-ui-testing-force-korean-keyboard"
}

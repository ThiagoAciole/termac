//
//  HeaderSizeSettingTests.swift
//  TermacTests
//

import Testing
@testable import Termac

struct HeaderSizeSettingTests {
    @Test func agentMenuIconIsLargerThanStandardChromeIcon() {
        #expect(HeaderSizeSetting.compact.agentMenuIconSize > HeaderSizeSetting.compact.buttonIconSize)
        #expect(HeaderSizeSetting.regular.agentMenuIconSize > HeaderSizeSetting.regular.buttonIconSize)
        #expect(HeaderSizeSetting.large.agentMenuIconSize > HeaderSizeSetting.large.buttonIconSize)
    }

    @Test func agentMenuIconGrowsWithHeaderSize() {
        #expect(HeaderSizeSetting.compact.agentMenuIconSize < HeaderSizeSetting.regular.agentMenuIconSize)
        #expect(HeaderSizeSetting.regular.agentMenuIconSize < HeaderSizeSetting.large.agentMenuIconSize)
    }
}

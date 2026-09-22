//
//  HeaderSizeSettingTests.swift
//  TermacTests
//

import Testing
@testable import Termac

struct HeaderSizeSettingTests {
    @Test func chromeIconScalesWithHeaderSize() {
        #expect(HeaderSizeSetting.compact.buttonIconSize < HeaderSizeSetting.regular.buttonIconSize)
        #expect(HeaderSizeSetting.regular.buttonIconSize < HeaderSizeSetting.large.buttonIconSize)
    }

    @Test func actionIconIsLargerThanStandardChromeIcon() {
        #expect(HeaderSizeSetting.compact.actionIconSize > HeaderSizeSetting.compact.buttonIconSize)
        #expect(HeaderSizeSetting.regular.actionIconSize > HeaderSizeSetting.regular.buttonIconSize)
        #expect(HeaderSizeSetting.large.actionIconSize > HeaderSizeSetting.large.buttonIconSize)
    }

    @Test func chromeFrameScalesWithHeaderSize() {
        #expect(HeaderSizeSetting.compact.buttonFrameWidth < HeaderSizeSetting.regular.buttonFrameWidth)
        #expect(HeaderSizeSetting.regular.buttonFrameWidth < HeaderSizeSetting.large.buttonFrameWidth)
        #expect(HeaderSizeSetting.compact.buttonFrameHeight < HeaderSizeSetting.regular.buttonFrameHeight)
        #expect(HeaderSizeSetting.regular.buttonFrameHeight < HeaderSizeSetting.large.buttonFrameHeight)
    }
}

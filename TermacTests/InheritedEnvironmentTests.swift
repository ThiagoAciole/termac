//
//  InheritedEnvironmentTests.swift
//  TermacTests
//

import Darwin
import Testing
@testable import Termac

struct InheritedEnvironmentTests {
    @Test func sanitizeRemovesChildSessionMarkerFromProcessEnvironment() {
        setenv("CLAUDE_CODE_CHILD_SESSION", "1", 1)
        sanitizeInheritedEnvironment()
        #expect(getenv("CLAUDE_CODE_CHILD_SESSION") == nil)
    }

    @Test func sanitizeIsANoOpWithoutTheMarker() {
        unsetenv("CLAUDE_CODE_CHILD_SESSION")
        sanitizeInheritedEnvironment()
        #expect(getenv("CLAUDE_CODE_CHILD_SESSION") == nil)
    }
}

//
//  FuzzyMatcherTests.swift
//  TermacTests
//

import Testing
@testable import Termac

struct FuzzyMatcherTests {
    @Test func emptyQueryKeepsStableOrder() {
        let items = [item("first", title: "First"), item("second", title: "Second")]
        #expect(FuzzyMatcher.rank(items: items, query: "").map(\.id) == ["first", "second"])
    }

    @Test func matchesCaseInsensitivelyAndBySubsequence() {
        let item = item("claude", title: "Claude Code")
        #expect(FuzzyMatcher.rank(items: [item], query: "cld").map(\.id) == ["claude"])
        #expect(FuzzyMatcher.rank(items: [item], query: "CLAUDE").map(\.id) == ["claude"])
    }

    @Test func matchesMultipleQueryTokensAcrossCandidate() {
        let item = item("move", title: "Move Tab Right")
        #expect(FuzzyMatcher.rank(items: [item], query: "move right").map(\.id) == ["move"])
        #expect(FuzzyMatcher.rank(items: [item], query: "tab move").map(\.id) == ["move"])
    }

    @Test func exactAndPrefixMatchesRankBeforeLooseMatches() {
        let items = [
            item("word", title: "Command Palette"),
            item("prefix", title: "Palettes"),
            item("exact", title: "Palette"),
        ]
        #expect(FuzzyMatcher.rank(items: items, query: "palette").map(\.id) == ["exact", "prefix", "word"])
    }

    @Test func subsequenceFindsScatteredLetters() {
        let item = item("palette", title: "Palette")
        #expect(FuzzyMatcher.rank(items: [item], query: "pltt").map(\.id) == ["palette"])
    }

    @Test func excludesItemsWithoutAllTokens() {
        let items = [item("one", title: "Claude Code"), item("two", title: "Codex")]
        #expect(FuzzyMatcher.rank(items: items, query: "claude terminal").isEmpty)
    }

    private func item(_ id: String, title: String) -> CommandPaletteItem {
        CommandPaletteItem(id: id, title: title, icon: "terminal", kind: .action) {}
    }
}

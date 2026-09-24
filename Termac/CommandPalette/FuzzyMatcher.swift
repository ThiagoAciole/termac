//
//  FuzzyMatcher.swift
//  termac
//

import Foundation

enum FuzzyMatcher {
    /// Returns a higher score for closer matches and nil when any query token misses.
    static func score(query: String, candidate: String) -> Int? {
        let tokens = normalizedTokens(query)
        guard !tokens.isEmpty else { return 0 }

        let normalizedCandidate = candidate.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        var total = 0
        for token in tokens {
            guard let tokenScore = scoreToken(token, in: normalizedCandidate) else { return nil }
            total += tokenScore
        }
        return total
    }

    static func rank(
        items: [CommandPaletteItem],
        query: String
    ) -> [CommandPaletteItem] {
        guard !normalizedTokens(query).isEmpty else { return items }

        struct Scored {
            let item: CommandPaletteItem
            let score: Int
            let index: Int
        }

        let scored: [Scored] = items.enumerated().compactMap { index, item in
            guard let score = item.searchTerms
                .compactMap({ score(query: query, candidate: $0) })
                .max()
            else { return nil }
            return Scored(item: item, score: score, index: index)
        }

        return scored
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.index < $1.index
            }
            .map(\.item)
    }

    private static func scoreToken(_ token: String, in candidate: String) -> Int? {
        guard !token.isEmpty else { return 0 }
        if candidate == token { return 1_000 }
        if candidate.hasPrefix(token) { return 700 - token.count }

        let wordPrefix = candidate.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .contains { $0.hasPrefix(token) }
        if wordPrefix { return 500 - token.count }

        guard let match = subsequenceMatch(token, in: candidate) else { return nil }
        return 300 - match.position - match.gaps
    }

    private static func subsequenceMatch(_ token: String, in candidate: String) -> (position: Int, gaps: Int)? {
        let characters = Array(candidate)
        let target = Array(token)
        var targetIndex = 0
        var firstPosition: Int?
        var previousPosition: Int?
        var gaps = 0

        for (index, character) in characters.enumerated() where targetIndex < target.count {
            guard character == target[targetIndex] else { continue }
            firstPosition = firstPosition ?? index
            if let previousPosition {
                gaps += max(0, index - previousPosition - 1)
            }
            previousPosition = index
            targetIndex += 1
        }

        guard targetIndex == target.count, let firstPosition else { return nil }
        return (firstPosition, gaps)
    }

    private static func normalizedTokens(_ query: String) -> [String] {
        query
            .split(whereSeparator: \.isWhitespace)
            .map {
                String($0).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            }
    }
}

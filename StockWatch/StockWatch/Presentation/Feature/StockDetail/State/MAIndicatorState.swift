//
//  MAIndicatorState.swift
//  StockWatch
//

import Foundation

struct MAIndicatorState: Equatable {
    var lines: [MALine]

    static let defaultColors: [String] = [
        "#F5A623", "#4CAF50", "#2196F3", "#E91E63", "#9C27B0"
    ]

    static let defaultLines: [MALine] = [
        MALine(period: 5, colorHex: "#F5A623", lineWidth: 1),
        MALine(period: 20, colorHex: "#4CAF50", lineWidth: 1)
    ]

    static let maxLineCount = 5

    init(lines: [MALine] = defaultLines) {
        self.lines = lines
    }

    init(configuration: MAIndicatorConfiguration) {
        self.lines = configuration.lines
    }

    func toConfiguration() -> MAIndicatorConfiguration {
        MAIndicatorConfiguration(lines: lines)
    }
}

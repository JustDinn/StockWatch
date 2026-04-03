//
//  EMAIndicatorState.swift
//  StockWatch
//

import Foundation

struct EMAIndicatorState: Equatable {
    var lines: [EMALine]

    static let defaultColors: [String] = [
        "#F5A623", "#4CAF50", "#2196F3", "#E91E63", "#9C27B0"
    ]

    static let defaultLines: [EMALine] = [
        EMALine(period: 5, colorHex: "#F5A623", lineWidth: 1),
        EMALine(period: 20, colorHex: "#4CAF50", lineWidth: 1)
    ]

    static let maxLineCount = 5

    init(lines: [EMALine] = defaultLines) {
        self.lines = lines
    }

    init(configuration: EMAIndicatorConfiguration) {
        self.lines = configuration.lines
    }

    func toConfiguration() -> EMAIndicatorConfiguration {
        EMAIndicatorConfiguration(lines: lines)
    }
}

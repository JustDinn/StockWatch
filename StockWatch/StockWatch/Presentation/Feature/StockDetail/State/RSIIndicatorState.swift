//
//  RSIIndicatorState.swift
//  StockWatch
//

import Foundation

struct RSIIndicatorState: Equatable {
    var line: RSILine
    var upperLevel: RSILevel
    var middleLevel: RSILevel
    var lowerLevel: RSILevel
    var background: RSIBackground

    init(
        line: RSILine = RSIConfiguration.defaultConfiguration.line,
        upperLevel: RSILevel = RSIConfiguration.defaultConfiguration.upperLevel,
        middleLevel: RSILevel = RSIConfiguration.defaultConfiguration.middleLevel,
        lowerLevel: RSILevel = RSIConfiguration.defaultConfiguration.lowerLevel,
        background: RSIBackground = RSIConfiguration.defaultConfiguration.background
    ) {
        self.line = line
        self.upperLevel = upperLevel
        self.middleLevel = middleLevel
        self.lowerLevel = lowerLevel
        self.background = background
    }

    init(configuration: RSIConfiguration) {
        self.line = configuration.line
        self.upperLevel = configuration.upperLevel
        self.middleLevel = configuration.middleLevel
        self.lowerLevel = configuration.lowerLevel
        self.background = configuration.background
    }

    func toConfiguration() -> RSIConfiguration {
        RSIConfiguration(
            line: line,
            upperLevel: upperLevel,
            middleLevel: middleLevel,
            lowerLevel: lowerLevel,
            background: background
        )
    }
}

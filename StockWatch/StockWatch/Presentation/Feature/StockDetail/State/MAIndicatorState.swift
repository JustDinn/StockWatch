//
//  MAIndicatorState.swift
//  StockWatch
//

import Foundation

struct MAIndicatorPeriod: Identifiable, Equatable {
    let id: UUID
    var period: Int
    var colorHex: String
    var lineWidth: Int
}

struct MAIndicatorState: Equatable {
    var periods: [MAIndicatorPeriod]

    static let defaultColors: [String] = [
        "#F5A623", "#4CAF50", "#2196F3", "#E91E63", "#9C27B0"
    ]

    static let defaultPeriods: [MAIndicatorPeriod] = [
        MAIndicatorPeriod(id: UUID(), period: 5, colorHex: "#F5A623", lineWidth: 1),
        MAIndicatorPeriod(id: UUID(), period: 20, colorHex: "#4CAF50", lineWidth: 1)
    ]

    static let maxPeriodCount = 5

    init(periods: [MAIndicatorPeriod] = defaultPeriods) {
        self.periods = periods
    }
}

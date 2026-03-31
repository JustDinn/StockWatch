//
//  RSIConfiguration.swift
//  StockWatch
//

import Foundation

struct RSILine: Codable, Equatable {
    var period: Int
    var colorHex: String
    var lineWidth: Int
    var isEnabled: Bool
}

struct RSILevel: Codable, Equatable {
    var value: Int
    var isEnabled: Bool
}

struct RSIBackground: Codable, Equatable {
    var colorHex: String
    var isEnabled: Bool
}

struct RSIConfiguration: Codable, Equatable {
    var line: RSILine
    var upperLevel: RSILevel
    var middleLevel: RSILevel
    var lowerLevel: RSILevel
    var background: RSIBackground

    static let defaultConfiguration = RSIConfiguration(
        line: RSILine(period: 14, colorHex: "#7B1FA2", lineWidth: 1, isEnabled: true),
        upperLevel: RSILevel(value: 70, isEnabled: true),
        middleLevel: RSILevel(value: 50, isEnabled: false),
        lowerLevel: RSILevel(value: 30, isEnabled: true),
        background: RSIBackground(colorHex: "#333333", isEnabled: true)
    )
}

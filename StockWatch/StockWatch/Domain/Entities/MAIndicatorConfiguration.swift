//
//  MAIndicatorConfiguration.swift
//  StockWatch
//

import Foundation

/// 개별 이동평균선 정보
struct MALine: Codable, Equatable, Identifiable {
    let id: UUID
    var period: Int
    var colorHex: String
    var lineWidth: Int

    init(id: UUID = UUID(), period: Int, colorHex: String, lineWidth: Int) {
        self.id = id
        self.period = period
        self.colorHex = colorHex
        self.lineWidth = lineWidth
    }
}

/// 이동평균선 설정 컨테이너
struct MAIndicatorConfiguration: Codable, Equatable {
    var lines: [MALine]

    static let defaultColors: [String] = [
        "#F5A623", "#4CAF50", "#2196F3", "#E91E63", "#9C27B0"
    ]

    static let defaultConfiguration = MAIndicatorConfiguration(
        lines: [
            MALine(period: 5, colorHex: "#F5A623", lineWidth: 1),
            MALine(period: 20, colorHex: "#4CAF50", lineWidth: 1)
        ]
    )

    static let maxLineCount = 5

    init(lines: [MALine] = []) {
        self.lines = lines
    }
}

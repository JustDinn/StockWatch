//
//  MAIndicatorConfiguration.swift
//  StockWatch
//

import Foundation

/// 이동평균 계산 기준 가격
enum MAPriceSource: String, Codable, CaseIterable, Equatable {
    case close
    case open

    var displayName: String { self == .close ? "종가" : "시가" }
}

/// 개별 이동평균선 정보
struct MALine: Codable, Equatable, Identifiable {
    let id: UUID
    var period: Int
    var colorHex: String
    var lineWidth: Int
    var priceSource: MAPriceSource

    init(id: UUID = UUID(), period: Int, colorHex: String, lineWidth: Int, priceSource: MAPriceSource = .close) {
        self.id = id
        self.period = period
        self.colorHex = colorHex
        self.lineWidth = lineWidth
        self.priceSource = priceSource
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        period = try container.decode(Int.self, forKey: .period)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        lineWidth = try container.decode(Int.self, forKey: .lineWidth)
        priceSource = try container.decodeIfPresent(MAPriceSource.self, forKey: .priceSource) ?? .close
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

//
//  VolumeMAConfiguration.swift
//  StockWatch
//

import Foundation

/// 거래량 이동평균선 정보
struct VolumeMALine: Codable, Equatable {
    var period: Int
    var colorHex: String
    var lineWidth: Int
    var isEnabled: Bool

    init(period: Int, colorHex: String, lineWidth: Int, isEnabled: Bool) {
        self.period = period
        self.colorHex = colorHex
        self.lineWidth = lineWidth
        self.isEnabled = isEnabled
    }
}

/// 거래량 이동평균선 설정 컨테이너
struct VolumeMAConfiguration: Codable, Equatable {
    var line: VolumeMALine

    static let defaultConfiguration = VolumeMAConfiguration(
        line: VolumeMALine(period: 20, colorHex: "#4CAF50", lineWidth: 1, isEnabled: false)
    )
}

//
//  YahooFinanceChartMapper.swift
//  StockWatch
//

import Foundation

/// YahooFinanceChartDTO → 종가 배열([Double]) 변환 Mapper
enum YahooFinanceChartMapper {

    /// DTO에서 종가(close) 배열을 추출한다. nil 값(휴장일 등)은 제거한다.
    static func mapToCloses(_ dto: YahooFinanceChartDTO) -> [Double] {
        guard
            let result = dto.chart.result?.first,
            let closes = result.indicators.quote?.first?.close
        else { return [] }
        return closes.compactMap { $0 }
    }
}

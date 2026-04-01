//
//  UpperIndicatorLabel.swift
//  StockWatch
//

/// 차트 상단 오버레이에 표시할 지표 라벨 데이터
struct IndicatorValue: Equatable {
    let period: Int
    let colorHex: String
}

struct UpperIndicatorLabel: Equatable, Identifiable {
    /// TechnicalIndicator.rawValue
    let id: String
    /// 한글 지표명 (예: "이동평균선")
    let name: String
    /// 각 라인의 period + 색상 목록
    let values: [IndicatorValue]
}

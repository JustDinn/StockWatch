//
//  TechnicalIndicator.swift
//  StockWatch
//

enum IndicatorTab: String, CaseIterable {
    case upper = "상단지표"
    case lower = "하단지표"
}

enum TechnicalIndicator: String, CaseIterable, Hashable, Identifiable {
    case movingAverage
    case volume
    case rsi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .movingAverage: return "이동평균선"
        case .volume:        return "거래량"
        case .rsi:           return "RSI"
        }
    }

    var description: String {
        switch self {
        case .movingAverage: return "지난 n일 동안의 주가 평균값을 이은 선"
        case .volume:        return "거래량을 가격대별로 비교할 수 있는 막대그래프"
        case .rsi:           return "주가의 상승/하락 강도를 나타내는 0~100 사이의 지표"
        }
    }

    var tab: IndicatorTab {
        switch self {
        case .movingAverage: return .upper
        case .volume:        return .lower
        case .rsi:           return .lower
        }
    }

    static func indicators(for tab: IndicatorTab) -> [TechnicalIndicator] {
        allCases.filter { $0.tab == tab }
    }
}

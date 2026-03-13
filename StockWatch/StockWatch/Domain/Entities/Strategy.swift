//
//  Strategy.swift
//  StockWatch
//

/// 전략 엔티티
struct Strategy: Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    let description: String
    let category: StrategyCategory
}

/// 전략 카테고리
enum StrategyCategory: String, CaseIterable, Equatable {
    case movingAverage = "이동평균"
    case oscillator = "오실레이터"
}

extension Strategy {
    /// strategyId로 Strategy를 조회한다. (StrategyRepository의 정적 데이터와 동기화)
    static func from(strategyId: String) -> Strategy? {
        switch strategyId {
        case "sma_cross":
            return Strategy(
                id: "sma_cross",
                name: "단순 이동평균선 크로스 전략",
                shortName: "SMA",
                description: "",
                category: .movingAverage
            )
        case "ema_cross":
            return Strategy(
                id: "ema_cross",
                name: "지수 이동평균선 크로스 전략",
                shortName: "EMA",
                description: "",
                category: .movingAverage
            )
        case "rsi":
            return Strategy(
                id: "rsi",
                name: "RSI 전략",
                shortName: "RSI",
                description: "",
                category: .oscillator
            )
        default:
            return nil
        }
    }
}

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

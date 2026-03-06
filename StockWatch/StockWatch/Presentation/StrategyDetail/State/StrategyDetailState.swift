//
//  StrategyDetailState.swift
//  StockWatch
//

/// StrategyDetail 화면 UI 상태
struct StrategyDetailState: Equatable {
    let strategy: Strategy
    var isSaved: Bool = false
    var isLoading: Bool = false
}

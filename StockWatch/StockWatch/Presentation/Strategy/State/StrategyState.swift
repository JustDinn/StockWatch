//
//  StrategyState.swift
//  StockWatch
//

/// Strategy 카탈로그 화면 UI 상태
struct StrategyState: Equatable {
    var allStrategies: [Strategy] = []
    var savedStrategyIds: Set<String> = []
    var selectedSegment: StrategySegment = .all
    var selectedStrategy: Strategy? = nil
    var infoStrategy: Strategy? = nil
    var isLoading: Bool = false

    /// 현재 세그먼트에 따라 표시할 전략 목록
    var displayedStrategies: [Strategy] {
        switch selectedSegment {
        case .all:
            return allStrategies
        case .saved:
            return allStrategies.filter { savedStrategyIds.contains($0.id) }
        }
    }
}

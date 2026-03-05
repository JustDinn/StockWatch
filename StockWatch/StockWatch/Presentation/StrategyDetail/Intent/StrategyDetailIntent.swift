//
//  StrategyDetailIntent.swift
//  StockWatch
//

/// StrategyDetail 화면 사용자 액션 정의
enum StrategyDetailIntent {
    /// 화면 진입 시 저장 상태 로드
    case loadSavedStatus
    /// 전략 저장 토글
    case toggleSaved
}

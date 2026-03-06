//
//  StrategyIntent.swift
//  StockWatch
//

/// Strategy 카탈로그 화면 사용자 액션 정의
enum StrategyIntent {
    /// 화면 진입 시 전략 목록 및 저장 상태 로드
    case loadStrategies
    /// 세그먼트 전환 (전체 / 저장됨)
    case selectSegment(StrategySegment)
    /// 전략 셀 탭 → 상세 화면 이동
    case selectStrategy(Strategy)
}

/// 전략 카탈로그 세그먼트
enum StrategySegment: String, CaseIterable {
    case all = "전체"
    case saved = "저장됨"
}

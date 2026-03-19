//
//  StockDetailIntent.swift
//  StockWatch
//

/// StockDetail 화면 사용자 액션 정의
enum StockDetailIntent {
    /// 화면 진입 시 종목 상세 데이터 로드
    case loadDetail
    /// 뒤로 가기 (현재 단계에서는 SwiftUI 내장 뒤로 가기를 사용하므로 예약)
    case dismiss
    /// 관심 종목 토글
    case toggleFavorite
    /// 전략 적용 화면으로 이동
    case navigateToApplyStrategy
    /// 봉 주기 선택
    case selectPeriod(ChartPeriod)
}

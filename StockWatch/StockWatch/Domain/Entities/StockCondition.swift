//
//  StockCondition.swift
//  StockWatch
//

import Foundation

/// 종목에 적용된 전략 조건
/// 특정 종목에 특정 전략을 커스텀 파라미터와 함께 연결하며, 알림 설정을 포함한다.
struct StockCondition: Equatable, Identifiable {
    /// 고유 식별자 (UUID 문자열)
    let id: String
    /// 티커 심볼 (예: "AAPL")
    let ticker: String
    /// 전략 ID (예: "rsi", "sma_cross")
    let strategyId: String
    /// 사용자 커스텀 파라미터
    let parameters: StrategyParameters
    /// 푸시 알림 활성 여부
    var isNotificationEnabled: Bool
    /// 조건 활성 여부 (비활성화해도 삭제하지 않음)
    var isActive: Bool
    /// 생성 일시
    let createdAt: Date
}

//
//  StrategySignal.swift
//  StockWatch
//

import Foundation

/// 전략 평가 결과 타입
enum SignalType: String, Equatable {
    case buy = "매수"
    case sell = "매도"
    case neutral = "중립"
}

/// 전략 즉시 확인 결과
struct StrategySignal: Equatable {
    /// 전략 ID (예: "rsi", "sma_cross")
    let strategyId: String
    /// 티커 심볼 (예: "AAPL")
    let ticker: String
    /// 신호 타입 (매수/매도/중립)
    let signalType: SignalType
    /// 사람이 읽을 수 있는 설명 (예: "RSI(14) = 28.3 → 과매도")
    let description: String
    /// 평가 시각
    let evaluatedAt: Date
}

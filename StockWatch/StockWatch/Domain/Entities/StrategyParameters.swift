//
//  StrategyParameters.swift
//  StockWatch
//

/// 전략별 커스텀 파라미터
/// 각 전략 타입에 따라 사용자가 설정할 수 있는 파라미터를 정의한다.
enum StrategyParameters: Equatable, Hashable {
    /// 단순 이동평균선 크로스 전략 파라미터
    case sma(shortPeriod: Int, longPeriod: Int)
    /// 지수 이동평균선 크로스 전략 파라미터
    case ema(shortPeriod: Int, longPeriod: Int)
    /// RSI 전략 파라미터
    case rsi(period: Int, oversoldThreshold: Double, overboughtThreshold: Double)
}

extension StrategyParameters {

    /// 파라미터의 전략 ID
    var strategyId: String {
        switch self {
        case .sma: return "sma_cross"
        case .ema: return "ema_cross"
        case .rsi: return "rsi"
        }
    }

    /// 각 전략의 기본 파라미터
    static func defaultParameters(for strategyId: String) -> StrategyParameters? {
        switch strategyId {
        case "sma_cross": return .sma(shortPeriod: 20, longPeriod: 50)
        case "ema_cross": return .ema(shortPeriod: 12, longPeriod: 26)
        case "rsi": return .rsi(period: 14, oversoldThreshold: 30, overboughtThreshold: 70)
        default: return nil
        }
    }
}

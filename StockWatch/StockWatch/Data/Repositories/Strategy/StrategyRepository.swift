//
//  StrategyRepository.swift
//  StockWatch
//

/// 전략 목록 Repository 구현체
/// 현재는 하드코딩된 전략 목록을 반환한다.
final class StrategyRepository: StrategyRepositoryProtocol {

    func fetchAllStrategies() async -> [Strategy] {
        [
            Strategy(
                id: "sma_cross",
                name: "단순 이동평균선 크로스 전략",
                shortName: "SMA",
                description: """
                단순 이동평균선(SMA) 크로스 전략은 두 개의 이동평균선이 교차하는 시점을 매매 신호로 활용합니다.

                단기 이동평균선(예: 20일)이 장기 이동평균선(예: 50일)을 상향 돌파하면 골든크로스로 매수 신호, \
                하향 돌파하면 데드크로스로 매도 신호로 판단합니다.

                SMA는 일정 기간의 종가를 단순 평균하여 계산하며, 추세의 방향과 전환점을 파악하는 데 유용합니다.
                """,
                category: .movingAverage
            ),
            Strategy(
                id: "ema_cross",
                name: "지수 이동평균선 크로스 전략",
                shortName: "EMA",
                description: """
                지수 이동평균선(EMA) 크로스 전략은 SMA와 유사하지만, 최근 가격에 더 높은 가중치를 부여합니다.

                EMA는 SMA보다 가격 변동에 민감하게 반응하여 더 빠른 매매 신호를 제공합니다. \
                단기 EMA가 장기 EMA를 상향 돌파하면 매수, 하향 돌파하면 매도 신호입니다.

                빠른 반응이 장점이지만, 횡보장에서는 잦은 거짓 신호가 발생할 수 있습니다.
                """,
                category: .movingAverage
            ),
            Strategy(
                id: "rsi",
                name: "RSI 전략",
                shortName: "RSI",
                description: """
                RSI(상대강도지수)는 일정 기간 동안의 가격 상승과 하락의 상대적 강도를 0~100 사이의 값으로 나타냅니다.

                일반적으로 RSI가 70 이상이면 과매수 구간으로 매도 신호, 30 이하이면 과매도 구간으로 매수 신호로 판단합니다.

                추세가 강한 시장에서는 과매수/과매도 기준을 조정(80/20)하여 사용하기도 합니다.
                """,
                category: .oscillator
            )
        ]
    }
}

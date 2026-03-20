//
//  StrategyEvaluationRepository.swift
//  StockWatch
//

import Foundation

/// 전략 평가 Repository 구현체
/// Yahoo Finance v8 API로 과거 종가 데이터를 조회하고, 로컬에서 기술 지표를 계산하여 StrategySignal을 반환한다.
final class StrategyEvaluationRepository: StrategyEvaluationRepositoryProtocol {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func evaluate(ticker: String, parameters: StrategyParameters) async throws -> StrategySignal {
        // 거래일 → 캘린더일 변환: 1 거래일 ≈ 1.45 캘린더일 (연간 252 거래일 / 365 캘린더일)
        // 여유분 20일 추가로 공휴일·주말 편차 보정
        let daysBack = Int(Double(parameters.requiredTradingDays) * 1.5) + 20
        let dto = try await networkService.request(
            router: YahooFinanceChartRouter.dailyChart(symbol: ticker, daysBack: daysBack),
            model: YahooFinanceChartDTO.self
        )
        let closes = YahooFinanceChartMapper.mapToCloses(dto)
        return YahooFinanceSignalMapper.map(ticker: ticker, closes: closes, parameters: parameters)
    }
}

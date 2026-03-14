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
        let dto = try await networkService.request(
            router: YahooFinanceChartRouter.dailyChart(symbol: ticker),
            model: YahooFinanceChartDTO.self
        )
        let closes = YahooFinanceChartMapper.mapToCloses(dto)
        return YahooFinanceSignalMapper.map(ticker: ticker, closes: closes, parameters: parameters)
    }
}

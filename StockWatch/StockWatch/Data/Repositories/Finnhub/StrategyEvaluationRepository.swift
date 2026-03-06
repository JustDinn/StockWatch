//
//  StrategyEvaluationRepository.swift
//  StockWatch
//

import Foundation

/// 전략 평가 Repository 구현체
/// Finnhub /indicator API를 호출하여 기술 지표를 조회하고 StrategySignal을 반환한다.
final class StrategyEvaluationRepository: StrategyEvaluationRepositoryProtocol {

    private let networkService: NetworkServiceProtocol
    private let apiKey: String

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        apiKey: String = Bundle.main.infoDictionary?["FINNHUB_API_KEY"] as? String ?? ""
    ) {
        self.networkService = networkService
        self.apiKey = apiKey
    }

    func evaluate(ticker: String, parameters: StrategyParameters) async throws -> StrategySignal {
        switch parameters {
        case let .sma(shortPeriod, longPeriod):
            return try await evaluateSMA(ticker: ticker, shortPeriod: shortPeriod, longPeriod: longPeriod)
        case let .ema(shortPeriod, longPeriod):
            return try await evaluateEMA(ticker: ticker, shortPeriod: shortPeriod, longPeriod: longPeriod)
        case let .rsi(period, oversoldThreshold, overboughtThreshold):
            return try await evaluateRSI(
                ticker: ticker,
                period: period,
                oversoldThreshold: oversoldThreshold,
                overboughtThreshold: overboughtThreshold
            )
        }
    }

    // MARK: - Private

    private func evaluateSMA(ticker: String, shortPeriod: Int, longPeriod: Int) async throws -> StrategySignal {
        async let shortDTO = networkService.request(
            router: FinnhubIndicatorRouter.sma(symbol: ticker, period: shortPeriod, apiKey: apiKey),
            model: TechnicalIndicatorDTO.self
        )
        async let longDTO = networkService.request(
            router: FinnhubIndicatorRouter.sma(symbol: ticker, period: longPeriod, apiKey: apiKey),
            model: TechnicalIndicatorDTO.self
        )

        let (short, long) = try await (shortDTO, longDTO)
        return TechnicalIndicatorMapper.mapSMA(
            ticker: ticker,
            shortDTO: short,
            longDTO: long,
            shortPeriod: shortPeriod,
            longPeriod: longPeriod
        )
    }

    private func evaluateEMA(ticker: String, shortPeriod: Int, longPeriod: Int) async throws -> StrategySignal {
        async let shortDTO = networkService.request(
            router: FinnhubIndicatorRouter.ema(symbol: ticker, period: shortPeriod, apiKey: apiKey),
            model: TechnicalIndicatorDTO.self
        )
        async let longDTO = networkService.request(
            router: FinnhubIndicatorRouter.ema(symbol: ticker, period: longPeriod, apiKey: apiKey),
            model: TechnicalIndicatorDTO.self
        )

        let (short, long) = try await (shortDTO, longDTO)
        return TechnicalIndicatorMapper.mapEMA(
            ticker: ticker,
            shortDTO: short,
            longDTO: long,
            shortPeriod: shortPeriod,
            longPeriod: longPeriod
        )
    }

    private func evaluateRSI(
        ticker: String,
        period: Int,
        oversoldThreshold: Double,
        overboughtThreshold: Double
    ) async throws -> StrategySignal {
        let dto = try await networkService.request(
            router: FinnhubIndicatorRouter.rsi(symbol: ticker, period: period, apiKey: apiKey),
            model: TechnicalIndicatorDTO.self
        )
        return TechnicalIndicatorMapper.mapRSI(
            ticker: ticker,
            dto: dto,
            period: period,
            oversoldThreshold: oversoldThreshold,
            overboughtThreshold: overboughtThreshold
        )
    }
}

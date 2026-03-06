//
//  EvaluateStrategyUseCase.swift
//  StockWatch
//

/// 전략 즉시 평가 UseCase 구현체
/// Finnhub API를 통해 기술 지표를 조회하고 매수/매도/중립 신호를 반환한다.
final class EvaluateStrategyUseCase: EvaluateStrategyUseCaseProtocol {

    private let repository: StrategyEvaluationRepositoryProtocol

    init(repository: StrategyEvaluationRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String, parameters: StrategyParameters) async throws -> StrategySignal {
        try await repository.evaluate(ticker: ticker, parameters: parameters)
    }
}

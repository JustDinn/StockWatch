//
//  EvaluateStrategyUseCase.swift
//  StockWatch
//

/// 전략 즉시 평가 UseCase 구현체
/// Yahoo Finance API로 과거 종가 데이터를 조회하고 로컬에서 기술 지표를 계산하여 매수/매도/중립 신호를 반환한다.
final class EvaluateStrategyUseCase: EvaluateStrategyUseCaseProtocol {

    private let repository: StrategyEvaluationRepositoryProtocol

    init(repository: StrategyEvaluationRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String, parameters: StrategyParameters) async throws -> StrategySignal {
        try await repository.evaluate(ticker: ticker, parameters: parameters)
    }
}

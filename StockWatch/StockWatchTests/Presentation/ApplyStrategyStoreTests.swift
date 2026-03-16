//
//  ApplyStrategyStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockEvaluateStrategyUseCase: EvaluateStrategyUseCaseProtocol {
    var stubbedResult: StrategySignal?
    var stubbedError: Error?

    func execute(ticker: String, parameters: StrategyParameters) async throws -> StrategySignal {
        if let error = stubbedError { throw error }
        guard let result = stubbedResult else {
            fatalError("MockEvaluateStrategyUseCase: stubbedResult가 설정되지 않았습니다.")
        }
        return result
    }
}

final class MockSaveStockConditionUseCase: SaveStockConditionUseCaseProtocol {
    var stubbedError: Error?

    func execute(condition: StockCondition) async throws {
        if let error = stubbedError { throw error }
    }
}

final class MockRegisterAlertUseCase: RegisterAlertUseCaseProtocol {
    var stubbedError: Error?

    func register(condition: StockCondition, fcmToken: String) async throws {
        if let error = stubbedError { throw error }
    }

    func unregister(conditionId: String) async throws {
        if let error = stubbedError { throw error }
    }
}

// MARK: - Tests

@MainActor
final class ApplyStrategyStoreTests: XCTestCase {

    private var sut: ApplyStrategyStore!
    private var mockFetchStrategiesUseCase: MockFetchStrategiesUseCase!
    private var mockEvaluateUseCase: MockEvaluateStrategyUseCase!
    private var mockSaveUseCase: MockSaveStockConditionUseCase!
    private var mockRegisterAlertUseCase: MockRegisterAlertUseCase!

    private let sampleStrategy = Strategy(
        id: "sma_cross",
        name: "SMA 크로스",
        shortName: "SMA",
        description: "설명",
        category: .movingAverage
    )

    private let sampleSignal = StrategySignal(
        strategyId: "sma_cross",
        ticker: "AAPL",
        signalType: .buy,
        description: "골든크로스 (매수 신호)",
        evaluatedAt: Date()
    )

    override func setUp() {
        super.setUp()
        mockFetchStrategiesUseCase = MockFetchStrategiesUseCase()
        mockEvaluateUseCase = MockEvaluateStrategyUseCase()
        mockSaveUseCase = MockSaveStockConditionUseCase()
        mockRegisterAlertUseCase = MockRegisterAlertUseCase()

        sut = ApplyStrategyStore(
            ticker: "AAPL",
            fetchStrategiesUseCase: mockFetchStrategiesUseCase,
            evaluateStrategyUseCase: mockEvaluateUseCase,
            saveStockConditionUseCase: mockSaveUseCase,
            registerAlertUseCase: mockRegisterAlertUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchStrategiesUseCase = nil
        mockEvaluateUseCase = nil
        mockSaveUseCase = nil
        mockRegisterAlertUseCase = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_signalIsNil() {
        XCTAssertNil(sut.state.signal)
        XCTAssertFalse(sut.state.isEvaluating)
    }

    // MARK: - Evaluate Action

    func test_action_evaluate_withSuccess_setsSignal() async {
        // Arrange
        sut.action(.selectStrategy(sampleStrategy))
        mockEvaluateUseCase.stubbedResult = sampleSignal

        // Act
        sut.action(.evaluate)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertNotNil(sut.state.signal)
        XCTAssertEqual(sut.state.signal?.signalType, .buy)
        XCTAssertFalse(sut.state.isEvaluating)
    }

    func test_action_evaluate_whenUseCaseFails_setsErrorMessage() async {
        // Arrange
        sut.action(.selectStrategy(sampleStrategy))
        mockEvaluateUseCase.stubbedError = NetworkError.networkDisconnected

        // Act
        sut.action(.evaluate)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertNotNil(sut.state.errorMessage)
        XCTAssertNil(sut.state.signal)
        XCTAssertFalse(sut.state.isEvaluating)
    }

    // MARK: - Signal Clearing

    func test_action_updateShortPeriod_clearsSignal() async {
        // Arrange: 먼저 신호 세팅
        sut.action(.selectStrategy(sampleStrategy))
        mockEvaluateUseCase.stubbedResult = sampleSignal
        sut.action(.evaluate)
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(sut.state.signal)

        // Act
        sut.action(.updateShortPeriod(25))

        // Assert
        XCTAssertNil(sut.state.signal)
    }

    func test_action_deselectStrategy_clearsSignal() async {
        // Arrange
        sut.action(.selectStrategy(sampleStrategy))
        mockEvaluateUseCase.stubbedResult = sampleSignal
        sut.action(.evaluate)
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(sut.state.signal)

        // Act
        sut.action(.deselectStrategy)

        // Assert
        XCTAssertNil(sut.state.signal)
    }
}

//
//  StrategyDetailStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockToggleSavedStrategyUseCase: ToggleSavedStrategyUseCaseProtocol {
    var stubbedResult: Bool = false
    var stubbedError: Error?
    private(set) var executeCallCount = 0
    private(set) var lastReceivedStrategyId: String?

    func execute(strategyId: String) async throws -> Bool {
        executeCallCount += 1
        lastReceivedStrategyId = strategyId
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

final class MockCheckSavedStrategyUseCase: CheckSavedStrategyUseCaseProtocol {
    var stubbedResult: Bool = false
    private(set) var executeCallCount = 0
    private(set) var lastReceivedStrategyId: String?

    func execute(strategyId: String) async -> Bool {
        executeCallCount += 1
        lastReceivedStrategyId = strategyId
        return stubbedResult
    }
}

// MARK: - Tests

@MainActor
final class StrategyDetailStoreTests: XCTestCase {

    private var sut: StrategyDetailStore!
    private var mockToggleUseCase: MockToggleSavedStrategyUseCase!
    private var mockCheckUseCase: MockCheckSavedStrategyUseCase!

    private let sampleStrategy = Strategy(
        id: "sma_cross",
        name: "SMA 크로스",
        shortName: "SMA",
        description: "설명",
        category: .movingAverage
    )

    override func setUp() {
        super.setUp()
        mockToggleUseCase = MockToggleSavedStrategyUseCase()
        mockCheckUseCase = MockCheckSavedStrategyUseCase()
        sut = StrategyDetailStore(
            strategy: sampleStrategy,
            toggleSavedStrategyUseCase: mockToggleUseCase,
            checkSavedStrategyUseCase: mockCheckUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockToggleUseCase = nil
        mockCheckUseCase = nil
        super.tearDown()
    }

    // 초기 상태 검증
    func test_initialState_isCorrect() {
        XCTAssertEqual(sut.state.strategy, sampleStrategy)
        XCTAssertFalse(sut.state.isSaved)
        XCTAssertFalse(sut.state.isLoading)
    }

    // loadSavedStatus → 저장 상태 로드
    func test_action_loadSavedStatus_checksSavedStatus() async {
        // Given
        mockCheckUseCase.stubbedResult = true

        // When
        sut.action(.loadSavedStatus)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockCheckUseCase.executeCallCount, 1)
        XCTAssertEqual(mockCheckUseCase.lastReceivedStrategyId, "sma_cross")
        XCTAssertTrue(sut.state.isSaved)
    }

    // 미저장 전략 토글 → isSaved가 true로 변경
    func test_action_toggleSaved_whenNotSaved_updatesStateToTrue() async {
        // Given
        mockToggleUseCase.stubbedResult = true
        XCTAssertFalse(sut.state.isSaved)

        // When
        sut.action(.toggleSaved)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.state.isSaved)
        XCTAssertEqual(mockToggleUseCase.executeCallCount, 1)
        XCTAssertEqual(mockToggleUseCase.lastReceivedStrategyId, "sma_cross")
    }

    // 저장된 전략 토글 → isSaved가 false로 변경
    func test_action_toggleSaved_whenSaved_updatesStateToFalse() async {
        // Given: 먼저 저장 상태로 만들기
        mockCheckUseCase.stubbedResult = true
        sut.action(.loadSavedStatus)
        try? await Task.sleep(nanoseconds: 100_000_000)
        mockToggleUseCase.stubbedResult = false

        // When
        sut.action(.toggleSaved)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.state.isSaved)
        XCTAssertEqual(mockToggleUseCase.executeCallCount, 1)
    }

    // UseCase 에러 시 상태 롤백
    func test_action_toggleSaved_whenUseCaseFails_revertsState() async {
        // Given
        mockToggleUseCase.stubbedError = NSError(domain: "TestError", code: 1)

        // When
        sut.action(.toggleSaved)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: 낙관적 업데이트가 롤백되어 원래 false로 복구
        XCTAssertFalse(sut.state.isSaved)
    }
}

//
//  StrategyStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockFetchStrategiesUseCase: FetchStrategiesUseCaseProtocol {
    var stubbedResult: [Strategy] = []

    func execute() async -> [Strategy] {
        stubbedResult
    }
}

final class MockFetchSavedStrategyIdsUseCase: FetchSavedStrategyIdsUseCaseProtocol {
    var stubbedResult: [String] = []

    func execute() async -> [String] {
        stubbedResult
    }
}

// MARK: - Tests

@MainActor
final class StrategyStoreTests: XCTestCase {

    private var sut: StrategyStore!
    private var mockFetchUseCase: MockFetchStrategiesUseCase!
    private var mockFetchSavedIdsUseCase: MockFetchSavedStrategyIdsUseCase!

    private let sampleStrategies = [
        Strategy(id: "sma_cross", name: "SMA 크로스", shortName: "SMA", description: "설명", category: .movingAverage),
        Strategy(id: "ema_cross", name: "EMA 크로스", shortName: "EMA", description: "설명", category: .movingAverage),
        Strategy(id: "rsi", name: "RSI", shortName: "RSI", description: "설명", category: .oscillator)
    ]

    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchStrategiesUseCase()
        mockFetchSavedIdsUseCase = MockFetchSavedStrategyIdsUseCase()
        sut = StrategyStore(
            fetchStrategiesUseCase: mockFetchUseCase,
            fetchSavedStrategyIdsUseCase: mockFetchSavedIdsUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchUseCase = nil
        mockFetchSavedIdsUseCase = nil
        super.tearDown()
    }

    // 초기 상태 검증
    func test_initialState_isCorrect() {
        XCTAssertTrue(sut.state.allStrategies.isEmpty)
        XCTAssertTrue(sut.state.savedStrategyIds.isEmpty)
        XCTAssertEqual(sut.state.selectedSegment, .all)
        XCTAssertNil(sut.state.selectedStrategy)
        XCTAssertFalse(sut.state.isLoading)
    }

    // loadStrategies → 전략 목록 및 저장 ID 로드
    func test_action_loadStrategies_loadsDataCorrectly() async {
        // Given
        mockFetchUseCase.stubbedResult = sampleStrategies
        mockFetchSavedIdsUseCase.stubbedResult = ["sma_cross"]

        // When
        sut.action(.loadStrategies)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.state.allStrategies, sampleStrategies)
        XCTAssertEqual(sut.state.savedStrategyIds, Set(["sma_cross"]))
        XCTAssertFalse(sut.state.isLoading)
    }

    // 세그먼트 전환
    func test_action_selectSegment_updatesSegment() {
        // When
        sut.action(.selectSegment(.saved))

        // Then
        XCTAssertEqual(sut.state.selectedSegment, .saved)
    }

    // 전략 선택
    func test_action_selectStrategy_updatesSelectedStrategy() {
        // Given
        let strategy = sampleStrategies[0]

        // When
        sut.action(.selectStrategy(strategy))

        // Then
        XCTAssertEqual(sut.state.selectedStrategy, strategy)
    }

    // "전체" 세그먼트 → 전체 전략 표시
    func test_displayedStrategies_allSegment_returnsAllStrategies() async {
        // Given
        mockFetchUseCase.stubbedResult = sampleStrategies
        mockFetchSavedIdsUseCase.stubbedResult = ["sma_cross"]
        sut.action(.loadStrategies)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.action(.selectSegment(.all))

        // Then
        XCTAssertEqual(sut.state.displayedStrategies.count, 3)
    }

    // "저장됨" 세그먼트 → 저장된 전략만 표시
    func test_displayedStrategies_savedSegment_returnsOnlySavedStrategies() async {
        // Given
        mockFetchUseCase.stubbedResult = sampleStrategies
        mockFetchSavedIdsUseCase.stubbedResult = ["sma_cross"]
        sut.action(.loadStrategies)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.action(.selectSegment(.saved))

        // Then
        XCTAssertEqual(sut.state.displayedStrategies.count, 1)
        XCTAssertEqual(sut.state.displayedStrategies.first?.id, "sma_cross")
    }
}

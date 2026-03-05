//
//  FetchStrategiesUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockStrategyRepository: StrategyRepositoryProtocol {
    var stubbedStrategies: [Strategy] = []

    func fetchAllStrategies() async -> [Strategy] {
        stubbedStrategies
    }
}

// MARK: - Tests

final class FetchStrategiesUseCaseTests: XCTestCase {

    private var sut: FetchStrategiesUseCase!
    private var mockRepository: MockStrategyRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockStrategyRepository()
        sut = FetchStrategiesUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 전략 목록 반환 확인
    func test_execute_returnsAllStrategies() async {
        // Given
        let strategies = [
            Strategy(id: "sma_cross", name: "SMA 크로스", shortName: "SMA", description: "설명", category: .movingAverage),
            Strategy(id: "rsi", name: "RSI", shortName: "RSI", description: "설명", category: .oscillator)
        ]
        mockRepository.stubbedStrategies = strategies

        // When
        let result = await sut.execute()

        // Then
        XCTAssertEqual(result, strategies)
    }

    // 빈 목록 반환 확인
    func test_execute_whenEmpty_returnsEmptyArray() async {
        // Given
        mockRepository.stubbedStrategies = []

        // When
        let result = await sut.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
    }
}

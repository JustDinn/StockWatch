//
//  CheckSavedStrategyUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Tests

final class CheckSavedStrategyUseCaseTests: XCTestCase {

    private var sut: CheckSavedStrategyUseCase!
    private var mockRepository: MockSavedStrategyRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockSavedStrategyRepository()
        sut = CheckSavedStrategyUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 저장된 전략이면 true 반환
    func test_execute_whenSaved_returnsTrue() async {
        // Given
        mockRepository.stubbedIsSaved = true

        // When
        let result = await sut.execute(strategyId: "sma_cross")

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockRepository.isSavedCallCount, 1)
        XCTAssertEqual(mockRepository.lastReceivedStrategyId, "sma_cross")
    }

    // 미저장 전략이면 false 반환
    func test_execute_whenNotSaved_returnsFalse() async {
        // Given
        mockRepository.stubbedIsSaved = false

        // When
        let result = await sut.execute(strategyId: "rsi")

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockRepository.isSavedCallCount, 1)
        XCTAssertEqual(mockRepository.lastReceivedStrategyId, "rsi")
    }
}

//
//  FetchSavedStrategyIdsUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Tests

final class FetchSavedStrategyIdsUseCaseTests: XCTestCase {

    private var sut: FetchSavedStrategyIdsUseCase!
    private var mockRepository: MockSavedStrategyRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockSavedStrategyRepository()
        sut = FetchSavedStrategyIdsUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 저장된 ID 목록 반환 확인
    func test_execute_returnsSavedIds() async {
        // Given
        mockRepository.stubbedSavedIds = ["sma_cross", "rsi"]

        // When
        let result = await sut.execute()

        // Then
        XCTAssertEqual(result, ["sma_cross", "rsi"])
    }

    // 빈 목록 반환 확인
    func test_execute_whenEmpty_returnsEmptyArray() async {
        // Given
        mockRepository.stubbedSavedIds = []

        // When
        let result = await sut.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
    }
}

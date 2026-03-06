//
//  CheckFavoriteUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Tests

final class CheckFavoriteUseCaseTests: XCTestCase {

    private var sut: CheckFavoriteUseCase!
    private var mockRepository: MockFavoriteRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockFavoriteRepository()
        sut = CheckFavoriteUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 저장된 종목이면 true 반환
    func test_execute_whenFavoriteExists_returnsTrue() async {
        // Given
        mockRepository.stubbedIsFavorite = true

        // When
        let result = await sut.execute(ticker: "AAPL")

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockRepository.isFavoriteCallCount, 1)
        XCTAssertEqual(mockRepository.lastReceivedTicker, "AAPL")
    }

    // 미저장 종목이면 false 반환
    func test_execute_whenFavoriteNotExists_returnsFalse() async {
        // Given
        mockRepository.stubbedIsFavorite = false

        // When
        let result = await sut.execute(ticker: "TSLA")

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockRepository.isFavoriteCallCount, 1)
        XCTAssertEqual(mockRepository.lastReceivedTicker, "TSLA")
    }
}

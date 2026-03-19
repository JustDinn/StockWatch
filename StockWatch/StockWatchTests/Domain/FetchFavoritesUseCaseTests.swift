//
//  FetchFavoritesUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class FetchFavoritesUseCaseTests: XCTestCase {

    private var sut: FetchFavoritesUseCase!
    private var mockRepository: MockFavoriteRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockFavoriteRepository()
        sut = FetchFavoritesUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // Repository의 FavoriteItem 목록을 그대로 반환한다
    func test_execute_returnsFavoriteItems() async {
        // Given
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date()),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla, Inc.", addedAt: Date())
        ]
        mockRepository.stubbedFavorites = items

        // When
        let result = await sut.execute()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].ticker, "AAPL")
        XCTAssertEqual(result[0].companyName, "Apple Inc.")
        XCTAssertEqual(result[1].ticker, "TSLA")
    }

    // 빈 Repository → 빈 배열 반환
    func test_execute_emptyRepository_returnsEmpty() async {
        // Given
        mockRepository.stubbedFavorites = []

        // When
        let result = await sut.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
    }
}

//
//  WatchListStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockFetchFavoritesUseCase: FetchFavoritesUseCaseProtocol {
    var stubbedResult: [String] = []
    func execute() async -> [String] { stubbedResult }
}

final class MockToggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol {
    var stubbedResult: Bool = true
    var stubbedError: Error?
    func execute(ticker: String) async throws -> Bool {
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

// MARK: - Tests

@MainActor
final class WatchListStoreTests: XCTestCase {

    private var sut: WatchListStore!
    private var mockFetchUseCase: MockFetchFavoritesUseCase!
    private var mockToggleUseCase: MockToggleFavoriteUseCase!

    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchFavoritesUseCase()
        mockToggleUseCase = MockToggleFavoriteUseCase()
        sut = WatchListStore(
            fetchFavoritesUseCase: mockFetchUseCase,
            toggleFavoriteUseCase: mockToggleUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchUseCase = nil
        mockToggleUseCase = nil
        super.tearDown()
    }

    // MARK: - selectTicker

    func test_action_selectTicker_updatesSelectedTicker() {
        // Arrange
        let ticker = "AAPL"

        // Act
        sut.action(.selectTicker(ticker))

        // Assert
        XCTAssertEqual(sut.state.selectedTicker, ticker)
    }

    func test_action_selectTicker_differentTickers_updatesCorrectly() {
        // Arrange & Act
        sut.action(.selectTicker("AAPL"))
        XCTAssertEqual(sut.state.selectedTicker, "AAPL")

        sut.action(.selectTicker("GOOGL"))
        XCTAssertEqual(sut.state.selectedTicker, "GOOGL")
    }

    // MARK: - selectedTickerBinding

    func test_selectedTickerBinding_get_returnsCurrentSelectedTicker() {
        // Arrange
        sut.action(.selectTicker("TSLA"))

        // Act
        let binding = sut.selectedTickerBinding

        // Assert
        XCTAssertEqual(binding.wrappedValue, "TSLA")
    }

    func test_selectedTickerBinding_setNil_resetsSelectedTicker() {
        // Arrange
        sut.action(.selectTicker("AAPL"))
        XCTAssertNotNil(sut.state.selectedTicker)

        // Act
        sut.selectedTickerBinding.wrappedValue = nil

        // Assert
        XCTAssertNil(sut.state.selectedTicker)
    }

    func test_selectedTickerBinding_initialValue_isNil() {
        // Assert
        XCTAssertNil(sut.selectedTickerBinding.wrappedValue)
    }
}

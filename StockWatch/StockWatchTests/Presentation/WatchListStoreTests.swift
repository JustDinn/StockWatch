//
//  WatchListStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockFetchFavoritesUseCase: FetchFavoritesUseCaseProtocol {
    var stubbedResult: [FavoriteItem] = []
    func execute() async -> [FavoriteItem] { stubbedResult }
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

    // MARK: - loadFavorites

    func test_action_loadFavorites_updatesFavorites() async {
        // Arrange
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date()),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla, Inc.", addedAt: Date())
        ]
        mockFetchUseCase.stubbedResult = items

        // Act
        sut.action(.loadFavorites)
        await Task.yield()

        // Assert
        XCTAssertEqual(sut.state.favorites.count, 2)
        XCTAssertEqual(sut.state.favorites[0].ticker, "AAPL")
        XCTAssertEqual(sut.state.favorites[1].ticker, "TSLA")
    }

    // MARK: - removeFavorite

    func test_action_removeFavorite_removesOptimistically() async {
        // Arrange
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date()),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla, Inc.", addedAt: Date())
        ]
        sut = WatchListStore(
            fetchFavoritesUseCase: mockFetchUseCase,
            toggleFavoriteUseCase: mockToggleUseCase,
            state: WatchListState(favorites: items)
        )
        mockToggleUseCase.stubbedResult = false

        // Act
        sut.action(.removeFavorite(ticker: "AAPL"))

        // Assert (낙관적 즉시 제거)
        XCTAssertEqual(sut.state.favorites.count, 1)
        XCTAssertEqual(sut.state.favorites[0].ticker, "TSLA")
    }

    func test_action_removeFavorite_rollsBackOnError() async {
        // Arrange
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date())
        ]
        sut = WatchListStore(
            fetchFavoritesUseCase: mockFetchUseCase,
            toggleFavoriteUseCase: mockToggleUseCase,
            state: WatchListState(favorites: items)
        )
        mockToggleUseCase.stubbedError = NSError(domain: "TestError", code: 1)

        // Act
        sut.action(.removeFavorite(ticker: "AAPL"))
        await Task.yield()

        // Assert (에러 시 롤백)
        XCTAssertEqual(sut.state.favorites.count, 1)
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

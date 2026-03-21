//
//  AddStockToGroupStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockTickerUseCase: TickerUseCaseProtocol {
    var stubbedResult: [SearchResult] = []
    var stubbedError: Error?

    func search(query: String) async throws -> [SearchResult] {
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

final class MockFetchStockLogoUseCase: FetchStockLogoUseCaseProtocol {
    var stubbedURLs: [String: String] = [:]
    var stubbedError: Error?

    func execute(ticker: String) async throws -> String {
        if let error = stubbedError { throw error }
        return stubbedURLs[ticker] ?? ""
    }
}

// MARK: - Tests

@MainActor
final class AddStockToGroupStoreTests: XCTestCase {

    private var sut: AddStockToGroupStore!
    private var mockTickerUseCase: MockTickerUseCase!
    private var mockLogoUseCase: MockFetchStockLogoUseCase!

    override func setUp() {
        super.setUp()
        mockTickerUseCase = MockTickerUseCase()
        mockLogoUseCase = MockFetchStockLogoUseCase()
        sut = AddStockToGroupStore(
            tickerUseCase: mockTickerUseCase,
            fetchLogoUseCase: mockLogoUseCase,
            onConfirm: { _ in }
        )
    }

    override func tearDown() {
        sut = nil
        mockTickerUseCase = nil
        mockLogoUseCase = nil
        super.tearDown()
    }

    // 검색 후 logoURLs가 ticker별로 업데이트되는지 검증
    func test_action_search_updatesLogoURLsForResults() async {
        // Arrange
        mockTickerUseCase.stubbedResult = [
            SearchResult(description: "Apple Inc", displayTicker: "AAPL", ticker: "AAPL", type: "EQUITY"),
            SearchResult(description: "Microsoft Corp", displayTicker: "MSFT", ticker: "MSFT", type: "EQUITY")
        ]
        mockLogoUseCase.stubbedURLs = [
            "AAPL": "https://logo.url/aapl.png",
            "MSFT": "https://logo.url/msft.png"
        ]

        // Act
        sut.action(.search("apple"))
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Assert
        XCTAssertEqual(sut.state.logoURLs["AAPL"], "https://logo.url/aapl.png")
        XCTAssertEqual(sut.state.logoURLs["MSFT"], "https://logo.url/msft.png")
    }

    // 로고 fetch 실패 시 searchResults는 정상 표시, logoURLs에 해당 키 없음
    func test_action_search_whenLogoFetchFails_searchResultsStillDisplayed() async {
        // Arrange
        mockTickerUseCase.stubbedResult = [
            SearchResult(description: "Apple Inc", displayTicker: "AAPL", ticker: "AAPL", type: "EQUITY")
        ]
        mockLogoUseCase.stubbedError = NetworkError.serverError

        // Act
        sut.action(.search("apple"))
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Assert
        XCTAssertEqual(sut.state.searchResults.count, 1)
        XCTAssertNil(sut.state.logoURLs["AAPL"], "로고 fetch 실패 시 logoURLs에 저장되지 않아야 한다")
    }

    // logoURLFetched intent로 State의 logoURLs가 업데이트되는지 검증
    func test_action_logoURLFetched_updatesState() {
        // Act
        sut.action(.logoURLFetched(ticker: "AAPL", url: "https://logo.url/aapl.png"))

        // Assert
        XCTAssertEqual(sut.state.logoURLs["AAPL"], "https://logo.url/aapl.png")
    }

    // toggleSelection - 종목 선택/해제 정상 동작 (회귀 테스트)
    func test_action_toggleSelection_addsAndRemovesStock() {
        // Arrange
        let stock = SearchResult(description: "Apple Inc", displayTicker: "AAPL", ticker: "AAPL", type: "EQUITY")

        // Act: 선택
        sut.action(.toggleSelection(stock))
        XCTAssertTrue(sut.state.selectedStocks.contains(stock))

        // Act: 해제
        sut.action(.toggleSelection(stock))
        XCTAssertFalse(sut.state.selectedStocks.contains(stock))
    }

    // confirmSelection - 콜백으로 선택된 종목 전달
    func test_action_confirmSelection_invokesCallbackWithSelectedStocks() {
        // Arrange
        let stock = SearchResult(description: "Apple Inc", displayTicker: "AAPL", ticker: "AAPL", type: "EQUITY")
        var confirmedStocks: [SearchResult] = []
        sut = AddStockToGroupStore(
            tickerUseCase: mockTickerUseCase,
            fetchLogoUseCase: mockLogoUseCase,
            onConfirm: { confirmedStocks = $0 }
        )
        sut.action(.toggleSelection(stock))

        // Act
        sut.action(.confirmSelection)

        // Assert
        XCTAssertEqual(confirmedStocks.count, 1)
        XCTAssertEqual(confirmedStocks.first?.ticker, "AAPL")
    }
}

//
//  FetchStockQuoteUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockStockQuoteRepository: StockQuoteRepositoryProtocol {
    var stubbedResult: StockQuote = StockQuote(ticker: "AAPL", currentPrice: 150.0, priceChangePercent: 1.5, currency: "USD")
    var stubbedError: Error?
    var lastReceivedTicker: String?

    func fetchStockQuote(ticker: String) async throws -> StockQuote {
        lastReceivedTicker = ticker
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

// MARK: - Tests

final class FetchStockQuoteUseCaseTests: XCTestCase {

    private var sut: FetchStockQuoteUseCase!
    private var mockRepository: MockStockQuoteRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockStockQuoteRepository()
        sut = FetchStockQuoteUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 정상 케이스: 유효한 ticker로 StockQuote를 반환하는지 검증
    func test_execute_withValidTicker_returnsStockQuote() async throws {
        // Arrange
        let expected = StockQuote(ticker: "AAPL", currentPrice: 150.0, priceChangePercent: 1.5, currency: "USD")
        mockRepository.stubbedResult = expected

        // Act
        let result = try await sut.execute(ticker: "AAPL")

        // Assert
        XCTAssertEqual(result, expected)
        XCTAssertEqual(mockRepository.lastReceivedTicker, "AAPL")
    }

    // 빈 ticker 케이스: Repository를 호출하지 않고 emptyTicker 에러를 던지는지 검증
    func test_execute_withEmptyTicker_throwsEmptyTickerError() async {
        // Act / Assert
        do {
            _ = try await sut.execute(ticker: "")
            XCTFail("emptyTicker 에러가 발생해야 한다")
        } catch FetchStockQuoteError.emptyTicker {
            XCTAssertNil(mockRepository.lastReceivedTicker, "빈 ticker 시 Repository를 호출하지 않아야 한다")
        } catch {
            XCTFail("FetchStockQuoteError.emptyTicker가 발생해야 한다, 실제: \(error)")
        }
    }

    // 에러 전파 케이스: Repository 에러가 올바르게 전파되는지 검증
    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Arrange
        mockRepository.stubbedError = NetworkError.serverError

        // Act / Assert
        do {
            _ = try await sut.execute(ticker: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

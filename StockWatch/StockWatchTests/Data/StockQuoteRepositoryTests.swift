//
//  StockQuoteRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class StockQuoteRepositoryTests: XCTestCase {

    private var sut: StockQuoteRepository!
    private var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = StockQuoteRepository(networkService: mockNetworkService)
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // 정상 케이스: quote 응답을 StockQuote 엔티티로 올바르게 변환하는지 검증
    func test_fetchStockQuote_withValidResponse_returnsMappedEntity() async throws {
        // Given
        let quoteDTO = YahooFinanceQuoteDTO(
            chart: .init(
                result: [
                    .init(meta: .init(
                        symbol: "AAPL",
                        regularMarketPrice: 150.0,
                        previousClose: 148.0,
                        regularMarketChangePercent: 1.35,
                        chartPreviousClose: nil,
                        shortName: nil,
                        longName: nil,
                        currency: "USD"
                    ))
                ],
                error: nil
            )
        )
        mockNetworkService.stubbedResult = quoteDTO

        // When
        let result = try await sut.fetchStockQuote(ticker: "AAPL")

        // Then
        XCTAssertEqual(result.ticker, "AAPL")
        XCTAssertEqual(result.currentPrice, 150.0)
        XCTAssertEqual(result.priceChangePercent, 1.35)
        XCTAssertEqual(result.currency, "USD")
    }

    // 네트워크 실패 시 에러 전파
    func test_fetchStockQuote_whenNetworkFails_throwsError() async {
        // Given
        mockNetworkService.stubbedError = NetworkError.networkDisconnected

        // When / Then
        do {
            _ = try await sut.fetchStockQuote(ticker: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

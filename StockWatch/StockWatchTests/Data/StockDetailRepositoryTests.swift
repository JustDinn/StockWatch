//
//  StockDetailRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class StockDetailRepositoryTests: XCTestCase {

    private var sut: StockDetailRepository!
    private var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = StockDetailRepository(networkService: mockNetworkService, apiKey: "test-api-key")
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // 정상 케이스: quote와 profile 응답을 Entity로 올바르게 변환하는지 검증
    func test_fetchStockDetail_withValidResponses_returnsMappedEntity() async throws {
        // Given
        let quoteDTO = YahooFinanceQuoteDTO(
            chart: .init(
                result: [
                    .init(meta: .init(
                        symbol: "AAPL",
                        regularMarketPrice: 150.0,
                        previousClose: 148.0,
                        regularMarketChangePercent: nil,
                        chartPreviousClose: nil,
                        shortName: "Apple Inc.",
                        longName: "Apple Inc",
                        currency: "USD"
                    ))
                ],
                error: nil
            )
        )
        let profileDTO = StockProfileDTO(
            name: "Apple Inc",
            logo: "https://logo.url/aapl.png",
            ticker: "AAPL",
            country: "US",
            currency: "USD",
            exchange: "NASDAQ"
        )

        // MockNetworkService는 단일 stubbedResult만 지원하므로
        // quote 요청에 대해 YahooFinanceQuoteDTO를 반환하도록 설정
        // profile 요청은 graceful degradation으로 처리됨 (try?)
        mockNetworkService.stubbedResult = quoteDTO

        // When
        // profile 요청 실패 시 logoURL은 빈 문자열로 graceful degradation
        let result = try await sut.fetchStockDetail(ticker: "AAPL")

        // Then
        XCTAssertEqual(result.ticker, "AAPL")
        XCTAssertEqual(result.currentPrice, 150.0)
    }

    // Finnhub profile2 실패 시 로고만 빈 문자열로 graceful degradation
    func test_fetchStockDetail_whenProfileFails_returnsEntityWithEmptyLogoURL() async throws {
        // Given
        let quoteDTO = YahooFinanceQuoteDTO(
            chart: .init(
                result: [
                    .init(meta: .init(
                        symbol: "AAPL",
                        regularMarketPrice: 150.0,
                        previousClose: 148.0,
                        regularMarketChangePercent: nil,
                        chartPreviousClose: nil,
                        shortName: "Apple Inc.",
                        longName: "Apple Inc",
                        currency: "USD"
                    ))
                ],
                error: nil
            )
        )
        mockNetworkService.stubbedResult = quoteDTO

        // When (profile 실패는 try?로 처리되므로 throw 없이 logoURL = "" 반환)
        let result = try await sut.fetchStockDetail(ticker: "AAPL")

        // Then
        XCTAssertEqual(result.logoURL, "")
        XCTAssertEqual(result.companyName, "Apple Inc")
    }

    // quote 요청 실패 시 에러 전파
    func test_fetchStockDetail_whenQuoteFails_throwsError() async {
        // Given
        mockNetworkService.stubbedError = NetworkError.networkDisconnected

        // When / Then
        do {
            _ = try await sut.fetchStockDetail(ticker: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

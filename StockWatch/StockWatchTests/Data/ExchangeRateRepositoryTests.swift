//
//  ExchangeRateRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class ExchangeRateRepositoryTests: XCTestCase {

    private var sut: ExchangeRateRepository!
    private var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = ExchangeRateRepository(networkService: mockNetworkService)
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    private func makeQuoteDTO(price: Double) -> YahooFinanceQuoteDTO {
        YahooFinanceQuoteDTO(
            chart: .init(
                result: [
                    .init(meta: .init(
                        symbol: "KRW=X",
                        regularMarketPrice: price,
                        previousClose: nil,
                        regularMarketChangePercent: nil,
                        chartPreviousClose: nil,
                        shortName: nil,
                        longName: nil,
                        currency: nil
                    ))
                ],
                error: nil
            )
        )
    }

    // 단일 통화 조회 시 올바른 환율을 반환하는지 검증
    func test_fetchRates_withSingleCurrency_returnsRate() async throws {
        // Given
        mockNetworkService.stubbedResult = makeQuoteDTO(price: 1380.0)

        // When
        let result = try await sut.fetchRates(currencies: ["KRW"])

        // Then
        XCTAssertEqual(result["KRW"], 1380.0)
    }

    // 네트워크 실패 시 에러 전파
    func test_fetchRates_whenNetworkFails_throwsError() async {
        // Given
        mockNetworkService.stubbedError = NetworkError.networkDisconnected

        // When / Then
        do {
            _ = try await sut.fetchRates(currencies: ["KRW"])
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

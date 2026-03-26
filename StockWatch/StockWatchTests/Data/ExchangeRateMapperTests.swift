//
//  ExchangeRateMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class ExchangeRateMapperTests: XCTestCase {

    private func makeQuoteDTO(
        symbol: String = "KRW=X",
        regularMarketPrice: Double? = 1380.0
    ) -> YahooFinanceQuoteDTO {
        YahooFinanceQuoteDTO(
            chart: .init(
                result: [
                    .init(meta: .init(
                        symbol: symbol,
                        regularMarketPrice: regularMarketPrice,
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

    // 정상 케이스: 유효한 DTO에서 환율 값을 올바르게 추출하는지 검증
    func test_map_withValidDTO_returnsCorrectRate() {
        // Given
        let dto = makeQuoteDTO(regularMarketPrice: 1380.0)

        // When
        let rate = YahooFinanceExchangeRateMapper.map(currency: "KRW", dto: dto)

        // Then
        XCTAssertEqual(rate, 1380.0)
    }

    // regularMarketPrice가 nil인 경우 0.0을 반환하는지 검증
    func test_map_withNilPrice_returnsZero() {
        // Given
        let dto = makeQuoteDTO(regularMarketPrice: nil)

        // When
        let rate = YahooFinanceExchangeRateMapper.map(currency: "KRW", dto: dto)

        // Then
        XCTAssertEqual(rate, 0.0)
    }

    // result가 빈 배열인 경우 0.0을 반환하는지 검증
    func test_map_withEmptyResult_returnsZero() {
        // Given
        let dto = YahooFinanceQuoteDTO(chart: .init(result: [], error: nil))

        // When
        let rate = YahooFinanceExchangeRateMapper.map(currency: "KRW", dto: dto)

        // Then
        XCTAssertEqual(rate, 0.0)
    }
}

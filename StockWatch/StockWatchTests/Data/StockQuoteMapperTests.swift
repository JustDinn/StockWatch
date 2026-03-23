//
//  StockQuoteMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class StockQuoteMapperTests: XCTestCase {

    private func makeQuoteDTO(
        symbol: String = "AAPL",
        regularMarketPrice: Double? = 150.0,
        previousClose: Double? = 148.0,
        regularMarketChangePercent: Double? = nil,
        chartPreviousClose: Double? = nil,
        currency: String? = "USD"
    ) -> YahooFinanceQuoteDTO {
        YahooFinanceQuoteDTO(
            chart: .init(
                result: [
                    .init(meta: .init(
                        symbol: symbol,
                        regularMarketPrice: regularMarketPrice,
                        previousClose: previousClose,
                        regularMarketChangePercent: regularMarketChangePercent,
                        chartPreviousClose: chartPreviousClose,
                        shortName: nil,
                        longName: nil,
                        currency: currency
                    ))
                ],
                error: nil
            )
        )
    }

    // 정상 케이스: 유효한 meta 데이터를 StockQuote로 올바르게 변환하는지 검증
    func test_map_withValidMeta_returnsCorrectStockQuote() {
        // Given
        let ticker = "AAPL"
        let quote = makeQuoteDTO(regularMarketPrice: 150.0, previousClose: 148.0)

        // When
        let result = YahooFinanceStockQuoteMapper.map(ticker: ticker, quote: quote)

        // Then
        XCTAssertEqual(result.ticker, ticker)
        XCTAssertEqual(result.currentPrice, 150.0)
        XCTAssertEqual(result.priceChangePercent, ((150.0 - 148.0) / 148.0) * 100, accuracy: 0.0001)
        XCTAssertEqual(result.currency, "USD")
    }

    // API에서 regularMarketChangePercent를 직접 제공하는 경우 해당 값을 사용
    func test_map_withRegularMarketChangePercent_usesApiValue() {
        // Given
        let quote = makeQuoteDTO(
            regularMarketPrice: 150.0,
            previousClose: 148.0,
            regularMarketChangePercent: 2.5
        )

        // When
        let result = YahooFinanceStockQuoteMapper.map(ticker: "AAPL", quote: quote)

        // Then
        XCTAssertEqual(result.priceChangePercent, 2.5)
    }

    // previousClose가 0인 경우 priceChangePercent는 0.0 반환
    func test_map_withZeroPreviousClose_returnsZeroPriceChangePercent() {
        // Given
        let quote = makeQuoteDTO(regularMarketPrice: 100.0, previousClose: 0.0)

        // When
        let result = YahooFinanceStockQuoteMapper.map(ticker: "TEST", quote: quote)

        // Then
        XCTAssertEqual(result.priceChangePercent, 0.0)
    }

    // result가 빈 배열인 경우 기본값(0.0) 반환
    func test_map_withEmptyResult_returnsZeroValues() {
        // Given
        let emptyDTO = YahooFinanceQuoteDTO(chart: .init(result: [], error: nil))

        // When
        let result = YahooFinanceStockQuoteMapper.map(ticker: "AAPL", quote: emptyDTO)

        // Then
        XCTAssertEqual(result.currentPrice, 0.0)
        XCTAssertEqual(result.priceChangePercent, 0.0)
    }
}

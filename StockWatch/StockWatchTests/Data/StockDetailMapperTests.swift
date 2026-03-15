//
//  StockDetailMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class StockDetailMapperTests: XCTestCase {

    private func makeQuoteDTO(
        symbol: String = "AAPL",
        regularMarketPrice: Double? = 150.0,
        previousClose: Double? = 148.0,
        regularMarketChangePercent: Double? = nil,
        chartPreviousClose: Double? = nil,
        shortName: String? = nil,
        longName: String? = nil
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
                        shortName: shortName,
                        longName: longName
                    ))
                ],
                error: nil
            )
        )
    }

    // 정상 케이스: 유효한 meta 데이터를 Entity로 올바르게 변환하는지 검증
    func test_map_withValidMeta_returnsCorrectEntity() {
        // Given
        let ticker = "AAPL"
        let quote = makeQuoteDTO(
            regularMarketPrice: 150.0,
            previousClose: 148.0,
            longName: "Apple Inc"
        )

        // When
        let result = YahooFinanceStockDetailMapper.map(ticker: ticker, quote: quote, logoURL: "https://logo.url/aapl.png")

        // Then
        XCTAssertEqual(result.ticker, ticker)
        XCTAssertEqual(result.companyName, "Apple Inc")
        XCTAssertEqual(result.currentPrice, 150.0)
        XCTAssertEqual(result.priceChangePercent, ((150.0 - 148.0) / 148.0) * 100, accuracy: 0.0001)
        XCTAssertEqual(result.logoURL, "https://logo.url/aapl.png")
    }

    // longName 없이 shortName만 있는 경우 shortName을 companyName으로 사용
    func test_map_withoutLongName_usesShortnameAsCompanyName() {
        // Given
        let ticker = "QQQ"
        let quote = makeQuoteDTO(
            symbol: "QQQ",
            regularMarketPrice: 400.0,
            previousClose: 404.0,
            shortName: "Invesco QQQ Trust"
        )

        // When
        let result = YahooFinanceStockDetailMapper.map(ticker: ticker, quote: quote, logoURL: "")

        // Then
        XCTAssertEqual(result.companyName, "Invesco QQQ Trust")
    }

    // 이름 필드가 모두 없는 경우 ticker를 companyName으로 사용
    func test_map_withNoNameFields_usesTickerAsCompanyName() {
        // Given
        let ticker = "SOXL"
        let quote = makeQuoteDTO(symbol: "SOXL", shortName: nil, longName: nil)

        // When
        let result = YahooFinanceStockDetailMapper.map(ticker: ticker, quote: quote, logoURL: "")

        // Then
        XCTAssertEqual(result.companyName, ticker)
    }

    // previousClose가 0인 경우 priceChangePercent는 0.0 반환
    func test_map_withZeroPreviousClose_returnZeroPriceChangePercent() {
        // Given
        let quote = makeQuoteDTO(regularMarketPrice: 100.0, previousClose: 0.0)

        // When
        let result = YahooFinanceStockDetailMapper.map(ticker: "TEST", quote: quote, logoURL: "")

        // Then
        XCTAssertEqual(result.priceChangePercent, 0.0)
    }
}

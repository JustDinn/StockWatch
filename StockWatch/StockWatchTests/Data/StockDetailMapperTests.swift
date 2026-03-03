//
//  StockDetailMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class StockDetailMapperTests: XCTestCase {

    func test_map_withValidProfile_returnsCorrectEntity() {
        // Given
        let ticker = "AAPL"
        let quote = QuoteResponseDTO(c: 150.0, d: 2.0, dp: 1.35, h: 155.0, l: 145.0, o: 148.0, pc: 148.0)
        let profile = StockProfileDTO(
            name: "Apple Inc",
            logo: "https://logo.url/aapl.png",
            ticker: "AAPL",
            country: "US",
            currency: "USD",
            exchange: "NASDAQ"
        )

        // When
        let result = StockDetailMapper.map(ticker: ticker, quote: quote, profile: profile)

        // Then
        XCTAssertEqual(result.ticker, ticker)
        XCTAssertEqual(result.companyName, "Apple Inc")
        XCTAssertEqual(result.currentPrice, 150.0)
        XCTAssertEqual(result.priceChangePercent, 1.35)
        XCTAssertEqual(result.logoURL, "https://logo.url/aapl.png")
    }

    func test_map_withMissingLogo_returnsEntityWithEmptyLogoURL() {
        // Given
        let ticker = "QQQ"
        let quote = QuoteResponseDTO(c: 400.0, d: -4.0, dp: -1.0, h: 410.0, l: 390.0, o: 405.0, pc: 404.0)
        let profile = StockProfileDTO(
            name: "Invesco QQQ Trust",
            logo: nil,
            ticker: "QQQ",
            country: "US",
            currency: "USD",
            exchange: "NASDAQ"
        )

        // When
        let result = StockDetailMapper.map(ticker: ticker, quote: quote, profile: profile)

        // Then
        XCTAssertEqual(result.ticker, ticker)
        XCTAssertEqual(result.logoURL, "")
    }

    func test_map_withMissingName_returnsTickerAsCompanyName() {
        // Given
        let ticker = "SOXL"
        let quote = QuoteResponseDTO(c: 50.0, d: 2.0, dp: 4.0, h: 55.0, l: 45.0, o: 48.0, pc: 48.0)
        let profile = StockProfileDTO(
            name: nil,
            logo: nil,
            ticker: nil,
            country: nil,
            currency: nil,
            exchange: nil
        )

        // When
        let result = StockDetailMapper.map(ticker: ticker, quote: quote, profile: profile)

        // Then
        XCTAssertEqual(result.ticker, ticker)
        XCTAssertEqual(result.companyName, ticker)
        XCTAssertEqual(result.logoURL, "")
    }
}

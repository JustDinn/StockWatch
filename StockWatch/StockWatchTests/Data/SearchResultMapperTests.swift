//
//  SearchResultMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class SearchResultMapperTests: XCTestCase {

    // longname이 있는 경우 longname을 description으로 사용
    func test_map_withLongname_usesLongnameAsDescription() {
        // Given
        let dto = YahooFinanceSearchItemDTO(
            symbol: "AAPL",
            shortname: "Apple Inc.",
            longname: "Apple Inc",
            quoteType: "EQUITY",
            exchange: "NMS"
        )

        // When
        let result = YahooFinanceSearchResultMapper.map(dto)

        // Then
        XCTAssertEqual(result.description, "Apple Inc")
        XCTAssertEqual(result.displayTicker, "AAPL")
        XCTAssertEqual(result.ticker, "AAPL")
        XCTAssertEqual(result.type, "EQUITY")
    }

    // longname이 없고 shortname이 있는 경우 shortname을 description으로 사용
    func test_map_withoutLongname_usesShortnameAsDescription() {
        // Given
        let dto = YahooFinanceSearchItemDTO(
            symbol: "QQQ",
            shortname: "Invesco QQQ Trust",
            longname: nil,
            quoteType: "ETF",
            exchange: "NMS"
        )

        // When
        let result = YahooFinanceSearchResultMapper.map(dto)

        // Then
        XCTAssertEqual(result.description, "Invesco QQQ Trust")
        XCTAssertEqual(result.type, "ETF")
    }

    // longname, shortname 모두 없는 경우 symbol을 description으로 사용
    func test_map_withoutNameFields_usesSymbolAsDescription() {
        // Given
        let dto = YahooFinanceSearchItemDTO(
            symbol: "SOXL",
            shortname: nil,
            longname: nil,
            quoteType: nil,
            exchange: nil
        )

        // When
        let result = YahooFinanceSearchResultMapper.map(dto)

        // Then
        XCTAssertEqual(result.description, "SOXL")
        XCTAssertEqual(result.ticker, "SOXL")
        XCTAssertEqual(result.type, "")
    }
}

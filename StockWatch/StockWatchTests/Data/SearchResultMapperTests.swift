//
//  SearchResultMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class SearchResultMapperTests: XCTestCase {

    // 정상 변환: DTO를 Entity로 올바르게 변환하는지 검증
    func test_map_withValidDTO_returnsCorrectEntity() {
        // Given
        let dto = TickerSearchItemDTO(
            description: "APPLE INC",
            displayTicker: "AAPL",
            ticker: "AAPL",
            type: "Common Stock"
        )

        // When
        let result = SearchResultMapper.map(dto)

        // Then
        XCTAssertEqual(result.description, "APPLE INC")
        XCTAssertEqual(result.displayTicker, "AAPL")
        XCTAssertEqual(result.ticker, "AAPL")
        XCTAssertEqual(result.type, "Common Stock")
    }


}

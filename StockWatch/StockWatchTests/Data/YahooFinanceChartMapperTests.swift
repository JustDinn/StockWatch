//
//  YahooFinanceChartMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class YahooFinanceChartMapperTests: XCTestCase {

    // 정상 케이스: 유효한 DTO → close 배열 반환
    func test_map_withValidDTO_returnsClosePrices() {
        // Arrange
        let dto = YahooFinanceChartDTO(
            chart: .init(
                result: [
                    .init(indicators: .init(quote: [.init(close: [100.0, 101.5, 102.3])]))
                ],
                error: nil
            )
        )

        // Act
        let closes = YahooFinanceChartMapper.mapToCloses(dto)

        // Assert
        XCTAssertEqual(closes, [100.0, 101.5, 102.3])
    }

    // nil 포함 케이스: nil 값은 compactMap으로 제거
    func test_map_withNullCloses_filtersNils() {
        // Arrange
        let dto = YahooFinanceChartDTO(
            chart: .init(
                result: [
                    .init(indicators: .init(quote: [.init(close: [100.0, nil, 102.3, nil, 104.0])]))
                ],
                error: nil
            )
        )

        // Act
        let closes = YahooFinanceChartMapper.mapToCloses(dto)

        // Assert
        XCTAssertEqual(closes, [100.0, 102.3, 104.0])
    }

    // 빈 result 케이스: result 배열이 비어있으면 [] 반환
    func test_map_withEmptyResult_returnsEmptyArray() {
        // Arrange
        let dto = YahooFinanceChartDTO(
            chart: .init(result: [], error: nil)
        )

        // Act
        let closes = YahooFinanceChartMapper.mapToCloses(dto)

        // Assert
        XCTAssertTrue(closes.isEmpty)
    }

    // nil quote 케이스: quote가 nil이면 [] 반환
    func test_map_withNilQuoteArray_returnsEmptyArray() {
        // Arrange
        let dto = YahooFinanceChartDTO(
            chart: .init(
                result: [
                    .init(indicators: .init(quote: nil))
                ],
                error: nil
            )
        )

        // Act
        let closes = YahooFinanceChartMapper.mapToCloses(dto)

        // Assert
        XCTAssertTrue(closes.isEmpty)
    }
}

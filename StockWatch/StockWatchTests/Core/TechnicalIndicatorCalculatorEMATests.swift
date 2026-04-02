//
//  TechnicalIndicatorCalculatorEMATests.swift
//  StockWatch
//

import XCTest
@testable import StockWatch

final class TechnicalIndicatorCalculatorEMATests: XCTestCase {

    // MARK: - emaTimeSeries Tests

    func testEMATimeSeries_withSufficientData_returnsCorrectValues() {
        // Given: 10개의 캔들, period = 5
        let candles = [
            Candle(timestamp: date(0), open: 10, high: 12, low: 9, close: 10, volume: 1000),
            Candle(timestamp: date(1), open: 11, high: 13, low: 10, close: 11, volume: 1000),
            Candle(timestamp: date(2), open: 12, high: 14, low: 11, close: 12, volume: 1000),
            Candle(timestamp: date(3), open: 13, high: 15, low: 12, close: 13, volume: 1000),
            Candle(timestamp: date(4), open: 14, high: 16, low: 13, close: 14, volume: 1000),
            Candle(timestamp: date(5), open: 15, high: 17, low: 14, close: 15, volume: 1000),
            Candle(timestamp: date(6), open: 16, high: 18, low: 15, close: 16, volume: 1000),
            Candle(timestamp: date(7), open: 17, high: 19, low: 16, close: 17, volume: 1000),
            Candle(timestamp: date(8), open: 18, high: 20, low: 17, close: 18, volume: 1000),
            Candle(timestamp: date(9), open: 19, high: 21, low: 18, close: 19, volume: 1000)
        ]

        // When
        let result = TechnicalIndicatorCalculator.emaTimeSeries(candles: candles, period: 5, priceSource: .close)

        // Then: period=5이므로 첫 EMA는 index 4(5번째 캔들)부터 시작, 총 6개 값
        XCTAssertEqual(result.count, 6, "Should have 6 EMA values (index 4-9)")

        // 첫 번째 EMA는 SMA로 시작 (10+11+12+13+14)/5 = 12
        XCTAssertEqual(result[0].timestamp, date(4))
        XCTAssertEqual(result[0].value, 12.0, accuracy: 0.01)

        // multiplier k = 2/(5+1) = 0.333...
        // EMA[5] = 15 * 0.333 + 12 * 0.667 = 13.0
        XCTAssertEqual(result[1].timestamp, date(5))
        XCTAssertEqual(result[1].value, 13.0, accuracy: 0.01)

        // EMA[6] = 16 * 0.333 + 13 * 0.667 = 13.993...
        XCTAssertEqual(result[2].timestamp, date(6))
        XCTAssertEqual(result[2].value, 13.993, accuracy: 0.01)

        // 마지막 값 검증
        XCTAssertEqual(result[5].timestamp, date(9))
    }

    func testEMATimeSeries_withPeriod1_returnsAllClosePrices() {
        // Given: period = 1이면 EMA는 종가와 동일
        let candles = [
            Candle(timestamp: date(0), open: 10, high: 12, low: 9, close: 100, volume: 1000),
            Candle(timestamp: date(1), open: 11, high: 13, low: 10, close: 200, volume: 1000),
            Candle(timestamp: date(2), open: 12, high: 14, low: 11, close: 300, volume: 1000)
        ]

        // When
        let result = TechnicalIndicatorCalculator.emaTimeSeries(candles: candles, period: 1, priceSource: .close)

        // Then: 모든 값이 종가와 동일해야 함
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].value, 100, accuracy: 0.01)
        XCTAssertEqual(result[1].value, 200, accuracy: 0.01)
        XCTAssertEqual(result[2].value, 300, accuracy: 0.01)
    }

    func testEMATimeSeries_withOpenPriceSource_usesOpenPrices() {
        // Given: 시가 기준 EMA
        let candles = [
            Candle(timestamp: date(0), open: 10, high: 12, low: 9, close: 50, volume: 1000),
            Candle(timestamp: date(1), open: 20, high: 13, low: 10, close: 50, volume: 1000),
            Candle(timestamp: date(2), open: 30, high: 14, low: 11, close: 50, volume: 1000)
        ]

        // When
        let result = TechnicalIndicatorCalculator.emaTimeSeries(candles: candles, period: 2, priceSource: .open)

        // Then: 시가로 계산되어야 함
        // EMA[1] = SMA(10, 20) = 15
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].timestamp, date(1))
        XCTAssertEqual(result[0].value, 15.0, accuracy: 0.01)

        // EMA[2] = 30 * (2/3) + 15 * (1/3) = 25
        XCTAssertEqual(result[1].timestamp, date(2))
        XCTAssertEqual(result[1].value, 25.0, accuracy: 0.01)
    }

    func testEMATimeSeries_withInsufficientData_returnsEmpty() {
        // Given: 2개 캔들, period = 5
        let candles = [
            Candle(timestamp: date(0), open: 10, high: 12, low: 9, close: 10, volume: 1000),
            Candle(timestamp: date(1), open: 11, high: 13, low: 10, close: 11, volume: 1000)
        ]

        // When
        let result = TechnicalIndicatorCalculator.emaTimeSeries(candles: candles, period: 5, priceSource: .close)

        // Then: period보다 적으면 빈 배열
        XCTAssertTrue(result.isEmpty)
    }

    func testEMATimeSeries_withExactPeriodData_returnsOneValue() {
        // Given: 정확히 period개 캔들
        let candles = [
            Candle(timestamp: date(0), open: 10, high: 12, low: 9, close: 10, volume: 1000),
            Candle(timestamp: date(1), open: 11, high: 13, low: 10, close: 20, volume: 1000),
            Candle(timestamp: date(2), open: 12, high: 14, low: 11, close: 30, volume: 1000)
        ]

        // When
        let result = TechnicalIndicatorCalculator.emaTimeSeries(candles: candles, period: 3, priceSource: .close)

        // Then: 1개 EMA 값 (마지막 캔들에서)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].timestamp, date(2))
        // SMA(10, 20, 30) = 20
        XCTAssertEqual(result[0].value, 20.0, accuracy: 0.01)
    }

    func testEMATimeSeries_withEmptyCandles_returnsEmpty() {
        // Given: 빈 캔들 배열
        let candles: [Candle] = []

        // When
        let result = TechnicalIndicatorCalculator.emaTimeSeries(candles: candles, period: 5, priceSource: .close)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testEMATimeSeries_withZeroPeriod_returnsEmpty() {
        // Given: period = 0
        let candles = [
            Candle(timestamp: date(0), open: 10, high: 12, low: 9, close: 10, volume: 1000)
        ]

        // When
        let result = TechnicalIndicatorCalculator.emaTimeSeries(candles: candles, period: 0, priceSource: .close)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testEMATimeSeries_withNegativePeriod_returnsEmpty() {
        // Given: period = -1
        let candles = [
            Candle(timestamp: date(0), open: 10, high: 12, low: 9, close: 10, volume: 1000)
        ]

        // When
        let result = TechnicalIndicatorCalculator.emaTimeSeries(candles: candles, period: -1, priceSource: .close)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Helper

    private func date(_ dayOffset: Int) -> Date {
        let calendar = Calendar.current
        let base = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        return calendar.date(byAdding: .day, value: dayOffset, to: base)!
    }
}

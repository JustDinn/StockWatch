//
//  TechnicalIndicatorCalculatorRSITests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class TechnicalIndicatorCalculatorRSITests: XCTestCase {

    func test_rsiTimeSeries_withInsufficientData_returnsEmpty() {
        let candles = (0..<10).map { i in
            Candle(timestamp: Date().addingTimeInterval(Double(i) * 86400), open: 100, high: 110, low: 90, close: 105, volume: 1000)
        }
        
        let result = TechnicalIndicatorCalculator.rsiTimeSeries(candles: candles, period: 10)
        
        XCTAssertTrue(result.isEmpty)
    }

    func test_rsiTimeSeries_withExactlyRequiredData_returnsFirstValue() {
        let period = 14
        let candles = (0...period).map { i in
            Candle(timestamp: Date().addingTimeInterval(Double(i) * 86400), open: 100, high: 110, low: 90, close: 100 + Double(i), volume: 1000)
        }
        
        let result = TechnicalIndicatorCalculator.rsiTimeSeries(candles: candles, period: period)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.timestamp, candles[period].timestamp)
        // 모든 캔들이 상승했으므로 RSI는 100
        XCTAssertEqual(result.first?.value, 100.0)
    }

    func test_rsiTimeSeries_allDown_returnsZero() {
        let period = 5
        let candles = (0...period + 3).map { i in
            Candle(timestamp: Date().addingTimeInterval(Double(i) * 86400), open: 100, high: 100, low: 100, close: 200 - Double(i), volume: 1000)
        }
        
        let result = TechnicalIndicatorCalculator.rsiTimeSeries(candles: candles, period: period)
        
        XCTAssertFalse(result.isEmpty)
        for item in result {
            XCTAssertEqual(item.value, 0.0)
        }
    }
}

//
//  YahooFinanceCandlestickMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class YahooFinanceCandlestickMapperTests: XCTestCase {

    private var sut: YahooFinanceCandlestickMapper!

    override func setUp() {
        super.setUp()
        sut = YahooFinanceCandlestickMapper()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // 유효한 DTO → 올바른 캔들 개수 반환
    func test_map_withValidDTO_returnsCorrectCandleCount() {
        // Given
        let dto = makeDTO(
            timestamps: [1_700_000_000, 1_700_086_400],
            opens: [100.0, 105.0],
            highs: [110.0, 115.0],
            lows: [95.0, 100.0],
            closes: [105.0, 112.0],
            volumes: [1_000_000.0, 2_000_000.0]
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL")

        // Then
        XCTAssertEqual(result.candles.count, 2)
        XCTAssertEqual(result.ticker, "AAPL")
    }

    // timestamp nil → 빈 캔들 반환
    func test_map_withNilTimestamps_returnsEmptyCandlestickData() {
        // Given
        let dto = YahooFinanceCandlestickDTO(
            chart: .init(result: [
                .init(timestamp: nil, indicators: nil)
            ], error: nil)
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL")

        // Then
        XCTAssertEqual(result.candles.count, 0)
    }

    // 일부 nil 값 → 해당 캔들 스킵
    func test_map_withPartialNilValues_skipsInvalidCandles() {
        // Given: close[1]이 nil
        let dto = makeDTO(
            timestamps: [1_700_000_000, 1_700_086_400],
            opens: [100.0, 105.0],
            highs: [110.0, 115.0],
            lows: [95.0, 100.0],
            closes: [105.0, nil],
            volumes: [1_000_000.0, 2_000_000.0]
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL")

        // Then: 유효한 캔들 1개만 반환
        XCTAssertEqual(result.candles.count, 1)
    }

    // 첫 번째 캔들의 OHLCV 값 검증
    func test_map_firstCandleHasCorrectOHLCV() {
        // Given
        let dto = makeDTO(
            timestamps: [1_700_000_000],
            opens: [100.0],
            highs: [110.0],
            lows: [95.0],
            closes: [105.0],
            volumes: [1_000_000.0]
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL")

        // Then
        let candle = result.candles[0]
        XCTAssertEqual(candle.open, 100.0)
        XCTAssertEqual(candle.high, 110.0)
        XCTAssertEqual(candle.low, 95.0)
        XCTAssertEqual(candle.close, 105.0)
        XCTAssertEqual(candle.volume, 1_000_000.0)
    }

    // timestamp → Date 변환 검증
    func test_map_timestampConvertedToDate() {
        // Given
        let unixTimestamp: TimeInterval = 1_700_000_000
        let dto = makeDTO(
            timestamps: [unixTimestamp],
            opens: [100.0], highs: [110.0], lows: [95.0], closes: [105.0], volumes: [1_000_000.0]
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL")

        // Then
        let expectedDate = Date(timeIntervalSince1970: unixTimestamp)
        XCTAssertEqual(result.candles[0].timestamp, expectedDate)
    }

    // result가 nil → 빈 캔들 반환
    func test_map_withNilResult_returnsEmptyCandlestickData() {
        // Given
        let dto = YahooFinanceCandlestickDTO(
            chart: .init(result: nil, error: nil)
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL")

        // Then
        XCTAssertEqual(result.candles.count, 0)
    }
}

// MARK: - Helpers

private extension YahooFinanceCandlestickMapperTests {

    func makeDTO(
        timestamps: [TimeInterval],
        opens: [Double?],
        highs: [Double?],
        lows: [Double?],
        closes: [Double?],
        volumes: [Double?]
    ) -> YahooFinanceCandlestickDTO {
        YahooFinanceCandlestickDTO(
            chart: .init(
                result: [
                    .init(
                        timestamp: timestamps,
                        indicators: .init(
                            quote: [
                                .init(
                                    open: opens,
                                    high: highs,
                                    low: lows,
                                    close: closes,
                                    volume: volumes
                                )
                            ]
                        )
                    )
                ],
                error: nil
            )
        )
    }
}

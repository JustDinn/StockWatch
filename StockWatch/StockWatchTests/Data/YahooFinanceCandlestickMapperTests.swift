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

    // timestamp → NYSE 자정으로 정규화 검증
    func test_map_timestampNormalizedToNYSEMidnight() {
        // Given: 2023-11-14 14:30:00 UTC (NYSE 개장 시각)
        let unixTimestamp: TimeInterval = 1_700_000_000 // 2023-11-14 22:13:20 UTC
        let dto = makeDTO(
            timestamps: [unixTimestamp],
            opens: [100.0], highs: [110.0], lows: [95.0], closes: [105.0], volumes: [1_000_000.0]
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL")

        // Then: ET 기준 자정으로 정규화됨
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let components = calendar.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: unixTimestamp))
        let expectedDate = calendar.date(from: components)!
        XCTAssertEqual(result.candles[0].timestamp, expectedDate)
    }

    // 같은 거래일의 서로 다른 timestamp → 중복 제거 후 1개 캔들만 반환, 마지막 값 사용
    func test_map_sameTradingDayTimestamps_deduplicatedToLastValue() {
        // Given: 2024-03-20 14:30:00 UTC (시장 개장) vs 2024-03-20 20:00:08 UTC (live 캔들)
        // 2024-03-20 14:30:00 UTC = 1710941400
        // 2024-03-20 20:00:08 UTC = 1710961208
        let marketOpenTimestamp: TimeInterval = 1_710_941_400
        let liveTimestamp: TimeInterval = 1_710_961_208
        let dto = makeDTO(
            timestamps: [marketOpenTimestamp, liveTimestamp],
            opens: [170.0, 171.0],
            highs: [175.0, 176.0],
            lows: [169.0, 170.0],
            closes: [174.0, 175.0],
            volumes: [1_000_000.0, 1_100_000.0]
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL")

        // Then: 중복 제거로 1개 캔들만 반환, 마지막 데이터(live 캔들) 값 사용
        XCTAssertEqual(result.candles.count, 1)
        XCTAssertEqual(result.candles[0].close, 175.0)
        XCTAssertEqual(result.candles[0].volume, 1_100_000.0)
    }

    // 월봉: 같은 달(2026-04) 다른 날짜 타임스탬프 → 1개 캔들로 중복 제거, 마지막 값 사용
    func test_map_sameMonthDifferentDayTimestamps_deduplicatedToLastValue() {
        // Given: 2026-04-01 00:00 ET (월 시작 스냅샷) vs 2026-04-02 14:30 ET (장중 확정)
        let monthStartTimestamp: TimeInterval = 1_775_016_000  // 2026-04-01 00:00 ET
        let midMonthTimestamp: TimeInterval   = 1_775_154_600  // 2026-04-02 14:30 ET
        let dto = makeDTO(
            timestamps: [monthStartTimestamp, midMonthTimestamp],
            opens:   [200.0, 201.0],
            highs:   [210.0, 211.0],
            lows:    [195.0, 196.0],
            closes:  [205.0, 208.0],
            volumes: [5_000_000.0, 5_500_000.0]
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL", interval: "1mo")

        // Then: 중복 제거로 1개 캔들만 반환, 마지막 데이터(최신) 값 사용
        XCTAssertEqual(result.candles.count, 1)
        XCTAssertEqual(result.candles[0].close, 208.0)
        XCTAssertEqual(result.candles[0].volume, 5_500_000.0)
    }

    // 주봉: 같은 주(2026-03-30 주) 다른 날짜 타임스탬프 → 1개 캔들로 중복 제거, 마지막 값 사용
    func test_map_sameWeekDifferentDayTimestamps_deduplicatedToLastValue() {
        // Given: 2026-03-30 00:00 ET (주 시작 월요일) vs 2026-04-02 14:30 ET (같은 주 목요일)
        let weekStartTimestamp: TimeInterval = 1_774_843_200  // 2026-03-30 00:00 ET (Mon)
        let midWeekTimestamp: TimeInterval   = 1_775_154_600  // 2026-04-02 14:30 ET (Thu)
        let dto = makeDTO(
            timestamps: [weekStartTimestamp, midWeekTimestamp],
            opens:   [200.0, 201.0],
            highs:   [210.0, 212.0],
            lows:    [195.0, 196.0],
            closes:  [205.0, 209.0],
            volumes: [3_000_000.0, 3_200_000.0]
        )

        // When
        let result = sut.map(dto: dto, ticker: "AAPL", interval: "1wk")

        // Then: 중복 제거로 1개 캔들만 반환, 마지막 데이터(최신) 값 사용
        XCTAssertEqual(result.candles.count, 1)
        XCTAssertEqual(result.candles[0].close, 209.0)
        XCTAssertEqual(result.candles[0].volume, 3_200_000.0)
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

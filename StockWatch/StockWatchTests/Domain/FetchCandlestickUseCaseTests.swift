//
//  FetchCandlestickUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockCandlestickRepository: CandlestickRepositoryProtocol {
    var stubbedResult: CandlestickData?
    var stubbedError: Error?
    private(set) var receivedPeriod: ChartPeriod?
    private(set) var receivedRange: String?

    func fetchCandlesticks(ticker: String, period: ChartPeriod) async throws -> CandlestickData {
        receivedPeriod = period
        if let error = stubbedError { throw error }
        return stubbedResult ?? CandlestickData(ticker: ticker, candles: [])
    }

    func fetchCandlesticks(ticker: String, interval: String, period1: Int, period2: Int) async throws -> CandlestickData {
        if let error = stubbedError { throw error }
        return stubbedResult ?? CandlestickData(ticker: ticker, candles: [])
    }

    func fetchCandlesticks(ticker: String, range: String, interval: String) async throws -> CandlestickData {
        receivedRange = range
        if let error = stubbedError { throw error }
        return stubbedResult ?? CandlestickData(ticker: ticker, candles: [])
    }
}

// MARK: - Tests

final class FetchCandlestickUseCaseTests: XCTestCase {

    private var sut: FetchCandlestickUseCase!
    private var mockRepository: MockCandlestickRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockCandlestickRepository()
        sut = FetchCandlestickUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 빈 ticker → emptyTicker 에러
    func test_execute_withEmptyTicker_throwsEmptyTickerError() async {
        // When / Then
        do {
            _ = try await sut.execute(ticker: "", period: .day)
            XCTFail("emptyTicker 에러가 발생해야 한다")
        } catch FetchCandlestickError.emptyTicker {
            // success
        } catch {
            XCTFail("예상치 못한 에러: \(error)")
        }
    }

    // 유효한 ticker → CandlestickData 반환
    func test_execute_withValidTicker_returnsCandlestickData() async throws {
        // Given
        let candle = Candle(
            timestamp: Date(),
            open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000
        )
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: [candle])

        // When
        let result = try await sut.execute(ticker: "AAPL", period: .day)

        // Then
        XCTAssertEqual(result.ticker, "AAPL")
        XCTAssertEqual(result.candles.count, 1)
    }

    // Repository 에러 → 에러 전파
    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Given
        mockRepository.stubbedError = NSError(domain: "TestError", code: 1)

        // When / Then
        do {
            _ = try await sut.execute(ticker: "AAPL", period: .day)
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // Repository 결과가 그대로 반환되는지 검증
    func test_execute_returnedCandlesMatchRepositoryData() async throws {
        // Given
        let now = Date()
        let candles = [
            Candle(timestamp: now, open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000),
            Candle(timestamp: now.addingTimeInterval(86400), open: 105.0, high: 115.0, low: 100.0, close: 112.0, volume: 2_000_000)
        ]
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // When
        let result = try await sut.execute(ticker: "AAPL", period: .day)

        // Then
        XCTAssertEqual(result.candles.count, 2)
        XCTAssertEqual(result.candles[0].open, 100.0)
        XCTAssertEqual(result.candles[1].close, 112.0)
        XCTAssertEqual(result.candles[0].volume, 1_000_000)
    }

    // period.day → repository에 .day 전달
    func test_execute_withPeriodDay_forwardsCorrectPeriodToRepository() async throws {
        // When
        _ = try await sut.execute(ticker: "AAPL", period: .day)

        // Then
        XCTAssertEqual(mockRepository.receivedPeriod, .day)
    }

    // period.year → repository에 .year 전달
    func test_execute_withPeriodYear_forwardsCorrectPeriodToRepository() async throws {
        // When
        _ = try await sut.execute(ticker: "AAPL", period: .year)

        // Then
        XCTAssertEqual(mockRepository.receivedPeriod, .year)
    }

    // 빈 ticker + 임의 period → emptyTicker 에러
    func test_execute_withEmptyTicker_anyPeriod_throwsEmptyTickerError() async {
        // When / Then
        do {
            _ = try await sut.execute(ticker: "", period: .month)
            XCTFail("emptyTicker 에러가 발생해야 한다")
        } catch FetchCandlestickError.emptyTicker {
            // success
        } catch {
            XCTFail("예상치 못한 에러: \(error)")
        }
    }

    // MARK: - Initial 20 Candles Limit

    // 20개 초과 → 최신 20개만 반환
    func test_execute_withMoreThan20Candles_returnsLast20() async throws {
        // Arrange
        let candles = (0..<130).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day)

        // Assert
        XCTAssertEqual(result.candles.count, 20)
    }

    // 정확히 20개 → 그대로 반환
    func test_execute_withExactly20Candles_returnsAll20() async throws {
        // Arrange
        let candles = (0..<20).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day)

        // Assert
        XCTAssertEqual(result.candles.count, 20)
    }

    // 20개 미만 → 전부 반환
    func test_execute_withLessThan20Candles_returnsAll() async throws {
        // Arrange
        let candles = (0..<5).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day)

        // Assert
        XCTAssertEqual(result.candles.count, 5)
    }

    // 빈 배열 → 빈 배열 반환
    func test_execute_withEmptyCandles_returnsEmpty() async throws {
        // Arrange
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: [])

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day)

        // Assert
        XCTAssertEqual(result.candles.count, 0)
    }

    // MARK: - Warmup Count

    // warmupCount=0 → 기존 동작(20개) 유지
    func test_execute_withZeroWarmupCount_returnsInitial20() async throws {
        // Arrange
        let candles = (0..<130).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day, warmupCount: 0)

        // Assert
        XCTAssertEqual(result.candles.count, 20)
    }

    // warmupCount=60 → 80개 반환
    func test_execute_withWarmupCount_returnsInitialPlusWarmup() async throws {
        // Arrange
        let candles = (0..<130).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: Double(i), high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day, warmupCount: 60)

        // Assert: 20 + 60 = 80개
        XCTAssertEqual(result.candles.count, 80)
        // 최신 80개 (index 50~129)
        XCTAssertEqual(result.candles.first?.open, 50.0)
        XCTAssertEqual(result.candles.last?.open, 129.0)
    }

    // warmupCount=200 → totalNeeded=220 → raw 데이터 충분하면 220개 반환
    func test_execute_withLargeWarmupCount_returns220() async throws {
        // Arrange: 300개 raw 데이터
        let candles = (0..<300).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: Double(i), high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day, warmupCount: 200)

        // Assert: 20 + 200 = 220개
        XCTAssertEqual(result.candles.count, 220)
        // 최신 220개 (index 80~299)
        XCTAssertEqual(result.candles.first?.open, 80.0)
        XCTAssertEqual(result.candles.last?.open, 299.0)
    }

    // warmupCount=500 이지만 raw 데이터가 300개 → 300개 모두 반환
    func test_execute_withWarmupExceedingAvailableCandles_returnsAll() async throws {
        // Arrange
        let candles = (0..<300).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day, warmupCount: 500)

        // Assert: totalNeeded=520이지만 raw=300이므로 300 반환
        XCTAssertEqual(result.candles.count, 300)
    }

    // warmupCount>defaultDailyCapacity(125)이면 widerRange fetch 사용
    func test_execute_withWarmupRequiringWiderRange_usesWiderRangeFetch() async throws {
        // Arrange: warmupCount=200 → totalNeeded=220 > 125 → "2y" range 사용
        let candles = (0..<300).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        _ = try await sut.execute(ticker: "AAPL", period: .day, warmupCount: 200)

        // Assert: range fetch가 호출됐어야 함
        XCTAssertNotNil(mockRepository.receivedRange)
        XCTAssertEqual(mockRepository.receivedRange, "2y")
    }

    // warmupCount가 작아 기존 range로 충분하면 widerRange fetch 미사용
    func test_execute_withSmallWarmupCount_usesDefaultFetch() async throws {
        // Arrange: warmupCount=60 → totalNeeded=80 ≤ 125 → 기존 period fetch 사용
        let candles = (0..<130).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        _ = try await sut.execute(ticker: "AAPL", period: .day, warmupCount: 60)

        // Assert: range fetch 미호출
        XCTAssertNil(mockRepository.receivedRange)
        XCTAssertEqual(mockRepository.receivedPeriod, .day)
    }

    // 최신 20개(배열 뒤 20개) 반환 여부 확인
    func test_execute_returnsNewestCandles_notOldest() async throws {
        // Arrange: 130개, index 110~129가 최신
        let candles = (0..<130).map { i in
            Candle(timestamp: Date(timeIntervalSince1970: TimeInterval(i * 86400)),
                   open: Double(i), high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        }
        mockRepository.stubbedResult = CandlestickData(ticker: "AAPL", candles: candles)

        // Act
        let result = try await sut.execute(ticker: "AAPL", period: .day)

        // Assert: 첫 번째 캔들의 open이 110.0 (index 110)이어야 함
        XCTAssertEqual(result.candles.first?.open, 110.0)
        XCTAssertEqual(result.candles.last?.open, 129.0)
    }
}

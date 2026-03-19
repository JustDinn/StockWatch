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

    func fetchCandlesticks(ticker: String, period: ChartPeriod) async throws -> CandlestickData {
        receivedPeriod = period
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
}

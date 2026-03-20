//
//  CandlestickRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Router-capturing Mock

final class MockNetworkServiceCapturingRouter: NetworkServiceProtocol {
    var stubbedResult: Any?
    var stubbedError: Error?
    private(set) var lastRouterParameters: [String: Any]?

    func request<T: Decodable>(router: some NetworkRouter, model: T.Type) async throws -> T {
        lastRouterParameters = router.parameters
        if let error = stubbedError { throw error }
        guard let result = stubbedResult as? T else {
            throw NetworkError.decodingFailed
        }
        return result
    }
}

// MARK: - Tests

final class CandlestickRepositoryTests: XCTestCase {

    private var sut: CandlestickRepository!
    private var mockNetworkService: MockNetworkService!
    private var mockCapturingService: MockNetworkServiceCapturingRouter!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockCapturingService = MockNetworkServiceCapturingRouter()
        sut = CandlestickRepository(networkService: mockNetworkService)
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        mockCapturingService = nil
        super.tearDown()
    }

    // 정상 응답 → Mapper를 통해 CandlestickData 반환
    func test_fetchCandlesticks_returnsMapperResult() async throws {
        // Given
        let dto = YahooFinanceCandlestickDTO(
            chart: .init(
                result: [
                    .init(
                        timestamp: [1_700_000_000, 1_700_086_400],
                        indicators: .init(
                            quote: [
                                .init(
                                    open: [100.0, 105.0],
                                    high: [110.0, 115.0],
                                    low: [95.0, 100.0],
                                    close: [105.0, 112.0],
                                    volume: [1_000_000.0, 2_000_000.0]
                                )
                            ]
                        )
                    )
                ],
                error: nil
            )
        )
        mockNetworkService.stubbedResult = dto

        // When
        let result = try await sut.fetchCandlesticks(ticker: "AAPL", period: .day)

        // Then
        XCTAssertEqual(result.ticker, "AAPL")
        XCTAssertEqual(result.candles.count, 2)
    }

    // 네트워크 에러 → 에러 전파
    func test_fetchCandlesticks_whenNetworkThrows_propagatesError() async {
        // Given
        mockNetworkService.stubbedError = NetworkError.networkDisconnected

        // When / Then
        do {
            _ = try await sut.fetchCandlesticks(ticker: "AAPL", period: .day)
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // period .day → range:"1mo", interval:"1d" 로 라우터 호출
    func test_fetchCandlesticks_withPeriodDay_usesCorrectRangeAndInterval() async throws {
        // Given
        let dto = YahooFinanceCandlestickDTO(chart: .init(result: [], error: nil))
        mockCapturingService.stubbedResult = dto
        let capturingSut = CandlestickRepository(networkService: mockCapturingService)

        // When
        _ = try await capturingSut.fetchCandlesticks(ticker: "AAPL", period: .day)

        // Then
        XCTAssertEqual(mockCapturingService.lastRouterParameters?["range"] as? String, "1mo")
        XCTAssertEqual(mockCapturingService.lastRouterParameters?["interval"] as? String, "1d")
    }

    // period .year → range:"20y", interval:"1y" 로 라우터 호출
    func test_fetchCandlesticks_withPeriodYear_usesCorrectRangeAndInterval() async throws {
        // Given
        let dto = YahooFinanceCandlestickDTO(chart: .init(result: [], error: nil))
        mockCapturingService.stubbedResult = dto
        let capturingSut = CandlestickRepository(networkService: mockCapturingService)

        // When
        _ = try await capturingSut.fetchCandlesticks(ticker: "AAPL", period: .year)

        // Then
        XCTAssertEqual(mockCapturingService.lastRouterParameters?["range"] as? String, "20y")
        XCTAssertEqual(mockCapturingService.lastRouterParameters?["interval"] as? String, "1y")
    }

    // period .week → range:"5mo", interval:"1wk" 로 라우터 호출
    func test_fetchCandlesticks_withPeriodWeek_usesCorrectRangeAndInterval() async throws {
        // Given
        let dto = YahooFinanceCandlestickDTO(chart: .init(result: [], error: nil))
        mockCapturingService.stubbedResult = dto
        let capturingSut = CandlestickRepository(networkService: mockCapturingService)

        // When
        _ = try await capturingSut.fetchCandlesticks(ticker: "AAPL", period: .week)

        // Then
        XCTAssertEqual(mockCapturingService.lastRouterParameters?["range"] as? String, "5mo")
        XCTAssertEqual(mockCapturingService.lastRouterParameters?["interval"] as? String, "1wk")
    }
}

//
//  CandlestickRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class CandlestickRepositoryTests: XCTestCase {

    private var sut: CandlestickRepository!
    private var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = CandlestickRepository(networkService: mockNetworkService)
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
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
        let result = try await sut.fetchCandlesticks(ticker: "AAPL")

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
            _ = try await sut.fetchCandlesticks(ticker: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

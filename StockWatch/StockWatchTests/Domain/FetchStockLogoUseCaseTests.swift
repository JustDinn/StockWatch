//
//  FetchStockLogoUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockStockLogoRepository: StockLogoRepositoryProtocol {
    var stubbedResult: String = ""
    var stubbedError: Error?
    var lastReceivedTicker: String?

    func fetchLogoURL(ticker: String) async throws -> String {
        lastReceivedTicker = ticker
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

// MARK: - Tests

final class FetchStockLogoUseCaseTests: XCTestCase {

    private var sut: FetchStockLogoUseCase!
    private var mockRepository: MockStockLogoRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockStockLogoRepository()
        sut = FetchStockLogoUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 정상 케이스: 유효한 ticker로 로고 URL을 반환하는지 검증
    func test_execute_withValidTicker_returnsLogoURL() async throws {
        // Arrange
        let expected = "https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AAPL.png"
        mockRepository.stubbedResult = expected

        // Act
        let result = try await sut.execute(ticker: "AAPL")

        // Assert
        XCTAssertEqual(result, expected)
        XCTAssertEqual(mockRepository.lastReceivedTicker, "AAPL")
    }

    // 에러 전파 케이스: Repository 에러가 올바르게 전파되는지 검증
    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Arrange
        mockRepository.stubbedError = NetworkError.serverError

        // Act / Assert
        do {
            _ = try await sut.execute(ticker: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // 빈 ticker 케이스: Repository를 호출하지 않고 빈 문자열 반환
    func test_execute_withEmptyTicker_returnsEmptyString() async throws {
        // Arrange
        mockRepository.stubbedResult = "https://logo.url"

        // Act
        let result = try await sut.execute(ticker: "")

        // Assert
        XCTAssertTrue(result.isEmpty)
        XCTAssertNil(mockRepository.lastReceivedTicker, "빈 ticker 시 Repository를 호출하지 않아야 한다")
    }
}

//
//  FetchExchangeRateUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockExchangeRateRepository: ExchangeRateRepositoryProtocol {
    var stubbedResult: [String: Double] = [:]
    var stubbedError: Error?
    var lastReceivedCurrencies: [String]?

    func fetchRates(currencies: [String]) async throws -> [String: Double] {
        lastReceivedCurrencies = currencies
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

// MARK: - Tests

final class FetchExchangeRateUseCaseTests: XCTestCase {

    private var sut: FetchExchangeRateUseCase!
    private var mockRepository: MockExchangeRateRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockExchangeRateRepository()
        sut = FetchExchangeRateUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // KRW 환율 조회 시 Repository를 호출하고 결과를 반환하는지 검증
    func test_execute_withKRW_returnsExchangeRate() async throws {
        // Arrange
        mockRepository.stubbedResult = ["KRW": 1380.0]

        // Act
        let result = try await sut.execute(currencies: ["KRW"])

        // Assert
        XCTAssertEqual(result["KRW"], 1380.0)
        XCTAssertEqual(result["USD"], 1.0)
        XCTAssertEqual(mockRepository.lastReceivedCurrencies, ["KRW"])
    }

    // USD만 요청 시 Repository를 호출하지 않고 1.0을 반환하는지 검증
    func test_execute_withUSD_returnsOnePointZero() async throws {
        // Act
        let result = try await sut.execute(currencies: ["USD"])

        // Assert
        XCTAssertEqual(result["USD"], 1.0)
        XCTAssertNil(mockRepository.lastReceivedCurrencies, "USD만 있으면 Repository를 호출하지 않아야 한다")
    }

    // 빈 배열 입력 시 USD만 포함된 딕셔너리를 반환하는지 검증
    func test_execute_withEmptyCurrencies_returnsOnlyUSD() async throws {
        // Act
        let result = try await sut.execute(currencies: [])

        // Assert
        XCTAssertEqual(result, ["USD": 1.0])
        XCTAssertNil(mockRepository.lastReceivedCurrencies)
    }

    // Repository 에러가 올바르게 전파되는지 검증
    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Arrange
        mockRepository.stubbedError = NetworkError.serverError

        // Act / Assert
        do {
            _ = try await sut.execute(currencies: ["KRW"])
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // 여러 통화 요청 시 USD는 자동 포함되고 나머지만 Repository에 전달하는지 검증
    func test_execute_withMixedCurrencies_filtersUSDFromRepositoryCall() async throws {
        // Arrange
        mockRepository.stubbedResult = ["KRW": 1380.0, "JPY": 155.0]

        // Act
        let result = try await sut.execute(currencies: ["USD", "KRW", "JPY"])

        // Assert
        XCTAssertEqual(result["USD"], 1.0)
        XCTAssertEqual(result["KRW"], 1380.0)
        XCTAssertEqual(result["JPY"], 155.0)
        XCTAssertEqual(Set(mockRepository.lastReceivedCurrencies ?? []), Set(["KRW", "JPY"]))
    }
}

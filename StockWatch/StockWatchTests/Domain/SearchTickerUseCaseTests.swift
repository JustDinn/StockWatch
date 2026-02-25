//
//  SearchTickerUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockSearchRepository: SearchRepositoryProtocol {
    var stubbedResult: [SearchResult] = []
    var stubbedError: Error?
    var lastReceivedQuery: String?

    func search(query: String) async throws -> [SearchResult] {
        lastReceivedQuery = query
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

// MARK: - Tests

final class SearchTickerUseCaseTests: XCTestCase {

    private var sut: SearchTickerUseCase!
    private var mockRepository: MockSearchRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockSearchRepository()
        sut = SearchTickerUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 정상 케이스: 검색어로 결과를 반환하는지 검증
    func test_execute_withValidQuery_returnsResults() async throws {
        // Given
        let expected = [
            SearchResult(description: "APPLE INC", displayTicker: "AAPL", ticker: "AAPL", type: "Common Stock")
        ]
        mockRepository.stubbedResult = expected

        // When
        let result = try await sut.execute(query: "AAPL")

        // Then
        XCTAssertEqual(result, expected)
        XCTAssertEqual(mockRepository.lastReceivedQuery, "AAPL")
    }

    // 빈 쿼리 케이스: 빈 문자열이면 Repository를 호출하지 않고 빈 배열 반환
    func test_execute_withEmptyQuery_returnsEmpty() async throws {
        // Given
        mockRepository.stubbedResult = [
            SearchResult(description: "APPLE INC", displayTicker: "AAPL", ticker: "AAPL", type: "Common Stock")
        ]

        // When
        let result = try await sut.execute(query: "")

        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertNil(mockRepository.lastReceivedQuery, "빈 쿼리 시 Repository를 호출하지 않아야 한다")
    }

    // 에러 전파 케이스: Repository가 에러를 던지면 UseCase도 에러를 전파하는지 검증
    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Given
        mockRepository.stubbedError = NetworkError.serverError

        // When / Then
        do {
            _ = try await sut.execute(query: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

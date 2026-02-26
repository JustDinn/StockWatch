//
//  SearchRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock NetworkService

final class MockNetworkService: NetworkServiceProtocol {
    var stubbedResult: Any?
    var stubbedError: Error?

    func request<T: Decodable>(router: some NetworkRouter, model: T.Type) async throws -> T {
        if let error = stubbedError { throw error }
        guard let result = stubbedResult as? T else {
            fatalError("MockNetworkService: stubbedResult 타입이 일치하지 않습니다.")
        }
        return result
    }
}

// MARK: - Tests

final class SearchRepositoryTests: XCTestCase {

    private var sut: TickerRepository!
    private var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = TickerRepository(networkService: mockNetworkService, apiKey: "test-api-key")
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // 정상 케이스: NetworkService 응답을 Entity로 변환하여 반환하는지 검증
    func test_search_withValidResponse_returnsMappedResults() async throws {
        // Given
        let dto = TickerSearchResponseDTO(
            count: 1,
            result: [
                TickerSearchItemDTO(
                    description: "APPLE INC",
                    displayTicker: "AAPL",
                    ticker: "AAPL",
                    type: "Common Stock"
                )
            ]
        )
        mockNetworkService.stubbedResult = dto

        // When
        let results = try await sut.search(query: "AAPL")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].ticker, "AAPL")
        XCTAssertEqual(results[0].description, "APPLE INC")
    }

    // 빈 결과 케이스: API가 빈 결과를 반환하면 빈 배열을 반환하는지 검증
    func test_search_withEmptyResponse_returnsEmptyArray() async throws {
        // Given
        let dto = TickerSearchResponseDTO(count: 0, result: [])
        mockNetworkService.stubbedResult = dto

        // When
        let results = try await sut.search(query: "XYZXYZ")

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    // 에러 전파 케이스: NetworkService 에러가 올바르게 전파되는지 검증
    func test_search_whenNetworkFails_throwsError() async {
        // Given
        mockNetworkService.stubbedError = NetworkError.networkDisconnected

        // When / Then
        do {
            _ = try await sut.search(query: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

//
//  HomeStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock UseCase

final class MockSearchTickerUseCase: SearchTickerUseCaseProtocol {
    var stubbedResult: [SearchResult] = []
    var stubbedError: Error?
    var executeCallCount = 0
    var lastReceivedQuery: String?

    func execute(query: String) async throws -> [SearchResult] {
        executeCallCount += 1
        lastReceivedQuery = query
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

// MARK: - Tests

@MainActor
final class HomeStoreTests: XCTestCase {

    private var sut: HomeStore!
    private var mockUseCase: MockSearchTickerUseCase!

    override func setUp() {
        super.setUp()
        mockUseCase = MockSearchTickerUseCase()
        sut = HomeStore(searchTickerUseCase: mockUseCase)
    }

    override func tearDown() {
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    // 초기 상태 검증
    func test_initialState_isCorrect() {
        XCTAssertTrue(sut.state.searchResults.isEmpty)
        XCTAssertFalse(sut.state.isLoading)
        XCTAssertNil(sut.state.errorMessage)
    }

    // 정상 검색: 결과가 State에 반영되는지 검증
    func test_action_search_withResults_updatesState() async {
        // Given
        let expected = [
            SearchResult(description: "APPLE INC", displayTicker: "AAPL", ticker: "AAPL", type: "Common Stock")
        ]
        mockUseCase.stubbedResult = expected

        // When
        sut.action(.search("AAPL"))

        // Task 완료 대기
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.state.searchResults, expected)
        XCTAssertFalse(sut.state.isLoading)
        XCTAssertNil(sut.state.errorMessage)
    }

    // 빈 검색어: 빈 문자열이면 결과를 비우고 UseCase를 호출하지 않는지 검증
    func test_action_search_withEmptyQuery_clearsResults() async {
        // Given: 이전 결과가 있는 상태
        mockUseCase.stubbedResult = [
            SearchResult(description: "APPLE INC", displayTicker: "AAPL", ticker: "AAPL", type: "Common Stock")
        ]
        sut.action(.search("AAPL"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When: 빈 검색어로 검색
        mockUseCase.executeCallCount = 0
        sut.action(.search(""))

        // Then
        XCTAssertTrue(sut.state.searchResults.isEmpty)
        XCTAssertEqual(mockUseCase.executeCallCount, 0, "빈 쿼리 시 UseCase를 호출하지 않아야 한다")
    }

    // 에러 발생 시 State에 에러 메시지가 반영되는지 검증
    func test_action_search_whenUseCaseFails_updatesErrorState() async {
        // Given
        mockUseCase.stubbedError = NetworkError.networkDisconnected

        // When
        sut.action(.search("AAPL"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.state.searchResults.isEmpty)
        XCTAssertFalse(sut.state.isLoading)
        XCTAssertNotNil(sut.state.errorMessage)
    }
}

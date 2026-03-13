//
//  HomeStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock UseCases

final class MockCheckUnreadNotificationUseCase: CheckUnreadNotificationUseCaseProtocol {
    var stubbedResult: Bool = false
    var stubbedError: Error?
    var executeCallCount = 0

    func execute() throws -> Bool {
        executeCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

final class MockTickerUseCase: TickerUseCaseProtocol {
    var stubbedResult: [SearchResult] = []
    var stubbedError: Error?
    var executeCallCount = 0
    var lastReceivedQuery: String?

    func search(query: String) async throws -> [SearchResult] {
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
    private var mockUseCase: MockTickerUseCase!
    private var mockCheckUnreadUseCase: MockCheckUnreadNotificationUseCase!

    override func setUp() {
        super.setUp()
        mockUseCase = MockTickerUseCase()
        mockCheckUnreadUseCase = MockCheckUnreadNotificationUseCase()
        sut = HomeStore(tickerUseCase: mockUseCase, checkUnreadUseCase: mockCheckUnreadUseCase)
    }

    override func tearDown() {
        sut = nil
        mockUseCase = nil
        mockCheckUnreadUseCase = nil
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

    // onAppear: 미읽음 알림이 있을 때 hasUnreadNotification = true
    func test_action_onAppear_whenHasUnread_setsHasUnreadNotificationTrue() {
        // Given
        mockCheckUnreadUseCase.stubbedResult = true

        // When
        sut.action(.onAppear)

        // Then
        XCTAssertTrue(sut.state.hasUnreadNotification)
    }

    // onAppear: 모든 알림이 읽음 상태일 때 hasUnreadNotification = false
    func test_action_onAppear_whenAllRead_setsHasUnreadNotificationFalse() {
        // Given
        mockCheckUnreadUseCase.stubbedResult = false

        // When
        sut.action(.onAppear)

        // Then
        XCTAssertFalse(sut.state.hasUnreadNotification)
    }

    // onAppear: UseCase 에러 시 hasUnreadNotification = false (기본값 유지)
    func test_action_onAppear_whenUseCaseFails_hasUnreadNotificationIsFalse() {
        // Given
        mockCheckUnreadUseCase.stubbedError = NetworkError.serverError

        // When
        sut.action(.onAppear)

        // Then
        XCTAssertFalse(sut.state.hasUnreadNotification)
    }

    // isShowingNotificationHistoryBinding: dismiss 시 loadUnreadStatus 호출
    func test_isShowingNotificationHistoryBinding_whenDismissed_callsLoadUnreadStatus() {
        // Given
        mockCheckUnreadUseCase.stubbedResult = true
        sut.isShowingNotificationHistoryBinding.wrappedValue = true
        mockCheckUnreadUseCase.executeCallCount = 0

        // When: dismiss (false로 set)
        sut.isShowingNotificationHistoryBinding.wrappedValue = false

        // Then
        XCTAssertEqual(mockCheckUnreadUseCase.executeCallCount, 1)
        XCTAssertTrue(sut.state.hasUnreadNotification)
    }
}

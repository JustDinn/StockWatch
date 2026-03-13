//
//  StockDetailStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockFetchStockDetailUseCase: FetchStockDetailUseCaseProtocol {
    var stubbedResult: StockDetail?
    var stubbedError: Error?

    func execute(ticker: String) async throws -> StockDetail {
        if let error = stubbedError { throw error }
        return stubbedResult ?? StockDetail(
            ticker: ticker,
            companyName: "Test Corp",
            currentPrice: 100.0,
            priceChangePercent: 1.0,
            logoURL: ""
        )
    }
}

final class MockToggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol {
    var stubbedResult: Bool = false
    var stubbedError: Error?
    private(set) var executeCallCount = 0
    private(set) var lastReceivedTicker: String?

    func execute(ticker: String) async throws -> Bool {
        executeCallCount += 1
        lastReceivedTicker = ticker
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

final class MockCheckFavoriteUseCase: CheckFavoriteUseCaseProtocol {
    var stubbedResult: Bool = false
    private(set) var executeCallCount = 0
    private(set) var lastReceivedTicker: String?

    func execute(ticker: String) async -> Bool {
        executeCallCount += 1
        lastReceivedTicker = ticker
        return stubbedResult
    }
}

// MARK: - Tests

@MainActor
final class StockDetailStoreTests: XCTestCase {

    private var sut: StockDetailStore!
    private var mockFetchUseCase: MockFetchStockDetailUseCase!
    private var mockToggleUseCase: MockToggleFavoriteUseCase!
    private var mockCheckUseCase: MockCheckFavoriteUseCase!

    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchStockDetailUseCase()
        mockToggleUseCase = MockToggleFavoriteUseCase()
        mockCheckUseCase = MockCheckFavoriteUseCase()
        sut = StockDetailStore(
            ticker: "AAPL",
            fetchStockDetailUseCase: mockFetchUseCase,
            toggleFavoriteUseCase: mockToggleUseCase,
            checkFavoriteUseCase: mockCheckUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchUseCase = nil
        mockToggleUseCase = nil
        mockCheckUseCase = nil
        super.tearDown()
    }

    // 초기 상태 검증
    func test_initialState_isCorrect() {
        XCTAssertEqual(sut.state.ticker, "AAPL")
        XCTAssertFalse(sut.state.isFavorite)
        XCTAssertFalse(sut.state.isLoading)
        XCTAssertNil(sut.state.errorMessage)
    }

    // loadDetail 시 CheckFavoriteUseCase로 isFavorite 초기화
    func test_action_loadDetail_checksFavoriteStatus() async {
        // Given
        mockCheckUseCase.stubbedResult = true

        // When
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockCheckUseCase.executeCallCount, 1)
        XCTAssertEqual(mockCheckUseCase.lastReceivedTicker, "AAPL")
        XCTAssertTrue(sut.state.isFavorite)
    }

    // 미등록 종목 토글 → isFavorite이 true로 변경
    func test_action_toggleFavorite_whenNotFavorite_updatesStateToTrue() async {
        // Given
        mockToggleUseCase.stubbedResult = true
        XCTAssertFalse(sut.state.isFavorite)

        // When
        sut.action(.toggleFavorite)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.state.isFavorite)
        XCTAssertEqual(mockToggleUseCase.executeCallCount, 1)
        XCTAssertEqual(mockToggleUseCase.lastReceivedTicker, "AAPL")
    }

    // 등록된 종목 토글 → isFavorite이 false로 변경
    func test_action_toggleFavorite_whenFavorite_updatesStateToFalse() async {
        // Given: 먼저 즐겨찾기 상태로 만들기
        mockCheckUseCase.stubbedResult = true
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 100_000_000)
        mockToggleUseCase.stubbedResult = false

        // When
        sut.action(.toggleFavorite)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.state.isFavorite)
        XCTAssertEqual(mockToggleUseCase.executeCallCount, 1)
    }

    // UseCase 에러 시 상태 롤백
    func test_action_toggleFavorite_whenUseCaseFails_revertsState() async {
        // Given: isFavorite = false 상태에서 에러 발생
        mockToggleUseCase.stubbedError = NSError(domain: "TestError", code: 1)

        // When
        sut.action(.toggleFavorite)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: 낙관적 업데이트가 롤백되어 원래 false로 복구
        XCTAssertFalse(sut.state.isFavorite)
    }
}

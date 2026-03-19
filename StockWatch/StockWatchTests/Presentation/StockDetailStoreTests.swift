//
//  StockDetailStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockFetchCandlestickUseCase: FetchCandlestickUseCaseProtocol {
    var stubbedResult: CandlestickData?
    var stubbedError: Error?
    private(set) var receivedPeriod: ChartPeriod?
    private(set) var executeCallCount = 0

    func execute(ticker: String, period: ChartPeriod) async throws -> CandlestickData {
        executeCallCount += 1
        receivedPeriod = period
        if let error = stubbedError { throw error }
        return stubbedResult ?? CandlestickData(ticker: ticker, candles: [])
    }
}

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
            logoURL: "",
            currency: "USD"
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
    private var mockCandlestickUseCase: MockFetchCandlestickUseCase!

    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchStockDetailUseCase()
        mockToggleUseCase = MockToggleFavoriteUseCase()
        mockCheckUseCase = MockCheckFavoriteUseCase()
        mockCandlestickUseCase = MockFetchCandlestickUseCase()
        sut = StockDetailStore(
            ticker: "AAPL",
            fetchStockDetailUseCase: mockFetchUseCase,
            fetchCandlestickUseCase: mockCandlestickUseCase,
            toggleFavoriteUseCase: mockToggleUseCase,
            checkFavoriteUseCase: mockCheckUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchUseCase = nil
        mockToggleUseCase = nil
        mockCheckUseCase = nil
        mockCandlestickUseCase = nil
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

    // loadDetail 완료 후 isChartLoading이 false가 되어야 함
    func test_action_loadDetail_setsIsChartLoadingFalseAfterCompletion() async {
        // When
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.state.isChartLoading)
    }

    // 캔들스틱 성공 → candlestickData 업데이트
    func test_action_loadDetail_onCandlestickSuccess_updatesCandlestickData() async {
        // Given
        let candle = Candle(timestamp: Date(), open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        mockCandlestickUseCase.stubbedResult = CandlestickData(ticker: "AAPL", candles: [candle])

        // When
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.state.candlestickData)
        XCTAssertEqual(sut.state.candlestickData?.candles.count, 1)
    }

    // 캔들스틱 실패 → chartErrorMessage 설정
    func test_action_loadDetail_onCandlestickFailure_setsChartErrorMessage() async {
        // Given
        mockCandlestickUseCase.stubbedError = NSError(domain: "ChartError", code: 1, userInfo: [NSLocalizedDescriptionKey: "차트 로딩 실패"])

        // When
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.state.chartErrorMessage)
        XCTAssertNil(sut.state.candlestickData)
    }

    // 캔들스틱 실패해도 주식 상세 정보는 정상 표시
    func test_action_loadDetail_candlestickFailure_doesNotAffectStockDetail() async {
        // Given
        mockCandlestickUseCase.stubbedError = NSError(domain: "ChartError", code: 1)

        // When
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: 주식 상세 errorMessage는 nil, isLoading은 false
        XCTAssertNil(sut.state.errorMessage)
        XCTAssertFalse(sut.state.isLoading)
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

    // loadDetail 시 기본 period(.day)를 UseCase에 전달
    func test_action_loadDetail_passesDefaultPeriodToUseCase() async {
        // When
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockCandlestickUseCase.receivedPeriod, .day)
    }

    // selectPeriod → state.selectedPeriod 업데이트
    func test_action_selectPeriod_updatesSelectedPeriod() async {
        // When
        sut.action(.selectPeriod(.week))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.state.selectedPeriod, .week)
    }

    // selectPeriod → 해당 period로 차트 재조회
    func test_action_selectPeriod_triggersChartRefetch_withCorrectPeriod() async {
        // Given
        let candle = Candle(timestamp: Date(), open: 100.0, high: 110.0, low: 95.0, close: 105.0, volume: 1_000_000)
        mockCandlestickUseCase.stubbedResult = CandlestickData(ticker: "AAPL", candles: [candle])

        // When
        sut.action(.selectPeriod(.month))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockCandlestickUseCase.receivedPeriod, .month)
        XCTAssertNotNil(sut.state.candlestickData)
    }

    // selectPeriod 후 로딩 완료 → isChartLoading == false
    func test_action_selectPeriod_setsIsChartLoadingFalseAfterCompletion() async {
        // When
        sut.action(.selectPeriod(.year))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.state.isChartLoading)
    }

    // selectPeriod 에러 → chartErrorMessage 설정
    func test_action_selectPeriod_withError_setsChartErrorMessage() async {
        // Given
        mockCandlestickUseCase.stubbedError = NSError(domain: "ChartError", code: 1, userInfo: [NSLocalizedDescriptionKey: "차트 로딩 실패"])

        // When
        sut.action(.selectPeriod(.week))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(sut.state.chartErrorMessage)
        XCTAssertNil(sut.state.candlestickData)
    }

    // selectPeriod 성공 → chartErrorMessage 초기화
    func test_action_selectPeriod_clearsChartErrorOnSuccess() async {
        // Given: 먼저 에러 상태 만들기
        mockCandlestickUseCase.stubbedError = NSError(domain: "ChartError", code: 1)
        sut.action(.selectPeriod(.week))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(sut.state.chartErrorMessage)

        // When: 이번엔 성공
        mockCandlestickUseCase.stubbedError = nil
        mockCandlestickUseCase.stubbedResult = CandlestickData(ticker: "AAPL", candles: [])
        sut.action(.selectPeriod(.day))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNil(sut.state.chartErrorMessage)
    }
}

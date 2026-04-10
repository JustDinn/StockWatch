//
//  StockDetailStoreNetworkMonitorTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Tests

@MainActor
final class StockDetailStoreNetworkMonitorTests: XCTestCase {

    private var sut: StockDetailStore!
    private var mockFetchUseCase: MockFetchStockDetailUseCase!
    private var mockCandlestickUseCase: MockFetchCandlestickUseCase!
    private var mockToggleUseCase: MockToggleFavoriteUseCase!
    private var mockCheckUseCase: MockCheckFavoriteUseCase!
    private var mockFetchGroupIdsUseCase: MockFetchGroupIdsForTickerUseCase!
    private var mockUpdateFavoriteGroupsUseCase: MockUpdateFavoriteGroupsUseCase!
    private var mockMonitor: MockNetworkMonitor!

    override func setUp() async throws {
        try await super.setUp()
        await TechnicalIndicatorSettingsManager.shared.reset()
        mockFetchUseCase = MockFetchStockDetailUseCase()
        mockCandlestickUseCase = MockFetchCandlestickUseCase()
        mockToggleUseCase = MockToggleFavoriteUseCase()
        mockCheckUseCase = MockCheckFavoriteUseCase()
        mockFetchGroupIdsUseCase = MockFetchGroupIdsForTickerUseCase()
        mockUpdateFavoriteGroupsUseCase = MockUpdateFavoriteGroupsUseCase()
        mockMonitor = MockNetworkMonitor(isConnected: true)

        sut = StockDetailStore(
            ticker: "AAPL",
            fetchStockDetailUseCase: mockFetchUseCase,
            fetchCandlestickUseCase: mockCandlestickUseCase,
            toggleFavoriteUseCase: mockToggleUseCase,
            checkFavoriteUseCase: mockCheckUseCase,
            fetchGroupIdsForTickerUseCase: mockFetchGroupIdsUseCase,
            updateFavoriteGroupsUseCase: mockUpdateFavoriteGroupsUseCase,
            networkMonitor: mockMonitor
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchUseCase = nil
        mockCandlestickUseCase = nil
        mockToggleUseCase = nil
        mockCheckUseCase = nil
        mockFetchGroupIdsUseCase = nil
        mockUpdateFavoriteGroupsUseCase = nil
        mockMonitor = nil
        super.tearDown()
    }

    // 에러 상태에서 복구 이벤트 → loadDetail 재호출
    func test_networkRestored_whenErrorMessageExists_retriesLoadDetail() async {
        // Given: 에러 상태 만들기
        mockFetchUseCase.stubbedError = NetworkError.networkDisconnected
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertNotNil(sut.state.errorMessage, "전제조건: 에러 상태여야 함")

        // 이번엔 성공하도록 설정
        mockFetchUseCase.stubbedError = nil
        let callCountBefore = mockFetchUseCase.executeCallCount

        // When: 네트워크 복구 이벤트
        mockMonitor.simulateRestored()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then: loadDetail이 다시 호출됨
        XCTAssertGreaterThan(mockFetchUseCase.executeCallCount, callCountBefore)
    }

    // 정상 상태에서 복구 이벤트 → 재호출 없음
    func test_networkRestored_whenNoError_doesNotRetry() async {
        // Given: 정상 상태 (에러 없음)
        mockFetchUseCase.stubbedError = nil
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertNil(sut.state.errorMessage, "전제조건: 에러 없는 상태여야 함")

        let callCountBefore = mockFetchUseCase.executeCallCount

        // When: 네트워크 복구 이벤트
        mockMonitor.simulateRestored()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then: 추가 호출 없음
        XCTAssertEqual(mockFetchUseCase.executeCallCount, callCountBefore)
    }

    // 차트 에러 상태에서 복구 이벤트 → 차트만 재요청
    func test_networkRestored_whenChartErrorExists_retriesChart() async {
        // Given: 주식 정보는 성공, 차트만 실패
        mockFetchUseCase.stubbedError = nil
        mockCandlestickUseCase.stubbedError = NetworkError.networkDisconnected
        sut.action(.loadDetail)
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertNotNil(sut.state.chartErrorMessage, "전제조건: 차트 에러 상태여야 함")

        mockCandlestickUseCase.stubbedError = nil
        let chartCallCountBefore = mockCandlestickUseCase.executeCallCount
        let detailCallCountBefore = mockFetchUseCase.executeCallCount

        // When: 네트워크 복구
        mockMonitor.simulateRestored()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then: 차트는 재요청, 상세 정보는 재요청 없음
        XCTAssertGreaterThan(mockCandlestickUseCase.executeCallCount, chartCallCountBefore)
        XCTAssertEqual(mockFetchUseCase.executeCallCount, detailCallCountBefore)
    }
}

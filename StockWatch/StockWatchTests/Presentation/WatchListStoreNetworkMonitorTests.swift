//
//  WatchListStoreNetworkMonitorTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Tests

@MainActor
final class WatchListStoreNetworkMonitorTests: XCTestCase {

    private var sut: WatchListStore!
    private var mockFetchUseCase: MockFetchFavoritesUseCase!
    private var mockManageGroupUseCase: MockManageWatchListGroupUseCase!
    private var mockFetchByGroupUseCase: MockFetchFavoritesByGroupUseCase!
    private var mockStockQuoteUseCase: MockFetchStockQuoteUseCase!
    private var mockMonitor: MockNetworkMonitor!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "lastSelectedGroupId")
        mockFetchUseCase = MockFetchFavoritesUseCase()
        mockManageGroupUseCase = MockManageWatchListGroupUseCase()
        mockFetchByGroupUseCase = MockFetchFavoritesByGroupUseCase()
        mockStockQuoteUseCase = MockFetchStockQuoteUseCase()
        mockMonitor = MockNetworkMonitor(isConnected: true)
        sut = makeStore()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "lastSelectedGroupId")
        sut = nil
        mockFetchUseCase = nil
        mockManageGroupUseCase = nil
        mockFetchByGroupUseCase = nil
        mockStockQuoteUseCase = nil
        mockMonitor = nil
        super.tearDown()
    }

    private func makeStore() -> WatchListStore {
        WatchListStore(
            fetchFavoritesUseCase: mockFetchUseCase,
            toggleFavoriteUseCase: MockToggleFavoriteUseCase(),
            manageGroupUseCase: mockManageGroupUseCase,
            fetchFavoritesByGroupUseCase: mockFetchByGroupUseCase,
            addFavoriteToGroupUseCase: MockAddFavoriteToGroupUseCase(),
            fetchStockQuoteUseCase: mockStockQuoteUseCase,
            fetchGroupIdsForTickerUseCase: MockFetchGroupIdsForTickerUseCase(),
            updateFavoriteGroupsUseCase: MockUpdateFavoriteGroupsUseCase(),
            fetchSparklineUseCase: MockFetchSparklineUseCase(),
            fetchExchangeRateUseCase: MockFetchExchangeRateUseCase(),
            networkMonitor: mockMonitor
        )
    }

    // 즐겨찾기가 있고 가격 데이터 없는 상태에서 복구 → loadGroups 재호출
    func test_networkRestored_whenFavoritesExistButNoPriceData_retriesLoad() async {
        // Given: 즐겨찾기 목록은 있지만 가격 로드는 실패
        let group = WatchListGroup(id: UUID(), name: "전체", createdAt: Date())
        mockManageGroupUseCase.stubbedGroups = [group]
        mockFetchByGroupUseCase.stubbedResult = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        mockStockQuoteUseCase.stubbedError = NetworkError.networkDisconnected

        sut.action(.loadGroups)
        try? await Task.sleep(nanoseconds: 150_000_000)

        // 즐겨찾기는 있지만 가격 데이터 없음
        XCTAssertFalse(sut.state.favorites.isEmpty, "전제조건: 즐겨찾기 있어야 함")
        XCTAssertTrue(sut.state.priceData.isEmpty, "전제조건: 가격 데이터 없어야 함")

        // 이번엔 성공하도록
        mockStockQuoteUseCase.stubbedError = nil

        // When: 네트워크 복구
        mockMonitor.simulateRestored()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then: 가격 데이터가 채워짐
        XCTAssertFalse(sut.state.priceData.isEmpty)
    }

    // 빈 즐겨찾기 상태에서 복구 이벤트 → 불필요한 재요청 없음
    func test_networkRestored_whenNoFavorites_doesNotRetry() async {
        // Given: 그룹은 있지만 즐겨찾기 없음
        let group = WatchListGroup(id: UUID(), name: "전체", createdAt: Date())
        mockManageGroupUseCase.stubbedGroups = [group]
        mockFetchByGroupUseCase.stubbedResult = []

        sut.action(.loadGroups)
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertTrue(sut.state.favorites.isEmpty, "전제조건: 즐겨찾기 없어야 함")

        // When: 네트워크 복구
        mockMonitor.simulateRestored()
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Then: priceData는 여전히 비어있음 (재요청 의미 없음)
        XCTAssertTrue(sut.state.priceData.isEmpty)
    }
}

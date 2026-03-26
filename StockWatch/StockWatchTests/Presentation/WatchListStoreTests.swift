//
//  WatchListStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockFetchFavoritesUseCase: FetchFavoritesUseCaseProtocol {
    var stubbedResult: [FavoriteItem] = []
    func execute() async -> [FavoriteItem] { stubbedResult }
}

@MainActor
final class MockManageWatchListGroupUseCase: ManageWatchListGroupUseCaseProtocol {
    var stubbedGroups: [WatchListGroup] = []
    var stubbedError: Error?
    var capturedOrderedIds: [UUID]?

    func fetchGroups() async -> [WatchListGroup] { stubbedGroups }
    func createGroup(name: String) async throws -> WatchListGroup {
        WatchListGroup(id: UUID(), name: name, createdAt: Date())
    }
    func deleteGroup(id: UUID) async throws {
        stubbedGroups.removeAll { $0.id == id }
    }
    func renameGroup(id: UUID, name: String) async throws {}
    func reorderGroups(orderedIds: [UUID]) async throws {
        if let error = stubbedError { throw error }
        capturedOrderedIds = orderedIds
    }
}

final class MockFetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCaseProtocol {
    var stubbedResult: [FavoriteItem] = []
    func execute(groupId: UUID) async -> [FavoriteItem] { stubbedResult }
}

final class MockAddFavoriteToGroupUseCase: AddFavoriteToGroupUseCaseProtocol {
    func execute(ticker: String, companyName: String, logoURL: String, groupId: UUID) async throws {}
}

final class MockFetchSparklineUseCase: FetchSparklineUseCaseProtocol {
    var stubbedResult: SparklineData?
    var stubbedError: Error?
    func execute(ticker: String) async throws -> SparklineData {
        if let error = stubbedError { throw error }
        return stubbedResult ?? SparklineData(ticker: ticker, closePrices: [])
    }
}

final class MockFetchStockQuoteUseCase: FetchStockQuoteUseCaseProtocol {
    var stubbedResult: StockQuote = StockQuote(ticker: "", currentPrice: 0, priceChangePercent: 0, currency: "USD")
    var stubbedError: Error?
    func execute(ticker: String) async throws -> StockQuote {
        if let error = stubbedError { throw error }
        return StockQuote(ticker: ticker, currentPrice: stubbedResult.currentPrice, priceChangePercent: stubbedResult.priceChangePercent, currency: stubbedResult.currency)
    }
}

// MARK: - Tests

@MainActor
final class WatchListStoreTests: XCTestCase {

    private var sut: WatchListStore!
    private var mockFetchUseCase: MockFetchFavoritesUseCase!
    private var mockToggleUseCase: MockToggleFavoriteUseCase!
    private var mockManageGroupUseCase: MockManageWatchListGroupUseCase!
    private var mockFetchByGroupUseCase: MockFetchFavoritesByGroupUseCase!
    private var mockFetchStockQuoteUseCase: MockFetchStockQuoteUseCase!

    override func setUp() {
        super.setUp()
        // 테스트 간 UserDefaults 격리
        UserDefaults.standard.removeObject(forKey: "lastSelectedGroupId")
        mockFetchUseCase = MockFetchFavoritesUseCase()
        mockToggleUseCase = MockToggleFavoriteUseCase()
        mockManageGroupUseCase = MockManageWatchListGroupUseCase()
        mockFetchByGroupUseCase = MockFetchFavoritesByGroupUseCase()
        mockFetchStockQuoteUseCase = MockFetchStockQuoteUseCase()
        sut = makeStore()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "lastSelectedGroupId")
        sut = nil
        mockFetchUseCase = nil
        mockToggleUseCase = nil
        mockManageGroupUseCase = nil
        mockFetchByGroupUseCase = nil
        mockFetchStockQuoteUseCase = nil
        super.tearDown()
    }

    private func makeStore(state: WatchListState = WatchListState()) -> WatchListStore {
        WatchListStore(
            fetchFavoritesUseCase: mockFetchUseCase,
            toggleFavoriteUseCase: mockToggleUseCase,
            manageGroupUseCase: mockManageGroupUseCase,
            fetchFavoritesByGroupUseCase: mockFetchByGroupUseCase,
            addFavoriteToGroupUseCase: MockAddFavoriteToGroupUseCase(),
            fetchStockQuoteUseCase: mockFetchStockQuoteUseCase,
            fetchGroupIdsForTickerUseCase: MockFetchGroupIdsForTickerUseCase(),
            updateFavoriteGroupsUseCase: MockUpdateFavoriteGroupsUseCase(),
            fetchSparklineUseCase: MockFetchSparklineUseCase(),
            state: state
        )
    }

    // MARK: - loadFavorites

    func test_action_loadFavorites_updatesFavorites() async {
        // Arrange
        let group = WatchListGroup(id: UUID(), name: "전체", createdAt: Date())
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla, Inc.", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        mockManageGroupUseCase.stubbedGroups = [group]
        mockFetchByGroupUseCase.stubbedResult = items

        // Act — loadGroups가 내부적으로 loadFavorites를 호출함
        sut.action(.loadGroups)
        for _ in 0..<4 { await Task.yield() }

        // Assert
        XCTAssertEqual(sut.state.favorites.count, 2)
        XCTAssertEqual(sut.state.favorites[0].ticker, "AAPL")
        XCTAssertEqual(sut.state.favorites[1].ticker, "TSLA")
    }

    func test_action_loadFavorites_whenNoGroups_setsFavoritesEmpty() async {
        // Arrange
        mockManageGroupUseCase.stubbedGroups = []
        sut.action(.loadGroups)
        await Task.yield()

        // Act
        sut.action(.loadFavorites)
        await Task.yield()

        // Assert
        XCTAssertTrue(sut.state.favorites.isEmpty)
    }

    // MARK: - removeFavorite

    func test_action_removeFavorite_removesOptimistically() async {
        // Arrange
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla, Inc.", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        sut = makeStore(state: WatchListState(favorites: items))
        mockToggleUseCase.stubbedResult = false

        // Act
        sut.action(.removeFavorite(ticker: "AAPL"))

        // Assert (낙관적 즉시 제거)
        XCTAssertEqual(sut.state.favorites.count, 1)
        XCTAssertEqual(sut.state.favorites[0].ticker, "TSLA")
    }

    func test_action_removeFavorite_rollsBackOnError() async {
        // Arrange
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        sut = makeStore(state: WatchListState(favorites: items))
        mockToggleUseCase.stubbedError = NSError(domain: "TestError", code: 1)

        // Act
        sut.action(.removeFavorite(ticker: "AAPL"))
        for _ in 0..<4 { await Task.yield() }

        // Assert (에러 시 롤백)
        XCTAssertEqual(sut.state.favorites.count, 1)
    }

    // MARK: - selectTicker

    func test_action_selectTicker_updatesSelectedTicker() {
        sut.action(.selectTicker("AAPL"))
        XCTAssertEqual(sut.state.selectedTicker, "AAPL")
    }

    func test_action_selectTicker_differentTickers_updatesCorrectly() {
        sut.action(.selectTicker("AAPL"))
        XCTAssertEqual(sut.state.selectedTicker, "AAPL")

        sut.action(.selectTicker("GOOGL"))
        XCTAssertEqual(sut.state.selectedTicker, "GOOGL")
    }

    // MARK: - selectedTickerBinding

    func test_selectedTickerBinding_get_returnsCurrentSelectedTicker() {
        sut.action(.selectTicker("TSLA"))
        XCTAssertEqual(sut.selectedTickerBinding.wrappedValue, "TSLA")
    }

    func test_selectedTickerBinding_setNil_resetsSelectedTicker() {
        sut.action(.selectTicker("AAPL"))
        sut.selectedTickerBinding.wrappedValue = nil
        XCTAssertNil(sut.state.selectedTicker)
    }

    func test_selectedTickerBinding_initialValue_isNil() {
        XCTAssertNil(sut.selectedTickerBinding.wrappedValue)
    }

    // MARK: - loadGroups

    func test_action_loadGroups_whenNoGroups_setsEmptyDbGroups() async {
        // Arrange
        mockManageGroupUseCase.stubbedGroups = []

        // Act
        sut.action(.loadGroups)
        await Task.yield()

        // Assert
        XCTAssertTrue(sut.state.dbGroups.isEmpty)
    }

    func test_action_loadGroups_setsDbGroups() async {
        // Arrange
        let groups = [
            WatchListGroup(id: UUID(), name: "기술주", createdAt: Date()),
            WatchListGroup(id: UUID(), name: "배당주", createdAt: Date())
        ]
        mockManageGroupUseCase.stubbedGroups = groups

        // Act
        sut.action(.loadGroups)
        await Task.yield()

        // Assert
        XCTAssertEqual(sut.state.dbGroups.count, 2)
    }

    func test_action_loadGroups_restoresLastSelectedGroupById_whenGroupExists() async {
        // Arrange
        let targetId = UUID()
        let groups = [
            WatchListGroup(id: UUID(), name: "기술주", createdAt: Date()),
            WatchListGroup(id: targetId, name: "배당주", createdAt: Date())
        ]
        mockManageGroupUseCase.stubbedGroups = groups
        UserDefaults.standard.set(targetId.uuidString, forKey: "lastSelectedGroupId")

        // Act
        sut.action(.loadGroups)
        await Task.yield()

        // Assert — 저장된 ID의 그룹 인덱스(1)로 복원
        XCTAssertEqual(sut.state.selectedGroupIndex, 1)
    }

    func test_action_loadGroups_fallsBackToFirstGroup_whenSavedIdNotFound() async {
        // Arrange
        let groups = [WatchListGroup(id: UUID(), name: "기술주", createdAt: Date())]
        mockManageGroupUseCase.stubbedGroups = groups
        UserDefaults.standard.set(UUID().uuidString, forKey: "lastSelectedGroupId")  // 존재하지 않는 ID

        // Act
        sut.action(.loadGroups)
        await Task.yield()

        // Assert — 폴백: 첫 번째 그룹(index 0)
        XCTAssertEqual(sut.state.selectedGroupIndex, 0)
    }

    // MARK: - selectGroup

    func test_action_selectGroup_savesGroupId() async {
        // Arrange
        let groupId = UUID()
        let groups = [
            WatchListGroup(id: UUID(), name: "기술주", createdAt: Date()),
            WatchListGroup(id: groupId, name: "배당주", createdAt: Date())
        ]
        mockManageGroupUseCase.stubbedGroups = groups
        sut.action(.loadGroups)
        await Task.yield()

        // Act
        sut.action(.selectGroup(index: 1))

        // Assert — UserDefaults에 선택된 그룹 ID 저장
        let saved = UserDefaults.standard.string(forKey: "lastSelectedGroupId")
        XCTAssertEqual(saved, groupId.uuidString)
    }

    // MARK: - deleteGroup

    func test_action_deleteGroup_lastGroupDeleted_setsEmptyGroups() async {
        // Arrange
        let group = WatchListGroup(id: UUID(), name: "유일한 그룹", createdAt: Date())
        mockManageGroupUseCase.stubbedGroups = [group]
        sut.action(.loadGroups)
        await Task.yield()

        // Act
        sut.action(.deleteGroup(id: group.id))
        await Task.yield()

        // Assert
        XCTAssertTrue(sut.state.dbGroups.isEmpty)
        XCTAssertEqual(sut.state.selectedGroupIndex, 0)
    }

    // MARK: - priceData

    func test_loadGroups_withFavorites_populatesPriceDataAfterLoad() async {
        // Arrange
        let group = WatchListGroup(id: UUID(), name: "전체", createdAt: Date())
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        mockManageGroupUseCase.stubbedGroups = [group]
        mockFetchByGroupUseCase.stubbedResult = items
        mockFetchStockQuoteUseCase.stubbedResult = StockQuote(ticker: "AAPL", currentPrice: 150.0, priceChangePercent: 1.5, currency: "USD")

        // Act
        sut.action(.loadGroups)
        for _ in 0..<8 { await Task.yield() }

        // Assert
        XCTAssertFalse(sut.state.priceData.isEmpty)
        XCTAssertEqual(sut.state.priceData["AAPL"]?.currentPrice, 150.0)
    }

    func test_loadGroups_whenPriceFetchFails_favoritesStillLoaded() async {
        // Arrange
        let group = WatchListGroup(id: UUID(), name: "전체", createdAt: Date())
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        mockManageGroupUseCase.stubbedGroups = [group]
        mockFetchByGroupUseCase.stubbedResult = items
        mockFetchStockQuoteUseCase.stubbedError = NetworkError.serverError

        // Act
        sut.action(.loadGroups)
        for _ in 0..<8 { await Task.yield() }

        // Assert — favorites는 정상 로드, priceData만 비어있음
        XCTAssertEqual(sut.state.favorites.count, 1)
        XCTAssertTrue(sut.state.priceData.isEmpty)
    }

    // MARK: - reorderGroups

    func test_action_reorderGroups_updatesDbGroupsOptimistically() async {
        // Arrange
        let g1 = WatchListGroup(id: UUID(), name: "A", createdAt: Date(), sortOrder: 0)
        let g2 = WatchListGroup(id: UUID(), name: "B", createdAt: Date(), sortOrder: 1)
        let g3 = WatchListGroup(id: UUID(), name: "C", createdAt: Date(), sortOrder: 2)
        mockManageGroupUseCase.stubbedGroups = [g1, g2, g3]
        sut.action(.loadGroups)
        await Task.yield()

        // Act: C, A, B 순서로 재배치
        sut.action(.reorderGroups(orderedIds: [g3.id, g1.id, g2.id]))

        // Assert 즉시 (낙관적 업데이트)
        XCTAssertEqual(sut.state.dbGroups.map(\.name), ["C", "A", "B"])
    }

    func test_action_reorderGroups_callsUseCaseWithOrderedIds() async {
        // Arrange
        let g1 = WatchListGroup(id: UUID(), name: "A", createdAt: Date(), sortOrder: 0)
        let g2 = WatchListGroup(id: UUID(), name: "B", createdAt: Date(), sortOrder: 1)
        mockManageGroupUseCase.stubbedGroups = [g1, g2]
        sut.action(.loadGroups)
        await Task.yield()

        // Act
        sut.action(.reorderGroups(orderedIds: [g2.id, g1.id]))
        for _ in 0..<4 { await Task.yield() }

        // Assert
        XCTAssertEqual(mockManageGroupUseCase.capturedOrderedIds, [g2.id, g1.id])
    }

    func test_action_reorderGroups_whenUseCaseThrows_rollsBackDbGroups() async {
        // Arrange
        let g1 = WatchListGroup(id: UUID(), name: "A", createdAt: Date(), sortOrder: 0)
        let g2 = WatchListGroup(id: UUID(), name: "B", createdAt: Date(), sortOrder: 1)
        mockManageGroupUseCase.stubbedGroups = [g1, g2]
        sut.action(.loadGroups)
        await Task.yield()
        mockManageGroupUseCase.stubbedError = NSError(domain: "TestError", code: 1)

        // Act
        sut.action(.reorderGroups(orderedIds: [g2.id, g1.id]))
        for _ in 0..<4 { await Task.yield() }

        // Assert: 에러 시 원래 순서로 롤백
        XCTAssertEqual(sut.state.dbGroups.map(\.name), ["A", "B"])
    }

    func test_action_beginGroupDrag_setsDraggedGroupId() {
        // Arrange
        let groupId = UUID()

        // Act
        sut.action(.beginGroupDrag(groupId: groupId))

        // Assert
        XCTAssertEqual(sut.state.draggedGroupId, groupId)
        XCTAssertTrue(sut.state.isDraggingGroup)
    }

    func test_action_endGroupDrag_clearsDragState() {
        // Arrange
        let groupId = UUID()
        sut.action(.beginGroupDrag(groupId: groupId))
        sut.action(.updateGroupDragTarget(index: 2))

        // Act
        sut.action(.endGroupDrag)

        // Assert
        XCTAssertNil(sut.state.draggedGroupId)
        XCTAssertNil(sut.state.dragTargetIndex)
        XCTAssertFalse(sut.state.isDraggingGroup)
    }

    func test_action_reorderGroups_clearsDragState() async {
        // Arrange
        let g1 = WatchListGroup(id: UUID(), name: "A", createdAt: Date(), sortOrder: 0)
        mockManageGroupUseCase.stubbedGroups = [g1]
        sut.action(.loadGroups)
        await Task.yield()
        sut.action(.beginGroupDrag(groupId: g1.id))

        // Act
        sut.action(.reorderGroups(orderedIds: [g1.id]))

        // Assert: reorder 시 drag 상태 즉시 초기화
        XCTAssertNil(sut.state.draggedGroupId)
    }

    // MARK: - toggleSort

    func test_action_toggleSort_name_cyclesNoneAscDescNone() {
        // 초기: 정렬 없음
        XCTAssertNil(sut.state.sortCriteria)

        // 1탭: 오름차순
        sut.action(.toggleSort(.name))
        XCTAssertEqual(sut.state.sortCriteria, .name)
        XCTAssertEqual(sut.state.sortDirection, .ascending)

        // 2탭: 내림차순
        sut.action(.toggleSort(.name))
        XCTAssertEqual(sut.state.sortCriteria, .name)
        XCTAssertEqual(sut.state.sortDirection, .descending)

        // 3탭: 해제
        sut.action(.toggleSort(.name))
        XCTAssertNil(sut.state.sortCriteria)
        XCTAssertEqual(sut.state.sortDirection, .ascending)
    }

    func test_action_toggleSort_switchColumn_resetsToAsc() {
        // name 오름차순
        sut.action(.toggleSort(.name))
        XCTAssertEqual(sut.state.sortCriteria, .name)

        // price로 전환 → 오름차순
        sut.action(.toggleSort(.price))
        XCTAssertEqual(sut.state.sortCriteria, .price)
        XCTAssertEqual(sut.state.sortDirection, .ascending)
    }

    func test_sortedFavorites_byNameAsc_sortsAlphabetically() {
        // Arrange — companyName으로 정렬 (KoreanStockDictionary는 테스트에서 비어있으므로 fallback)
        let items = [
            FavoriteItem(ticker: "TSLA", companyName: "Tesla", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "AAPL", companyName: "Apple", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        sut = makeStore(state: WatchListState(favorites: items))
        sut.action(.toggleSort(.name)) // ascending

        // Act
        let sorted = sut.sortedFavorites

        // Assert
        XCTAssertEqual(sorted[0].ticker, "AAPL")
        XCTAssertEqual(sorted[1].ticker, "TSLA")
    }

    func test_sortedFavorites_byNameDesc_sortsReverse() {
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        sut = makeStore(state: WatchListState(favorites: items))
        sut.action(.toggleSort(.name)) // asc
        sut.action(.toggleSort(.name)) // desc

        let sorted = sut.sortedFavorites
        XCTAssertEqual(sorted[0].ticker, "TSLA")
        XCTAssertEqual(sorted[1].ticker, "AAPL")
    }

    func test_sortedFavorites_byPriceAsc_sortsByCurrentPrice() {
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        var state = WatchListState(favorites: items)
        state.priceData = [
            "AAPL": StockQuote(ticker: "AAPL", currentPrice: 150.0, priceChangePercent: 1.0, currency: "USD"),
            "TSLA": StockQuote(ticker: "TSLA", currentPrice: 70.0, priceChangePercent: -2.0, currency: "USD")
        ]
        sut = makeStore(state: state)
        sut.action(.toggleSort(.price)) // ascending

        let sorted = sut.sortedFavorites
        XCTAssertEqual(sorted[0].ticker, "TSLA") // 70 < 150
        XCTAssertEqual(sorted[1].ticker, "AAPL")
    }

    func test_sortedFavorites_byChangePercentDesc_sortsByChangePercent() {
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        var state = WatchListState(favorites: items)
        state.priceData = [
            "AAPL": StockQuote(ticker: "AAPL", currentPrice: 150.0, priceChangePercent: 1.0, currency: "USD"),
            "TSLA": StockQuote(ticker: "TSLA", currentPrice: 70.0, priceChangePercent: -2.0, currency: "USD")
        ]
        sut = makeStore(state: state)
        sut.action(.toggleSort(.changePercent)) // asc
        sut.action(.toggleSort(.changePercent)) // desc

        let sorted = sut.sortedFavorites
        XCTAssertEqual(sorted[0].ticker, "AAPL") // 1.0 > -2.0
        XCTAssertEqual(sorted[1].ticker, "TSLA")
    }

    func test_sortedFavorites_none_returnsOriginalOrder() {
        let items = [
            FavoriteItem(ticker: "TSLA", companyName: "Tesla", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "AAPL", companyName: "Apple", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        sut = makeStore(state: WatchListState(favorites: items))

        // 정렬 없음 — 원본 순서
        let sorted = sut.sortedFavorites
        XCTAssertEqual(sorted[0].ticker, "TSLA")
        XCTAssertEqual(sorted[1].ticker, "AAPL")
    }

    func test_sortedFavorites_byPrice_missingPriceData_placedAtEnd() {
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        var state = WatchListState(favorites: items)
        state.priceData = [
            "TSLA": StockQuote(ticker: "TSLA", currentPrice: 70.0, priceChangePercent: -2.0, currency: "USD")
        ]
        sut = makeStore(state: state)
        sut.action(.toggleSort(.price)) // ascending

        let sorted = sut.sortedFavorites
        XCTAssertEqual(sorted[0].ticker, "TSLA") // has price
        XCTAssertEqual(sorted[1].ticker, "AAPL") // no price → end
    }

    // MARK: - deleteGroup (continued)

    func test_action_deleteGroup_currentGroupDeleted_selectsFirstRemaining() async {
        // Arrange
        let group1 = WatchListGroup(id: UUID(), name: "그룹1", createdAt: Date())
        let group2 = WatchListGroup(id: UUID(), name: "그룹2", createdAt: Date())
        mockManageGroupUseCase.stubbedGroups = [group1, group2]
        sut.action(.loadGroups)
        await Task.yield()
        sut.action(.selectGroup(index: 1))

        // Act — 현재 선택된 그룹2 삭제
        sut.action(.deleteGroup(id: group2.id))
        await Task.yield()

        // Assert — 남은 첫 번째 그룹으로 이동
        XCTAssertEqual(sut.state.dbGroups.count, 1)
        XCTAssertEqual(sut.state.selectedGroupIndex, 0)
    }
}

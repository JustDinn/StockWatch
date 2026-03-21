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
    var stubbedDefaultGroup: WatchListGroup?
    var ensureDefaultGroupCallCount = 0

    func fetchGroups() async -> [WatchListGroup] { stubbedGroups }
    func createGroup(name: String) async throws -> WatchListGroup {
        WatchListGroup(id: UUID(), name: name, createdAt: Date(), isDefault: false)
    }
    func deleteGroup(id: UUID) async throws { }
    func ensureDefaultGroup() async throws -> WatchListGroup {
        ensureDefaultGroupCallCount += 1
        return stubbedDefaultGroup ?? WatchListGroup(id: UUID(), name: "전체", createdAt: Date(), isDefault: true)
    }
}

final class MockFetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCaseProtocol {
    var stubbedResult: [FavoriteItem] = []
    func execute(groupId: UUID) async -> [FavoriteItem] { stubbedResult }
}

// MARK: - Tests

@MainActor
final class WatchListStoreTests: XCTestCase {

    private var sut: WatchListStore!
    private var mockFetchUseCase: MockFetchFavoritesUseCase!
    private var mockToggleUseCase: MockToggleFavoriteUseCase!
    private var mockManageGroupUseCase: MockManageWatchListGroupUseCase!
    private var mockFetchByGroupUseCase: MockFetchFavoritesByGroupUseCase!

    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchFavoritesUseCase()
        mockToggleUseCase = MockToggleFavoriteUseCase()
        mockManageGroupUseCase = MockManageWatchListGroupUseCase()
        mockFetchByGroupUseCase = MockFetchFavoritesByGroupUseCase()
        sut = makeStore()
    }

    override func tearDown() {
        sut = nil
        mockFetchUseCase = nil
        mockToggleUseCase = nil
        mockManageGroupUseCase = nil
        mockFetchByGroupUseCase = nil
        super.tearDown()
    }

    private func makeStore(state: WatchListState = WatchListState()) -> WatchListStore {
        WatchListStore(
            fetchFavoritesUseCase: mockFetchUseCase,
            toggleFavoriteUseCase: mockToggleUseCase,
            manageGroupUseCase: mockManageGroupUseCase,
            fetchFavoritesByGroupUseCase: mockFetchByGroupUseCase,
            state: state
        )
    }

    // MARK: - loadFavorites

    func test_action_loadFavorites_updatesFavorites() async {
        // Arrange
        let items = [
            FavoriteItem(ticker: "AAPL", companyName: "Apple Inc.", addedAt: Date(), logoURL: "", groupIds: []),
            FavoriteItem(ticker: "TSLA", companyName: "Tesla, Inc.", addedAt: Date(), logoURL: "", groupIds: [])
        ]
        mockFetchUseCase.stubbedResult = items

        // Act
        sut.action(.loadFavorites)
        await Task.yield()

        // Assert
        XCTAssertEqual(sut.state.favorites.count, 2)
        XCTAssertEqual(sut.state.favorites[0].ticker, "AAPL")
        XCTAssertEqual(sut.state.favorites[1].ticker, "TSLA")
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
        await Task.yield()

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

    // MARK: - loadGroups (ensureDefaultGroup 보장)

    func test_action_loadGroups_ensuresDefaultGroupExists() async {
        // Arrange
        let defaultGroup = WatchListGroup(id: UUID(), name: "전체", createdAt: Date(), isDefault: true)
        mockManageGroupUseCase.stubbedDefaultGroup = defaultGroup
        mockManageGroupUseCase.stubbedGroups = [defaultGroup]

        // Act
        sut.action(.loadGroups)
        await Task.yield()

        // Assert — ensureDefaultGroup이 호출되었는지 확인
        XCTAssertEqual(mockManageGroupUseCase.ensureDefaultGroupCallCount, 1)
    }

    func test_groups_computedProperty_usesDefaultGroupName() async {
        // Arrange
        let defaultGroup = WatchListGroup(id: UUID(), name: "전체", createdAt: Date(), isDefault: true)
        let userGroup = WatchListGroup(id: UUID(), name: "기술주", createdAt: Date(), isDefault: false)
        mockManageGroupUseCase.stubbedGroups = [defaultGroup, userGroup]
        mockManageGroupUseCase.stubbedDefaultGroup = defaultGroup

        // Act
        sut.action(.loadGroups)
        await Task.yield()

        // Assert — groups는 dbGroups.map(\.name), "전체"가 첫 번째
        XCTAssertEqual(sut.state.groups, ["전체", "기술주"])
        XCTAssertEqual(sut.state.groups.first, "전체")
    }
}

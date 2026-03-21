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

    func fetchGroups() async -> [WatchListGroup] { stubbedGroups }
    func createGroup(name: String) async throws -> WatchListGroup {
        WatchListGroup(id: UUID(), name: name, createdAt: Date())
    }
    func deleteGroup(id: UUID) async throws {
        stubbedGroups.removeAll { $0.id == id }
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
        // 테스트 간 UserDefaults 격리
        UserDefaults.standard.removeObject(forKey: "lastSelectedGroupId")
        mockFetchUseCase = MockFetchFavoritesUseCase()
        mockToggleUseCase = MockToggleFavoriteUseCase()
        mockManageGroupUseCase = MockManageWatchListGroupUseCase()
        mockFetchByGroupUseCase = MockFetchFavoritesByGroupUseCase()
        sut = makeStore()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "lastSelectedGroupId")
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

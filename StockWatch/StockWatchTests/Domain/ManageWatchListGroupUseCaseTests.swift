//
//  ManageWatchListGroupUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

@MainActor
final class MockWatchListGroupRepository: WatchListGroupRepositoryProtocol {
    var stubbedGroups: [WatchListGroup] = []
    var stubbedCreatedGroup: WatchListGroup?
    var stubbedError: Error?
    var capturedOrderedIds: [UUID]?

    func fetchAllGroups() async -> [WatchListGroup] {
        stubbedGroups
    }

    func createGroup(name: String) async throws -> WatchListGroup {
        if let error = stubbedError { throw error }
        return stubbedCreatedGroup ?? WatchListGroup(id: UUID(), name: name, createdAt: Date())
    }

    func deleteGroup(id: UUID) async throws {
        if let error = stubbedError { throw error }
        stubbedGroups.removeAll { $0.id == id }
    }

    func renameGroup(id: UUID, name: String) async throws {
        if let error = stubbedError { throw error }
    }

    func reorderGroups(orderedIds: [UUID]) async throws {
        if let error = stubbedError { throw error }
        capturedOrderedIds = orderedIds
    }
}

// MARK: - Tests

final class ManageWatchListGroupUseCaseTests: XCTestCase {

    private var sut: ManageWatchListGroupUseCase!
    private var mockRepository: MockWatchListGroupRepository!

    @MainActor
    override func setUp() {
        super.setUp()
        mockRepository = MockWatchListGroupRepository()
        sut = ManageWatchListGroupUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - fetchGroups

    @MainActor
    func test_fetchGroups_whenEmpty_returnsEmptyArray() async {
        // Arrange
        mockRepository.stubbedGroups = []

        // Act
        let result = await sut.fetchGroups()

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    @MainActor
    func test_fetchGroups_returnsAllGroups() async {
        // Arrange
        let now = Date()
        let groups = [
            WatchListGroup(id: UUID(), name: "기술주", createdAt: now),
            WatchListGroup(id: UUID(), name: "배당주", createdAt: now.addingTimeInterval(1))
        ]
        mockRepository.stubbedGroups = groups

        // Act
        let result = await sut.fetchGroups()

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "기술주")
        XCTAssertEqual(result[1].name, "배당주")
    }

    // MARK: - reorderGroups

    @MainActor
    func test_reorderGroups_callsRepositoryWithOrderedIds() async throws {
        // Arrange
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        // Act
        try await sut.reorderGroups(orderedIds: [id3, id1, id2])

        // Assert
        XCTAssertEqual(mockRepository.capturedOrderedIds, [id3, id1, id2])
    }

    @MainActor
    func test_reorderGroups_whenRepositoryThrows_propagatesError() async {
        // Arrange
        mockRepository.stubbedError = NSError(domain: "TestError", code: 1)

        // Act & Assert
        do {
            try await sut.reorderGroups(orderedIds: [UUID()])
            XCTFail("에러가 전파되어야 합니다")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - deleteGroup

    @MainActor
    func test_deleteGroup_whenLastGroup_succeeds() async throws {
        // Arrange
        let group = WatchListGroup(id: UUID(), name: "유일한 그룹", createdAt: Date())
        mockRepository.stubbedGroups = [group]

        // Act & Assert — 예외 없이 삭제
        try await sut.deleteGroup(id: group.id)
        let remaining = await sut.fetchGroups()
        XCTAssertTrue(remaining.isEmpty)
    }
}

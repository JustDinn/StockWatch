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

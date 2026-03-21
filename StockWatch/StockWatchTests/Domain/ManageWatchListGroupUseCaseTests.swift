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
    var ensureDefaultGroupCallCount = 0
    var stubbedDefaultGroup: WatchListGroup?

    func fetchAllGroups() async -> [WatchListGroup] {
        stubbedGroups
    }

    func createGroup(name: String) async throws -> WatchListGroup {
        if let error = stubbedError { throw error }
        return stubbedCreatedGroup ?? WatchListGroup(id: UUID(), name: name, createdAt: Date(), isDefault: false)
    }

    func deleteGroup(id: UUID) async throws {
        if let error = stubbedError { throw error }
    }

    func ensureDefaultGroup() async throws -> WatchListGroup {
        ensureDefaultGroupCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedDefaultGroup ?? WatchListGroup(id: UUID(), name: "전체", createdAt: Date(), isDefault: true)
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

    // MARK: - ensureDefaultGroup

    @MainActor
    func test_ensureDefaultGroup_createsDefaultIfNotExists() async throws {
        // Arrange
        let expectedGroup = WatchListGroup(id: UUID(), name: "전체", createdAt: Date(), isDefault: true)
        mockRepository.stubbedDefaultGroup = expectedGroup

        // Act
        let result = try await sut.ensureDefaultGroup()

        // Assert
        XCTAssertEqual(mockRepository.ensureDefaultGroupCallCount, 1)
        XCTAssertTrue(result.isDefault)
        XCTAssertEqual(result.name, "전체")
    }

    @MainActor
    func test_ensureDefaultGroup_idempotent_whenAlreadyExists() async throws {
        // Arrange
        let existingDefault = WatchListGroup(id: UUID(), name: "전체", createdAt: Date(), isDefault: true)
        mockRepository.stubbedDefaultGroup = existingDefault

        // Act
        let first = try await sut.ensureDefaultGroup()
        let second = try await sut.ensureDefaultGroup()

        // Assert — 두 번 호출해도 동일한 그룹(id 동일) 반환
        XCTAssertEqual(mockRepository.ensureDefaultGroupCallCount, 2)
        XCTAssertEqual(first.id, second.id)
        XCTAssertTrue(second.isDefault)
    }

    // MARK: - fetchGroups

    @MainActor
    func test_fetchGroups_returnsAllGroups() async {
        // Arrange
        let groups = [
            WatchListGroup(id: UUID(), name: "전체", createdAt: Date(), isDefault: true),
            WatchListGroup(id: UUID(), name: "기술주", createdAt: Date(), isDefault: false)
        ]
        mockRepository.stubbedGroups = groups

        // Act
        let result = await sut.fetchGroups()

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result[0].isDefault)
        XCTAssertFalse(result[1].isDefault)
    }
}

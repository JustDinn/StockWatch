//
//  WatchListGroupRepositoryTests.swift
//  StockWatchTests
//

import XCTest
import SwiftData
@testable import StockWatch

final class WatchListGroupRepositoryTests: XCTestCase {

    private var sut: WatchListGroupRepository!
    private var modelContext: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        let container = try! ModelContainer(
            for: WatchListGroupModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = ModelContext(container)
        sut = WatchListGroupRepository(modelContext: modelContext)
    }

    override func tearDown() {
        sut = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - fetchAllGroups

    @MainActor
    func test_fetchAllGroups_whenEmpty_returnsEmptyArray() async {
        // Act
        let result = await sut.fetchAllGroups()

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    @MainActor
    func test_fetchAllGroups_orderedByCreatedAt_ascending() async throws {
        // Arrange
        let older = WatchListGroupModel(name: "오래된 그룹")
        older.createdAt = Date(timeIntervalSince1970: 1000)
        let newer = WatchListGroupModel(name: "새 그룹")
        newer.createdAt = Date(timeIntervalSince1970: 2000)
        modelContext.insert(older)
        modelContext.insert(newer)
        try modelContext.save()

        // Act
        let result = await sut.fetchAllGroups()

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "오래된 그룹")
        XCTAssertEqual(result[1].name, "새 그룹")
    }

    // MARK: - createGroup

    @MainActor
    func test_createGroup_succeeds() async throws {
        // Act
        let result = try await sut.createGroup(name: "기술주")

        // Assert
        XCTAssertEqual(result.name, "기술주")
        let all = await sut.fetchAllGroups()
        XCTAssertEqual(all.count, 1)
    }

    @MainActor
    func test_createGroup_withDuplicateName_throwsDuplicateNameError() async throws {
        // Arrange
        _ = try await sut.createGroup(name: "기술주")

        // Act & Assert
        do {
            _ = try await sut.createGroup(name: "기술주")
            XCTFail("중복 이름에서 에러가 발생해야 합니다")
        } catch WatchListGroupError.duplicateName {
            // 기대한 에러
        }
    }

    // MARK: - deleteGroup

    @MainActor
    func test_deleteGroup_lastGroup_deletesSuccessfully() async throws {
        // Arrange
        let group = try await sut.createGroup(name: "유일한 그룹")

        // Act
        try await sut.deleteGroup(id: group.id)

        // Assert — 그룹 0개 허용
        let remaining = await sut.fetchAllGroups()
        XCTAssertTrue(remaining.isEmpty)
    }

    @MainActor
    func test_deleteGroup_removesOnlyTargetGroup() async throws {
        // Arrange
        let group1 = try await sut.createGroup(name: "그룹1")
        _ = try await sut.createGroup(name: "그룹2")

        // Act
        try await sut.deleteGroup(id: group1.id)

        // Assert
        let remaining = await sut.fetchAllGroups()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].name, "그룹2")
    }
}

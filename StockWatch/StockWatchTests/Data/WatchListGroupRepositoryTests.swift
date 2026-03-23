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
    func test_fetchAllGroups_orderedBySortOrder() async throws {
        // Arrange: sortOrder를 역순으로 삽입
        let g0 = WatchListGroupModel(name: "두 번째")
        g0.sortOrder = 1
        let g1 = WatchListGroupModel(name: "세 번째")
        g1.sortOrder = 2
        let g2 = WatchListGroupModel(name: "첫 번째")
        g2.sortOrder = 0
        modelContext.insert(g0)
        modelContext.insert(g1)
        modelContext.insert(g2)
        try modelContext.save()

        // Act
        let result = await sut.fetchAllGroups()

        // Assert: sortOrder 오름차순
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].name, "첫 번째")
        XCTAssertEqual(result[1].name, "두 번째")
        XCTAssertEqual(result[2].name, "세 번째")
    }

    // MARK: - reorderGroups

    @MainActor
    func test_reorderGroups_persistsSortOrderCorrectly() async throws {
        // Arrange
        let g1 = try await sut.createGroup(name: "그룹A")
        let g2 = try await sut.createGroup(name: "그룹B")
        let g3 = try await sut.createGroup(name: "그룹C")

        // Act: C, A, B 순서로 재배치
        try await sut.reorderGroups(orderedIds: [g3.id, g1.id, g2.id])

        // Assert
        let result = await sut.fetchAllGroups()
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].name, "그룹C")
        XCTAssertEqual(result[1].name, "그룹A")
        XCTAssertEqual(result[2].name, "그룹B")
    }

    @MainActor
    func test_reorderGroups_sortOrderValuesCorrect() async throws {
        // Arrange
        let g1 = try await sut.createGroup(name: "그룹A")
        let g2 = try await sut.createGroup(name: "그룹B")

        // Act
        try await sut.reorderGroups(orderedIds: [g2.id, g1.id])

        // Assert: sortOrder 값 자체 검증
        let result = await sut.fetchAllGroups()
        XCTAssertEqual(result[0].sortOrder, 0)
        XCTAssertEqual(result[1].sortOrder, 1)
    }

    @MainActor
    func test_reorderGroups_withUnknownId_silentlyIgnores() async throws {
        // Arrange
        let g1 = try await sut.createGroup(name: "그룹A")

        // Act: 존재하지 않는 UUID 포함
        try await sut.reorderGroups(orderedIds: [g1.id, UUID()])

        // Assert: 에러 없이 알려진 그룹만 처리
        let result = await sut.fetchAllGroups()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].sortOrder, 0)
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

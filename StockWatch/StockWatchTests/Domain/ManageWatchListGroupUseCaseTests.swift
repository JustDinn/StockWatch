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
    // MARK: - Validation

    @MainActor
    func test_createGroup_with20Chars_succeeds() async throws {
        // Arrange
        let name = String(repeating: "가", count: 20)
        
        // Act & Assert — Should not throw
        _ = try await sut.createGroup(name: name)
    }

    @MainActor
    func test_createGroup_with21Chars_throwsTooLongError() async {
        // Arrange
        let name = String(repeating: "가", count: 21)
        
        // Act & Assert
        do {
            _ = try await sut.createGroup(name: name)
            XCTFail("21자일 때 에러가 발생해야 합니다")
        } catch let error as WatchListGroupError {
            if case .tooLong(let max) = error {
                XCTAssertEqual(max, 20)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    @MainActor
    func test_createGroup_withOnlyWhitespace_throwsOnlyWhitespaceError() async {
        // Arrange
        let name = "   \n  "
        
        // Act & Assert
        do {
            _ = try await sut.createGroup(name: name)
            XCTFail("공백만 있을 때 에러가 발생해야 합니다")
        } catch let error as WatchListGroupError {
            XCTAssertEqual(error.errorDescription, "공백만으로는 그룹을 만들 수 없어요.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

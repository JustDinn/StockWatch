//
//  CheckUnreadNotificationUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockNotificationHistoryRepository: NotificationHistoryRepositoryProtocol {
    var stubbedItems: [NotificationItem] = []
    var stubbedError: Error?

    func fetchAll() throws -> [NotificationItem] {
        if let error = stubbedError { throw error }
        return stubbedItems
    }

    func save(_ item: NotificationItem) throws {}
    func deleteOlderThan(days: Int) throws {}
    func markAsRead(id: String) throws {}
}

// MARK: - Tests

final class CheckUnreadNotificationUseCaseTests: XCTestCase {

    private var sut: CheckUnreadNotificationUseCase!
    private var mockRepository: MockNotificationHistoryRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockNotificationHistoryRepository()
        sut = CheckUnreadNotificationUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 미읽음 항목이 있을 때 true 반환
    func test_execute_whenHasUnreadItems_returnsTrue() throws {
        // Given
        mockRepository.stubbedItems = [
            makeItem(id: "1", isRead: false),
            makeItem(id: "2", isRead: true)
        ]

        // When
        let result = try sut.execute()

        // Then
        XCTAssertTrue(result)
    }

    // 모든 항목이 읽음 상태일 때 false 반환
    func test_execute_whenAllItemsRead_returnsFalse() throws {
        // Given
        mockRepository.stubbedItems = [
            makeItem(id: "1", isRead: true),
            makeItem(id: "2", isRead: true)
        ]

        // When
        let result = try sut.execute()

        // Then
        XCTAssertFalse(result)
    }

    // 알림이 없을 때 false 반환
    func test_execute_whenEmpty_returnsFalse() throws {
        // Given
        mockRepository.stubbedItems = []

        // When
        let result = try sut.execute()

        // Then
        XCTAssertFalse(result)
    }

    // Repository 에러 시 에러 전파
    func test_execute_whenRepositoryThrows_propagatesError() {
        // Given
        mockRepository.stubbedError = NetworkError.serverError

        // When / Then
        XCTAssertThrowsError(try sut.execute()) { error in
            XCTAssertTrue(error is NetworkError)
        }
    }
}

// MARK: - Helpers

private extension CheckUnreadNotificationUseCaseTests {
    func makeItem(id: String, isRead: Bool) -> NotificationItem {
        NotificationItem(
            id: id,
            conditionId: "cond-\(id)",
            ticker: "AAPL",
            logoURL: "",
            strategyName: "Test Strategy",
            body: "Test body",
            receivedAt: Date(),
            isRead: isRead
        )
    }
}

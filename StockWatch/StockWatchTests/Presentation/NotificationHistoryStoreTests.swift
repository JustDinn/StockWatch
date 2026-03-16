//
//  NotificationHistoryStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockFetchNotificationHistoryUseCase: FetchNotificationHistoryUseCaseProtocol {
    var stubbedResult: [NotificationItem] = []
    var stubbedError: Error?

    func execute() throws -> [NotificationItem] {
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

final class MockMarkNotificationAsReadUseCase: MarkNotificationAsReadUseCaseProtocol {
    var stubbedResult: Bool = false
    var stubbedError: Error?
    var executeCallCount = 0
    var lastReceivedId: String?

    func execute(id: String) throws -> Bool {
        executeCallCount += 1
        lastReceivedId = id
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

final class MockNotificationCenterService: NotificationCenterServiceProtocol {
    var removeCalledWithId: String?
    var removeCallCount = 0

    func removeDeliveredNotification(matchingId id: String) async {
        removeCallCount += 1
        removeCalledWithId = id
    }
}

final class MockBadgeService: BadgeServiceProtocol {
    var decrementCallCount = 0

    func decrement() async {
        decrementCallCount += 1
    }
}

// MARK: - Tests

@MainActor
final class NotificationHistoryStoreTests: XCTestCase {

    private var sut: NotificationHistoryStore!
    private var mockFetchUseCase: MockFetchNotificationHistoryUseCase!
    private var mockMarkAsReadUseCase: MockMarkNotificationAsReadUseCase!
    private var mockNotificationCenterService: MockNotificationCenterService!
    private var mockBadgeService: MockBadgeService!

    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchNotificationHistoryUseCase()
        mockMarkAsReadUseCase = MockMarkNotificationAsReadUseCase()
        mockNotificationCenterService = MockNotificationCenterService()
        mockBadgeService = MockBadgeService()
        sut = NotificationHistoryStore(
            fetchUseCase: mockFetchUseCase,
            markAsReadUseCase: mockMarkAsReadUseCase,
            notificationCenterService: mockNotificationCenterService,
            badgeService: mockBadgeService
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchUseCase = nil
        mockMarkAsReadUseCase = nil
        mockNotificationCenterService = nil
        mockBadgeService = nil
        super.tearDown()
    }

    // MARK: - loadNotifications

    func test_action_loadNotifications_updatesStateWithResults() throws {
        // Arrange
        let item = NotificationItem(
            id: "cond1_AAPL_28000000",
            conditionId: "cond1",
            ticker: "AAPL",
            logoURL: "",
            strategyName: "Test",
            body: "Test body",
            receivedAt: Date(),
            isRead: false
        )
        mockFetchUseCase.stubbedResult = [item]

        // Act
        sut.action(.loadNotifications)

        // Assert
        XCTAssertEqual(sut.state.notifications.count, 1)
        XCTAssertEqual(sut.state.notifications.first?.id, "cond1_AAPL_28000000")
    }

    // MARK: - markAsRead

    func test_handleMarkAsRead_whenItemIsUnread_callsRemoveDeliveredNotification() async {
        // Arrange
        let item = NotificationItem(
            id: "cond1_AAPL_28000000",
            conditionId: "cond1",
            ticker: "AAPL",
            logoURL: "",
            strategyName: "Test",
            body: "Test body",
            receivedAt: Date(),
            isRead: false
        )
        mockFetchUseCase.stubbedResult = [item]
        sut.action(.loadNotifications)
        mockMarkAsReadUseCase.stubbedResult = true // 처음 읽음 처리

        // Act
        sut.action(.markAsRead(id: "cond1_AAPL_28000000"))
        await sut.lastMarkAsReadTask?.value

        // Assert
        XCTAssertEqual(mockNotificationCenterService.removeCallCount, 1)
        XCTAssertEqual(mockNotificationCenterService.removeCalledWithId, "cond1_AAPL_28000000")
    }

    func test_handleMarkAsRead_whenItemIsAlreadyRead_doesNotCallRemoveDeliveredNotification() async {
        // Arrange
        let item = NotificationItem(
            id: "cond1_AAPL_28000000",
            conditionId: "cond1",
            ticker: "AAPL",
            logoURL: "",
            strategyName: "Test",
            body: "Test body",
            receivedAt: Date(),
            isRead: true
        )
        mockFetchUseCase.stubbedResult = [item]
        sut.action(.loadNotifications)
        mockMarkAsReadUseCase.stubbedResult = false // 이미 읽음 상태

        // Act
        sut.action(.markAsRead(id: "cond1_AAPL_28000000"))
        await sut.lastMarkAsReadTask?.value

        // Assert
        XCTAssertEqual(mockNotificationCenterService.removeCallCount, 0)
    }
}

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

final class MockFetchStockLogoUseCase: FetchStockLogoUseCaseProtocol {
    var stubbedURLs: [String: String] = [:]
    var stubbedError: Error?
    var executeCallCount = 0

    func execute(ticker: String) async throws -> String {
        executeCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedURLs[ticker] ?? ""
    }
}

// MARK: - Tests

@MainActor
final class NotificationHistoryStoreTests: XCTestCase {

    private var sut: NotificationHistoryStore!
    private var mockFetchUseCase: MockFetchNotificationHistoryUseCase!
    private var mockMarkAsReadUseCase: MockMarkNotificationAsReadUseCase!
    private var mockFetchLogoUseCase: MockFetchStockLogoUseCase!
    private var mockNotificationCenterService: MockNotificationCenterService!
    private var mockBadgeService: MockBadgeService!

    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchNotificationHistoryUseCase()
        mockMarkAsReadUseCase = MockMarkNotificationAsReadUseCase()
        mockFetchLogoUseCase = MockFetchStockLogoUseCase()
        mockNotificationCenterService = MockNotificationCenterService()
        mockBadgeService = MockBadgeService()
        sut = NotificationHistoryStore(
            fetchUseCase: mockFetchUseCase,
            markAsReadUseCase: mockMarkAsReadUseCase,
            fetchLogoUseCase: mockFetchLogoUseCase,
            notificationCenterService: mockNotificationCenterService,
            badgeService: mockBadgeService
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchUseCase = nil
        mockMarkAsReadUseCase = nil
        mockFetchLogoUseCase = nil
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

    // MARK: - fetchLogos

    func test_action_loadNotifications_fetchesLogosForUniqueTickers() async {
        // Arrange
        let makeItem = { (id: String, ticker: String) in
            NotificationItem(id: id, conditionId: id, ticker: ticker, logoURL: "", strategyName: "Test", body: "", receivedAt: Date(), isRead: false)
        }
        mockFetchUseCase.stubbedResult = [
            makeItem("id1", "AAPL"),
            makeItem("id2", "AAPL"),  // 중복 ticker
            makeItem("id3", "MSFT")
        ]
        mockFetchLogoUseCase.stubbedURLs = ["AAPL": "https://logo/aapl.png", "MSFT": "https://logo/msft.png"]

        // Act
        sut.action(.loadNotifications)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert: 중복 AAPL은 1회만 fetch → 총 2회
        XCTAssertEqual(mockFetchLogoUseCase.executeCallCount, 2)
    }

    func test_action_logoURLFetched_updatesStateLogoURLs() {
        // Act
        sut.action(.logoURLFetched(ticker: "AAPL", url: "https://logo/aapl.png"))

        // Assert
        XCTAssertEqual(sut.state.logoURLs["AAPL"], "https://logo/aapl.png")
    }

    func test_action_loadNotifications_withEmptyLogoURL_doesNotUpdateLogoURLs() async {
        // Arrange
        let item = NotificationItem(id: "id1", conditionId: "id1", ticker: "AAPL", logoURL: "", strategyName: "Test", body: "", receivedAt: Date(), isRead: false)
        mockFetchUseCase.stubbedResult = [item]
        mockFetchLogoUseCase.stubbedURLs = [:]  // 빈 URL 반환

        // Act
        sut.action(.loadNotifications)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertNil(sut.state.logoURLs["AAPL"])
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

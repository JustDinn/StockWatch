//
//  MyAlertsStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mocks

final class MockFetchStockConditionsUseCase: FetchStockConditionsUseCaseProtocol {
    var stubbedConditions: [StockCondition] = []

    func executeAll() async -> [StockCondition] {
        return stubbedConditions
    }

    func execute(ticker: String) async -> [StockCondition] {
        return stubbedConditions.filter { $0.ticker == ticker }
    }
}

final class MockDeleteStockConditionUseCase: DeleteStockConditionUseCaseProtocol {
    var stubbedError: Error?

    func execute(id: String) async throws {
        if let error = stubbedError { throw error }
    }
}

final class MockToggleAlertUseCase: ToggleAlertUseCaseProtocol {
    var stubbedError: Error?
    var stubbedResult: Bool = true

    func execute(condition: StockCondition, fcmToken: String) async throws -> Bool {
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

// MARK: - Tests

@MainActor
final class MyAlertsStoreTests: XCTestCase {

    private var sut: MyAlertsStore!
    private var mockFetchUseCase: MockFetchStockConditionsUseCase!
    private var mockDeleteUseCase: MockDeleteStockConditionUseCase!
    private var mockToggleUseCase: MockToggleAlertUseCase!

    override func setUp() {
        super.setUp()
        mockFetchUseCase = MockFetchStockConditionsUseCase()
        mockDeleteUseCase = MockDeleteStockConditionUseCase()
        mockToggleUseCase = MockToggleAlertUseCase()
        sut = MyAlertsStore(
            fetchStockConditionsUseCase: mockFetchUseCase,
            deleteStockConditionUseCase: mockDeleteUseCase,
            toggleAlertUseCase: mockToggleUseCase,
            fcmTokenProvider: { "test-token" }
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_action_loadConditions_setsConditions() async {
        // Arrange
        let condition = StockCondition(
            id: "id-1",
            ticker: "005930",
            companyName: "삼성전자",
            strategyId: "sma_cross",
            parameters: .sma(shortPeriod: 5, longPeriod: 20),
            isNotificationEnabled: true,
            notificationTime: Date(),
            isActive: true,
            createdAt: Date()
        )
        mockFetchUseCase.stubbedConditions = [condition]

        // Act
        sut.action(.loadConditions)
        await Task.yield()
        await Task.yield()

        // Assert
        XCTAssertEqual(sut.state.conditions.count, 1)
        XCTAssertEqual(sut.state.conditions.first?.companyName, "삼성전자")
    }

    func test_action_toggleNotification_optimisticUpdate_preservesCompanyName() async {
        // Arrange
        let condition = StockCondition(
            id: "id-2",
            ticker: "005930",
            companyName: "삼성전자",
            strategyId: "sma_cross",
            parameters: .sma(shortPeriod: 5, longPeriod: 20),
            isNotificationEnabled: true,
            notificationTime: Date(),
            isActive: true,
            createdAt: Date()
        )
        sut.state.conditions = [condition]

        // Act
        sut.action(.toggleNotification(condition: condition))

        // Assert (낙관적 업데이트 후 companyName 유지 확인)
        XCTAssertEqual(sut.state.conditions.first?.companyName, "삼성전자")
        XCTAssertEqual(sut.state.conditions.first?.isNotificationEnabled, false)
    }

    func test_action_toggleNotification_onFailure_rollsBackConditions() async {
        // Arrange
        let condition = StockCondition(
            id: "id-3",
            ticker: "005930",
            companyName: "삼성전자",
            strategyId: "sma_cross",
            parameters: .sma(shortPeriod: 5, longPeriod: 20),
            isNotificationEnabled: true,
            notificationTime: Date(),
            isActive: true,
            createdAt: Date()
        )
        sut.state.conditions = [condition]
        mockToggleUseCase.stubbedError = NSError(domain: "test", code: -1)

        // Act
        sut.action(.toggleNotification(condition: condition))
        await Task.yield()
        await Task.yield()

        // Assert (롤백 후 원래 상태 복원, companyName 포함)
        XCTAssertEqual(sut.state.conditions.first?.companyName, "삼성전자")
        XCTAssertEqual(sut.state.conditions.first?.isNotificationEnabled, true)
    }
}

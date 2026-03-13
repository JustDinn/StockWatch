//
//  ToggleSavedStrategyUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockSavedStrategyRepository: SavedStrategyRepositoryProtocol {
    var stubbedIsSaved: Bool = false
    var stubbedError: Error?
    var stubbedSavedIds: [String] = []

    private(set) var saveCallCount = 0
    private(set) var removeCallCount = 0
    private(set) var isSavedCallCount = 0
    private(set) var lastReceivedStrategyId: String?

    func isSaved(strategyId: String) async -> Bool {
        isSavedCallCount += 1
        lastReceivedStrategyId = strategyId
        return stubbedIsSaved
    }

    func save(strategyId: String) async throws {
        if let error = stubbedError { throw error }
        saveCallCount += 1
        lastReceivedStrategyId = strategyId
    }

    func remove(strategyId: String) async throws {
        if let error = stubbedError { throw error }
        removeCallCount += 1
        lastReceivedStrategyId = strategyId
    }

    func fetchAllSavedIds() async -> [String] {
        stubbedSavedIds
    }
}

// MARK: - Tests

final class ToggleSavedStrategyUseCaseTests: XCTestCase {

    private var sut: ToggleSavedStrategyUseCase!
    private var mockRepository: MockSavedStrategyRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockSavedStrategyRepository()
        sut = ToggleSavedStrategyUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 미저장 전략 토글 → save 호출, true 반환
    func test_execute_whenNotSaved_callsSaveAndReturnsTrue() async throws {
        // Given
        mockRepository.stubbedIsSaved = false

        // When
        let result = try await sut.execute(strategyId: "sma_cross")

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockRepository.saveCallCount, 1)
        XCTAssertEqual(mockRepository.removeCallCount, 0)
        XCTAssertEqual(mockRepository.lastReceivedStrategyId, "sma_cross")
    }

    // 저장된 전략 토글 → remove 호출, false 반환
    func test_execute_whenAlreadySaved_callsRemoveAndReturnsFalse() async throws {
        // Given
        mockRepository.stubbedIsSaved = true

        // When
        let result = try await sut.execute(strategyId: "sma_cross")

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockRepository.removeCallCount, 1)
        XCTAssertEqual(mockRepository.saveCallCount, 0)
        XCTAssertEqual(mockRepository.lastReceivedStrategyId, "sma_cross")
    }

    // 에러 발생 시 에러 전파
    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Given
        mockRepository.stubbedIsSaved = false
        mockRepository.stubbedError = NSError(domain: "TestError", code: 1)

        // When / Then
        do {
            _ = try await sut.execute(strategyId: "sma_cross")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

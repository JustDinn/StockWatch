//
//  SavedStrategyRepositoryTests.swift
//  StockWatchTests
//

import XCTest
import SwiftData
@testable import StockWatch

// MARK: - Tests

final class SavedStrategyRepositoryTests: XCTestCase {

    private var sut: SavedStrategyRepository!
    private var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        let container = try! ModelContainer(
            for: SavedStrategy.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = ModelContext(container)
        sut = SavedStrategyRepository(modelContext: modelContext)
    }

    override func tearDown() {
        sut = nil
        modelContext = nil
        super.tearDown()
    }

    // 저장 후 조회 시 존재 확인
    func test_save_persistsToStore() async throws {
        // When
        try await sut.save(strategyId: "sma_cross")

        // Then
        let isSaved = await sut.isSaved(strategyId: "sma_cross")
        XCTAssertTrue(isSaved)
    }

    // 삭제 후 조회 시 미존재 확인
    func test_remove_deletesFromStore() async throws {
        // Given
        try await sut.save(strategyId: "sma_cross")

        // When
        try await sut.remove(strategyId: "sma_cross")

        // Then
        let isSaved = await sut.isSaved(strategyId: "sma_cross")
        XCTAssertFalse(isSaved)
    }

    // 존재하는 ID → true
    func test_isSaved_whenExists_returnsTrue() async throws {
        // Given
        try await sut.save(strategyId: "rsi")

        // When
        let result = await sut.isSaved(strategyId: "rsi")

        // Then
        XCTAssertTrue(result)
    }

    // 미존재 ID → false
    func test_isSaved_whenNotExists_returnsFalse() async {
        // When
        let result = await sut.isSaved(strategyId: "unknown")

        // Then
        XCTAssertFalse(result)
    }

    // 중복 저장 방지
    func test_save_duplicateId_doesNotCreateDuplicate() async throws {
        // When
        try await sut.save(strategyId: "sma_cross")
        try await sut.save(strategyId: "sma_cross")

        // Then
        let descriptor = FetchDescriptor<SavedStrategy>(
            predicate: #Predicate { $0.strategyId == "sma_cross" }
        )
        let results = try modelContext.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
    }

    // 전체 저장된 ID 목록 반환
    func test_fetchAllSavedIds_returnsAllSavedIds() async throws {
        // Given
        try await sut.save(strategyId: "sma_cross")
        try await sut.save(strategyId: "rsi")

        // When
        let ids = await sut.fetchAllSavedIds()

        // Then
        XCTAssertEqual(Set(ids), Set(["sma_cross", "rsi"]))
    }

    // 빈 상태에서 전체 조회
    func test_fetchAllSavedIds_whenEmpty_returnsEmptyArray() async {
        // When
        let ids = await sut.fetchAllSavedIds()

        // Then
        XCTAssertTrue(ids.isEmpty)
    }
}

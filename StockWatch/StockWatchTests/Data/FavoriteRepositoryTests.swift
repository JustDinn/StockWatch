//
//  FavoriteRepositoryTests.swift
//  StockWatchTests
//

import XCTest
import SwiftData
@testable import StockWatch

// MARK: - Tests

final class FavoriteRepositoryTests: XCTestCase {

    private var sut: FavoriteRepository!
    private var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        // in-memory ModelContainer: 테스트 간 격리, 파일 I/O 없음
        let container = try! ModelContainer(
            for: FavoriteStock.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = ModelContext(container)
        sut = FavoriteRepository(modelContext: modelContext)
    }

    override func tearDown() {
        sut = nil
        modelContext = nil
        super.tearDown()
    }

    // 추가 후 조회 시 존재 확인
    func test_addFavorite_persistsToStore() async throws {
        // When
        try await sut.addFavorite(ticker: "AAPL", companyName: "Apple Inc.")

        // Then
        let isFav = await sut.isFavorite(ticker: "AAPL")
        XCTAssertTrue(isFav)
    }

    // companyName이 함께 저장되는지 확인
    func test_addFavorite_storesCompanyName() async throws {
        // When
        try await sut.addFavorite(ticker: "AAPL", companyName: "Apple Inc.")

        // Then
        let favorites = await sut.fetchAllFavorites()
        XCTAssertEqual(favorites.first?.companyName, "Apple Inc.")
    }

    // 삭제 후 조회 시 미존재 확인
    func test_removeFavorite_deletesFromStore() async throws {
        // Given
        try await sut.addFavorite(ticker: "AAPL", companyName: "Apple Inc.")

        // When
        try await sut.removeFavorite(ticker: "AAPL")

        // Then
        let isFav = await sut.isFavorite(ticker: "AAPL")
        XCTAssertFalse(isFav)
    }

    // 존재하는 ticker → true
    func test_isFavorite_whenExists_returnsTrue() async throws {
        // Given
        try await sut.addFavorite(ticker: "TSLA", companyName: "Tesla, Inc.")

        // When
        let result = await sut.isFavorite(ticker: "TSLA")

        // Then
        XCTAssertTrue(result)
    }

    // 미존재 ticker → false
    func test_isFavorite_whenNotExists_returnsFalse() async {
        // When
        let result = await sut.isFavorite(ticker: "UNKNOWN")

        // Then
        XCTAssertFalse(result)
    }

    // 중복 추가 방지: 동일 ticker를 두 번 추가해도 하나만 저장
    func test_addFavorite_duplicateTicker_doesNotCreateDuplicate() async throws {
        // When
        try await sut.addFavorite(ticker: "AAPL", companyName: "Apple Inc.")
        try await sut.addFavorite(ticker: "AAPL", companyName: "Apple Inc.")

        // Then: 조회 결과가 여전히 true이고, 중복 없음
        let descriptor = FetchDescriptor<FavoriteStock>(
            predicate: #Predicate { $0.ticker == "AAPL" }
        )
        let results = try modelContext.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
    }

    // fetchAllFavorites → FavoriteItem 배열 반환
    func test_fetchAllFavorites_returnsFavoriteItems() async throws {
        // Given
        try await sut.addFavorite(ticker: "AAPL", companyName: "Apple Inc.")
        try await sut.addFavorite(ticker: "TSLA", companyName: "Tesla, Inc.")

        // When
        let result = await sut.fetchAllFavorites()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(where: { $0.ticker == "AAPL" && $0.companyName == "Apple Inc." }))
        XCTAssertTrue(result.contains(where: { $0.ticker == "TSLA" && $0.companyName == "Tesla, Inc." }))
    }
}

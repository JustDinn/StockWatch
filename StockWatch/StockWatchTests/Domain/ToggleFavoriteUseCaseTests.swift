//
//  ToggleFavoriteUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockFavoriteRepository: FavoriteRepositoryProtocol {
    var stubbedIsFavorite: Bool = false
    var stubbedError: Error?

    private(set) var addFavoriteCallCount = 0
    private(set) var removeFavoriteCallCount = 0
    private(set) var isFavoriteCallCount = 0
    private(set) var lastReceivedTicker: String?

    func isFavorite(ticker: String) async -> Bool {
        isFavoriteCallCount += 1
        lastReceivedTicker = ticker
        return stubbedIsFavorite
    }

    func addFavorite(ticker: String) async throws {
        if let error = stubbedError { throw error }
        addFavoriteCallCount += 1
        lastReceivedTicker = ticker
    }

    func removeFavorite(ticker: String) async throws {
        if let error = stubbedError { throw error }
        removeFavoriteCallCount += 1
        lastReceivedTicker = ticker
    }

    var stubbedFavorites: [String] = []

    func fetchAllFavorites() async -> [String] {
        return stubbedFavorites
    }
}

// MARK: - Tests

final class ToggleFavoriteUseCaseTests: XCTestCase {

    private var sut: ToggleFavoriteUseCase!
    private var mockRepository: MockFavoriteRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockFavoriteRepository()
        sut = ToggleFavoriteUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 미등록 종목 토글 → addFavorite 호출, true 반환
    func test_execute_whenNotFavorite_callsAddFavoriteAndReturnsTrue() async throws {
        // Given
        mockRepository.stubbedIsFavorite = false

        // When
        let result = try await sut.execute(ticker: "AAPL")

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockRepository.addFavoriteCallCount, 1)
        XCTAssertEqual(mockRepository.removeFavoriteCallCount, 0)
        XCTAssertEqual(mockRepository.lastReceivedTicker, "AAPL")
    }

    // 등록된 종목 토글 → removeFavorite 호출, false 반환
    func test_execute_whenAlreadyFavorite_callsRemoveFavoriteAndReturnsFalse() async throws {
        // Given
        mockRepository.stubbedIsFavorite = true

        // When
        let result = try await sut.execute(ticker: "AAPL")

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockRepository.removeFavoriteCallCount, 1)
        XCTAssertEqual(mockRepository.addFavoriteCallCount, 0)
        XCTAssertEqual(mockRepository.lastReceivedTicker, "AAPL")
    }

    // 에러 발생 시 에러 전파
    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Given
        mockRepository.stubbedIsFavorite = false
        mockRepository.stubbedError = NSError(domain: "TestError", code: 1)

        // When / Then
        do {
            _ = try await sut.execute(ticker: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

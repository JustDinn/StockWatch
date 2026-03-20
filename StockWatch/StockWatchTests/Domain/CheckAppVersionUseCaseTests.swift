//
//  CheckAppVersionUseCaseTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockAppVersionRepository: AppVersionRepositoryProtocol {

    var stubbedResult: (minimumVersion: String, storeURL: String)?
    var stubbedError: Error?
    private(set) var fetchCallCount = 0

    func fetchMinimumVersion() async throws -> (minimumVersion: String, storeURL: String) {
        fetchCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedResult!
    }
}

// MARK: - Tests

final class CheckAppVersionUseCaseTests: XCTestCase {

    private var sut: CheckAppVersionUseCase!
    private var mockRepository: MockAppVersionRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockAppVersionRepository()
        sut = CheckAppVersionUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // 현재 버전이 최소 버전보다 낮으면 updateRequired 반환
    func test_execute_whenCurrentVersionBelowMinimum_returnsUpdateRequired() async throws {
        // Given
        mockRepository.stubbedResult = (minimumVersion: "2.0.0", storeURL: "https://apps.apple.com/app/id123")

        // When
        let result = try await sut.execute(currentVersion: "1.0.0")

        // Then
        if case .updateRequired(let minVersion, let storeURL) = result {
            XCTAssertEqual(minVersion, "2.0.0")
            XCTAssertEqual(storeURL, "https://apps.apple.com/app/id123")
        } else {
            XCTFail("Expected updateRequired but got \(result)")
        }
        XCTAssertEqual(mockRepository.fetchCallCount, 1)
    }

    // 현재 버전과 최소 버전이 같으면 upToDate 반환
    func test_execute_whenCurrentVersionEqualToMinimum_returnsUpToDate() async throws {
        // Given
        mockRepository.stubbedResult = (minimumVersion: "1.0.0", storeURL: "https://apps.apple.com/app/id123")

        // When
        let result = try await sut.execute(currentVersion: "1.0.0")

        // Then
        if case .upToDate = result {
            // pass
        } else {
            XCTFail("Expected upToDate but got \(result)")
        }
    }

    // 현재 버전이 최소 버전보다 높으면 upToDate 반환
    func test_execute_whenCurrentVersionAboveMinimum_returnsUpToDate() async throws {
        // Given
        mockRepository.stubbedResult = (minimumVersion: "1.0.0", storeURL: "https://apps.apple.com/app/id123")

        // When
        let result = try await sut.execute(currentVersion: "2.0.0")

        // Then
        if case .upToDate = result {
            // pass
        } else {
            XCTFail("Expected upToDate but got \(result)")
        }
    }

    // 패치 버전 비교: 1.0.1 < 1.0.2
    func test_execute_withPatchVersionDifference_returnsUpdateRequired() async throws {
        // Given
        mockRepository.stubbedResult = (minimumVersion: "1.0.2", storeURL: "https://apps.apple.com/app/id123")

        // When
        let result = try await sut.execute(currentVersion: "1.0.1")

        // Then
        if case .updateRequired = result {
            // pass
        } else {
            XCTFail("Expected updateRequired but got \(result)")
        }
    }

    // Repository 오류 발생 시 에러 전파
    func test_execute_whenFetchFails_throwsError() async {
        // Given
        struct FetchError: Error {}
        mockRepository.stubbedError = FetchError()

        // When / Then
        do {
            _ = try await sut.execute(currentVersion: "1.0.0")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is FetchError)
        }
    }
}

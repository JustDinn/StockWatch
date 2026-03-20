//
//  AppVersionRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock RemoteConfig Provider

final class MockRemoteConfigProvider: RemoteConfigProviding {

    var stubbedMinimumVersion = ""
    var stubbedStoreURL = ""
    var stubbedError: Error?
    private(set) var fetchCallCount = 0

    func fetchAndActivate() async throws {
        fetchCallCount += 1
        if let error = stubbedError { throw error }
    }

    func stringValue(forKey key: String) -> String {
        switch key {
        case "minimum_app_version": return stubbedMinimumVersion
        case "app_store_url": return stubbedStoreURL
        default: return ""
        }
    }
}

// MARK: - Tests

final class AppVersionRepositoryTests: XCTestCase {

    private var sut: AppVersionRepository!
    private var mockProvider: MockRemoteConfigProvider!

    override func setUp() {
        super.setUp()
        mockProvider = MockRemoteConfigProvider()
        sut = AppVersionRepository(remoteConfigProvider: mockProvider)
    }

    override func tearDown() {
        sut = nil
        mockProvider = nil
        super.tearDown()
    }

    // Remote Config에서 버전/URL 정상 반환
    func test_fetchMinimumVersion_returnsConfigValues() async throws {
        // Given
        mockProvider.stubbedMinimumVersion = "2.0.0"
        mockProvider.stubbedStoreURL = "https://apps.apple.com/app/id123"

        // When
        let result = try await sut.fetchMinimumVersion()

        // Then
        XCTAssertEqual(result.minimumVersion, "2.0.0")
        XCTAssertEqual(result.storeURL, "https://apps.apple.com/app/id123")
        XCTAssertEqual(mockProvider.fetchCallCount, 1)
    }

    // Remote Config fetch 실패 시 에러 전파
    func test_fetchMinimumVersion_whenFetchFails_throwsError() async {
        // Given
        struct FetchError: Error {}
        mockProvider.stubbedError = FetchError()

        // When / Then
        do {
            _ = try await sut.fetchMinimumVersion()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is FetchError)
        }
    }
}

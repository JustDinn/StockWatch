//
//  ForceUpdateStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock UseCase

final class MockCheckAppVersionUseCase: CheckAppVersionUseCaseProtocol {

    var stubbedResult: AppVersionStatus = .upToDate
    var stubbedError: Error?
    private(set) var executeCallCount = 0

    func execute(currentVersion: String) async throws -> AppVersionStatus {
        executeCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}

// MARK: - Tests

@MainActor
final class ForceUpdateStoreTests: XCTestCase {

    private var sut: ForceUpdateStore!
    private var mockUseCase: MockCheckAppVersionUseCase!

    override func setUp() {
        super.setUp()
        mockUseCase = MockCheckAppVersionUseCase()
        sut = ForceUpdateStore(checkVersionUseCase: mockUseCase)
    }

    override func tearDown() {
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    // updateRequired 응답 시 showUpdate = true, storeURL 설정
    func test_action_checkVersion_whenUpdateRequired_setsShowUpdateTrue() async {
        // Given
        mockUseCase.stubbedResult = .updateRequired(
            minimumVersion: "2.0.0",
            storeURL: "https://apps.apple.com/app/id123"
        )

        // When
        sut.action(.checkVersion(currentVersion: "1.0.0"))
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.state.showUpdate)
        XCTAssertEqual(sut.state.storeURL, "https://apps.apple.com/app/id123")
        XCTAssertEqual(mockUseCase.executeCallCount, 1)
    }

    // upToDate 응답 시 showUpdate = false
    func test_action_checkVersion_whenUpToDate_setsShowUpdateFalse() async {
        // Given
        mockUseCase.stubbedResult = .upToDate

        // When
        sut.action(.checkVersion(currentVersion: "2.0.0"))
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.state.showUpdate)
        XCTAssertNil(sut.state.storeURL)
    }

    // 에러 발생 시 fail-open: showUpdate = false
    func test_action_checkVersion_whenError_setsShowUpdateFalse() async {
        // Given
        struct NetworkError: Error {}
        mockUseCase.stubbedError = NetworkError()

        // When
        sut.action(.checkVersion(currentVersion: "1.0.0"))
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.state.showUpdate)
    }
}

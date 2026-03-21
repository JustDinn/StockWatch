//
//  StockLogoRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class StockLogoRepositoryTests: XCTestCase {

    private var sut: StockLogoRepository!
    private var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = StockLogoRepository(networkService: mockNetworkService, apiKey: "test-api-key")
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // 정상 케이스: logo 필드가 있으면 해당 URL 문자열 반환
    func test_fetchLogoURL_withValidResponse_returnsLogoString() async throws {
        // Arrange
        let profileDTO = StockProfileDTO(
            name: "Apple Inc",
            logo: "https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AAPL.png",
            ticker: "AAPL",
            country: "US",
            currency: "USD",
            exchange: "NASDAQ"
        )
        mockNetworkService.stubbedResult = profileDTO

        // Act
        let result = try await sut.fetchLogoURL(ticker: "AAPL")

        // Assert
        XCTAssertEqual(result, "https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AAPL.png")
    }

    // logo nil 케이스: logo 필드가 nil이면 빈 문자열 반환
    func test_fetchLogoURL_whenLogoIsNil_returnsEmptyString() async throws {
        // Arrange
        let profileDTO = StockProfileDTO(
            name: "Some Company",
            logo: nil,
            ticker: "XYZ",
            country: "KR",
            currency: "KRW",
            exchange: "KRX"
        )
        mockNetworkService.stubbedResult = profileDTO

        // Act
        let result = try await sut.fetchLogoURL(ticker: "XYZ")

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    // 에러 전파 케이스: 네트워크 에러가 전파되는지 검증
    func test_fetchLogoURL_whenNetworkFails_throwsError() async {
        // Arrange
        mockNetworkService.stubbedError = NetworkError.networkDisconnected

        // Act / Assert
        do {
            _ = try await sut.fetchLogoURL(ticker: "AAPL")
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

//
//  StrategyRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Tests

final class StrategyRepositoryTests: XCTestCase {

    private var sut: StrategyRepository!

    override func setUp() {
        super.setUp()
        sut = StrategyRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // 하드코딩된 전략 3개 반환 확인
    func test_fetchAllStrategies_returnsThreeStrategies() async {
        // When
        let result = await sut.fetchAllStrategies()

        // Then
        XCTAssertEqual(result.count, 3)
    }

    // 전략 ID 확인
    func test_fetchAllStrategies_containsExpectedIds() async {
        // When
        let result = await sut.fetchAllStrategies()
        let ids = result.map(\.id)

        // Then
        XCTAssertTrue(ids.contains("sma_cross"))
        XCTAssertTrue(ids.contains("ema_cross"))
        XCTAssertTrue(ids.contains("rsi"))
    }

    // 카테고리 분류 확인
    func test_fetchAllStrategies_categoriesAreCorrect() async {
        // When
        let result = await sut.fetchAllStrategies()
        let categoryMap = Dictionary(uniqueKeysWithValues: result.map { ($0.id, $0.category) })

        // Then
        XCTAssertEqual(categoryMap["sma_cross"], .movingAverage)
        XCTAssertEqual(categoryMap["ema_cross"], .movingAverage)
        XCTAssertEqual(categoryMap["rsi"], .oscillator)
    }
}

//
//  StockConditionMapperTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class StockConditionMapperTests: XCTestCase {

    // MARK: - Model → Entity

    func test_map_model_withCompanyName_mapsCorrectly() {
        // Arrange
        let model = StockConditionModel(
            conditionId: "id-1",
            ticker: "005930",
            companyName: "삼성전자",
            strategyId: "sma_cross",
            parametersJSON: StrategyParametersMapper.encode(.sma(shortPeriod: 5, longPeriod: 20)),
            isNotificationEnabled: true,
            notificationTime: Date(),
            isActive: true,
            createdAt: Date()
        )

        // Act
        let entity = StockConditionMapper.map(model)

        // Assert
        XCTAssertNotNil(entity)
        XCTAssertEqual(entity?.companyName, "삼성전자")
        XCTAssertEqual(entity?.ticker, "005930")
    }

    func test_map_model_withEmptyCompanyName_returnsEmptyString() {
        // Arrange
        let model = StockConditionModel(
            conditionId: "id-2",
            ticker: "AAPL",
            companyName: "",
            strategyId: "rsi",
            parametersJSON: StrategyParametersMapper.encode(.rsi(period: 14, oversoldThreshold: 30, overboughtThreshold: 70)),
            isNotificationEnabled: false,
            notificationTime: Date(),
            isActive: true,
            createdAt: Date()
        )

        // Act
        let entity = StockConditionMapper.map(model)

        // Assert
        XCTAssertNotNil(entity)
        XCTAssertEqual(entity?.companyName, "")
        XCTAssertEqual(entity?.ticker, "AAPL")
    }

    // MARK: - Entity → Model

    func test_map_entity_withCompanyName_mapsToModel() {
        // Arrange
        let entity = StockCondition(
            id: "id-3",
            ticker: "035420",
            companyName: "NAVER",
            strategyId: "ema_cross",
            parameters: .ema(shortPeriod: 10, longPeriod: 30),
            isNotificationEnabled: true,
            notificationTime: Date(),
            isActive: true,
            createdAt: Date()
        )

        // Act
        let model = StockConditionMapper.map(entity)

        // Assert
        XCTAssertEqual(model.companyName, "NAVER")
        XCTAssertEqual(model.ticker, "035420")
        XCTAssertEqual(model.conditionId, "id-3")
    }
}

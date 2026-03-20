//
//  StockConditionMapper.swift
//  StockWatch
//

/// StockConditionModel ↔ StockCondition Entity 변환 Mapper
enum StockConditionMapper {

    /// Model → Entity 변환
    static func map(_ model: StockConditionModel) -> StockCondition? {
        guard let parameters = StrategyParametersMapper.decode(model.parametersJSON) else {
            return nil
        }
        return StockCondition(
            id: model.conditionId,
            ticker: model.ticker,
            companyName: model.companyName ?? "",
            strategyId: model.strategyId,
            parameters: parameters,
            isNotificationEnabled: model.isNotificationEnabled,
            notificationTime: model.notificationTime,
            isActive: model.isActive,
            createdAt: model.createdAt
        )
    }

    /// Entity → Model 변환
    static func map(_ entity: StockCondition) -> StockConditionModel {
        StockConditionModel(
            conditionId: entity.id,
            ticker: entity.ticker,
            companyName: entity.companyName,
            strategyId: entity.strategyId,
            parametersJSON: StrategyParametersMapper.encode(entity.parameters),
            isNotificationEnabled: entity.isNotificationEnabled,
            notificationTime: entity.notificationTime,
            isActive: entity.isActive,
            createdAt: entity.createdAt
        )
    }
}

//
//  StockConditionRepository.swift
//  StockWatch
//

import SwiftData
import Foundation

/// 종목 전략 조건 Repository 구현체
/// SwiftData의 ModelContext를 통해 StockConditionModel을 CRUD한다.
final class StockConditionRepository: StockConditionRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async -> [StockCondition] {
        let descriptor = FetchDescriptor<StockConditionModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let models = (try? modelContext.fetch(descriptor)) ?? []
        return models.compactMap { StockConditionMapper.map($0) }
    }

    func fetch(ticker: String) async -> [StockCondition] {
        let descriptor = FetchDescriptor<StockConditionModel>(
            predicate: #Predicate { $0.ticker == ticker },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let models = (try? modelContext.fetch(descriptor)) ?? []
        return models.compactMap { StockConditionMapper.map($0) }
    }

    func save(_ condition: StockCondition) async throws {
        let model = StockConditionMapper.map(condition)
        modelContext.insert(model)
        try modelContext.save()
    }

    func update(_ condition: StockCondition) async throws {
        let id = condition.id
        let descriptor = FetchDescriptor<StockConditionModel>(
            predicate: #Predicate { $0.conditionId == id }
        )
        guard let existing = try modelContext.fetch(descriptor).first else { return }
        existing.isNotificationEnabled = condition.isNotificationEnabled
        existing.isActive = condition.isActive
        existing.parametersJSON = StrategyParametersMapper.encode(condition.parameters)
        try modelContext.save()
    }

    func delete(id: String) async throws {
        let descriptor = FetchDescriptor<StockConditionModel>(
            predicate: #Predicate { $0.conditionId == id }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        results.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}

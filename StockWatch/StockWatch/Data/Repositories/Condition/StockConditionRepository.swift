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
        print("<< [fetchAll] modelContext: \(ObjectIdentifier(modelContext))")
        print("<< [fetchAll] 조회된 모델 수: \(models.count)")
        for model in models {
            print("<< [fetchAll] conditionId=\(model.conditionId), ticker=\(model.ticker), isNotificationEnabled=\(model.isNotificationEnabled)")
        }
        let conditions = models.compactMap { StockConditionMapper.map($0) }
        print("<< [fetchAll] 매핑된 조건 수: \(conditions.count)")
        return conditions
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
        print("<< [save] modelContext: \(ObjectIdentifier(modelContext))")
        print("<< [save] 저장 시도: conditionId=\(condition.id), ticker=\(condition.ticker), isNotificationEnabled=\(condition.isNotificationEnabled)")
        let model = StockConditionMapper.map(condition)
        modelContext.insert(model)
        do {
            try modelContext.save()
            print("<< [save] modelContext.save() 성공")
        } catch {
            print("<< [save] modelContext.save() 실패: \(error)")
            throw error
        }

        // save 직후 즉시 재조회하여 실제 persist 여부 확인
        let verifyDescriptor = FetchDescriptor<StockConditionModel>()
        let allModels = (try? modelContext.fetch(verifyDescriptor)) ?? []
        print("<< [save] 저장 후 즉시 fetchAll: \(allModels.count)개")
        for m in allModels {
            print("<< [save] 확인: conditionId=\(m.conditionId), ticker=\(m.ticker)")
        }
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
        existing.notificationTime = condition.notificationTime
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

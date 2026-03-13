//
//  SavedStrategyRepository.swift
//  StockWatch
//

import SwiftData
import Foundation

/// 저장된 전략 Repository 구현체
/// SwiftData의 ModelContext를 통해 SavedStrategy를 CRUD한다.
final class SavedStrategyRepository: SavedStrategyRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func isSaved(strategyId: String) async -> Bool {
        let descriptor = FetchDescriptor<SavedStrategy>(
            predicate: #Predicate { $0.strategyId == strategyId }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return !results.isEmpty
    }

    func save(strategyId: String) async throws {
        guard await !isSaved(strategyId: strategyId) else { return }
        let saved = SavedStrategy(strategyId: strategyId)
        modelContext.insert(saved)
        try modelContext.save()
    }

    func remove(strategyId: String) async throws {
        let descriptor = FetchDescriptor<SavedStrategy>(
            predicate: #Predicate { $0.strategyId == strategyId }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        results.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    func fetchAllSavedIds() async -> [String] {
        let descriptor = FetchDescriptor<SavedStrategy>()
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map(\.strategyId)
    }
}

//
//  NotificationHistoryRepository.swift
//  StockWatch
//

import Foundation
import SwiftData

final class NotificationHistoryRepository: NotificationHistoryRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [NotificationItem] {
        let descriptor = FetchDescriptor<NotificationHistoryModel>(
            sortBy: [SortDescriptor(\.receivedAt, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map { NotificationHistoryMapper.toEntity($0) }
    }

    func save(_ item: NotificationItem) throws {
        let model = NotificationHistoryMapper.toModel(item)
        modelContext.insert(model)
        try modelContext.save()
    }

    func deleteOlderThan(days: Int) throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<NotificationHistoryModel> { $0.receivedAt < cutoff }
        let descriptor = FetchDescriptor<NotificationHistoryModel>(predicate: predicate)
        let old = try modelContext.fetch(descriptor)
        old.forEach { modelContext.delete($0) }
        if !old.isEmpty {
            try modelContext.save()
        }
    }
}

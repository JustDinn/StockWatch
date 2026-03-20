//
//  WatchListGroupRepository.swift
//  StockWatch
//

import SwiftData
import Foundation

final class WatchListGroupRepository: WatchListGroupRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllGroups() async -> [WatchListGroup] {
        let descriptor = FetchDescriptor<WatchListGroupModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map { WatchListGroup(id: $0.id, name: $0.name, createdAt: $0.createdAt) }
    }

    func createGroup(name: String) async throws -> WatchListGroup {
        let descriptor = FetchDescriptor<WatchListGroupModel>(
            predicate: #Predicate { $0.name == name }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else {
            throw WatchListGroupError.duplicateName
        }
        let model = WatchListGroupModel(name: name)
        modelContext.insert(model)
        try modelContext.save()
        return WatchListGroup(id: model.id, name: model.name, createdAt: model.createdAt)
    }

    func deleteGroup(id: UUID) async throws {
        let descriptor = FetchDescriptor<WatchListGroupModel>(
            predicate: #Predicate { $0.id == id }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        results.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}

enum WatchListGroupError: LocalizedError {
    case duplicateName

    var errorDescription: String? {
        switch self {
        case .duplicateName:
            return "같은 이름의 그룹이 이미 존재합니다."
        }
    }
}

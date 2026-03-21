//
//  WatchListGroupRepository.swift
//  StockWatch
//

import SwiftData
import Foundation

@MainActor
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
        let sorted = results.sorted { ($0.isDefault ?? false) && !($1.isDefault ?? false) }
        return sorted.map { WatchListGroup(id: $0.id, name: $0.name, createdAt: $0.createdAt, isDefault: $0.isDefault ?? false) }
    }

    func createGroup(name: String) async throws -> WatchListGroup {
        let descriptor = FetchDescriptor<WatchListGroupModel>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        guard !all.contains(where: { $0.name == name }) else {
            throw WatchListGroupError.duplicateName
        }
        let model = WatchListGroupModel(name: name)
        modelContext.insert(model)
        try modelContext.save()
        return WatchListGroup(id: model.id, name: model.name, createdAt: model.createdAt, isDefault: model.isDefault ?? false)
    }

    func deleteGroup(id: UUID) async throws {
        let descriptor = FetchDescriptor<WatchListGroupModel>(
            predicate: #Predicate { $0.id == id }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        results.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    func ensureDefaultGroup() async throws -> WatchListGroup {
        let descriptor = FetchDescriptor<WatchListGroupModel>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        if let model = all.first(where: { $0.isDefault ?? false }) {
            return WatchListGroup(id: model.id, name: model.name, createdAt: model.createdAt, isDefault: model.isDefault ?? false)
        }
        let model = WatchListGroupModel(name: "전체", isDefault: true)
        modelContext.insert(model)
        try modelContext.save()
        return WatchListGroup(id: model.id, name: model.name, createdAt: model.createdAt, isDefault: model.isDefault ?? false)
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

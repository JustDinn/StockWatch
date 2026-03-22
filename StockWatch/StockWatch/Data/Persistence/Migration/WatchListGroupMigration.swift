//
//  WatchListGroupMigration.swift
//  StockWatch
//

import SwiftData
import Foundation

// MARK: - Schema V1 (sortOrder 없음)

enum WatchListGroupSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [WatchListGroupModelV1.self] }

    @Model
    final class WatchListGroupModelV1 {
        @Attribute(.unique) var id: UUID
        var name: String
        var createdAt: Date
        var isDefault: Bool?

        init(name: String) {
            self.id = UUID()
            self.name = name
            self.createdAt = .now
        }
    }
}

// MARK: - Schema V2 (sortOrder 추가)

enum WatchListGroupSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [WatchListGroupModel.self] }
}

// MARK: - Migration Plan

enum WatchListGroupMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WatchListGroupSchemaV1.self, WatchListGroupSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: WatchListGroupSchemaV1.self,
        toVersion: WatchListGroupSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let descriptor = FetchDescriptor<WatchListGroupModel>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let groups = (try? context.fetch(descriptor)) ?? []
            for (index, group) in groups.enumerated() {
                group.sortOrder = index
            }
            try context.save()
        }
    )
}

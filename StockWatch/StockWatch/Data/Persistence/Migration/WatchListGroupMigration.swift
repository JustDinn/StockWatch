//
//  WatchListGroupMigration.swift
//  StockWatch
//

import SwiftData
import Foundation

// MARK: - Schema V1 (그룹 기능 도입 이전: FavoriteStock만 존재, WatchListGroupModel 없음)

enum WatchListGroupSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [FavoriteStockV1.self] }

    @Model
    final class FavoriteStockV1 {
        @Attribute(.unique) var ticker: String
        var companyName: String?
        var addedAt: Date
        var logoURL: String?
        // groups 관계 없음

        init(ticker: String, companyName: String? = nil, addedAt: Date = .now, logoURL: String? = nil) {
            self.ticker = ticker
            self.companyName = companyName
            self.addedAt = addedAt
            self.logoURL = logoURL
        }
    }
}

// MARK: - Schema V2 (그룹 기능 추가: WatchListGroupModel + FavoriteStock.groups 관계 + sortOrder)

enum WatchListGroupSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [FavoriteStock.self, WatchListGroupModel.self] }
}

// MARK: - Migration Plan

enum WatchListGroupMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WatchListGroupSchemaV1.self, WatchListGroupSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // 기존 사용자는 그룹이 없으므로 sortOrder 초기화 로직은 실행되지 않음.
    // 경량 마이그레이션으로 FavoriteStock에 groups 관계와 WatchListGroupModel 테이블이 자동 추가됨.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: WatchListGroupSchemaV1.self,
        toVersion: WatchListGroupSchemaV2.self
    )
}

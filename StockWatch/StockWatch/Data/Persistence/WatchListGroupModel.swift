//
//  WatchListGroupModel.swift
//  StockWatch
//

import SwiftData
import Foundation

@Model
final class WatchListGroupModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var isDefault: Bool?
    var sortOrder: Int = 0
    @Relationship(inverse: \FavoriteStock.groups) var stocks: [FavoriteStock] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.sortOrder = 0
    }
}

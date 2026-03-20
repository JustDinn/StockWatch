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
    @Relationship(inverse: \FavoriteStock.groups) var stocks: [FavoriteStock] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
    }
}

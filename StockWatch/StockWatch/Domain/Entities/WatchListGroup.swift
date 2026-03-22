//
//  WatchListGroup.swift
//  StockWatch
//

import Foundation

struct WatchListGroup: Equatable {
    let id: UUID
    let name: String
    let createdAt: Date
    let sortOrder: Int

    init(id: UUID, name: String, createdAt: Date, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

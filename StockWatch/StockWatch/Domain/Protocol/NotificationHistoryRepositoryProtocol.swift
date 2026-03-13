//
//  NotificationHistoryRepositoryProtocol.swift
//  StockWatch
//

import Foundation

protocol NotificationHistoryRepositoryProtocol {
    func fetchAll() throws -> [NotificationItem]
    func save(_ item: NotificationItem) throws
    func deleteOlderThan(days: Int) throws
    func markAsRead(id: String) throws
}

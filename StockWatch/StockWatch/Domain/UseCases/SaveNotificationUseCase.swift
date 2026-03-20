//
//  SaveNotificationUseCase.swift
//  StockWatch
//

import Foundation

@MainActor
protocol SaveNotificationUseCaseProtocol {
    func execute(_ item: NotificationItem) throws
}

@MainActor
final class SaveNotificationUseCase: SaveNotificationUseCaseProtocol {

    private let repository: NotificationHistoryRepositoryProtocol

    init(repository: NotificationHistoryRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ item: NotificationItem) throws {
        try repository.save(item)
        try repository.deleteOlderThan(days: 30)
    }
}

//
//  SaveNotificationUseCase.swift
//  StockWatch
//

import Foundation

protocol SaveNotificationUseCaseProtocol {
    func execute(_ item: NotificationItem) throws
}

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

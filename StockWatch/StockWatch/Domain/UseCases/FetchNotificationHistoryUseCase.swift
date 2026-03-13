//
//  FetchNotificationHistoryUseCase.swift
//  StockWatch
//

import Foundation

protocol FetchNotificationHistoryUseCaseProtocol {
    func execute() throws -> [NotificationItem]
}

final class FetchNotificationHistoryUseCase: FetchNotificationHistoryUseCaseProtocol {

    private let repository: NotificationHistoryRepositoryProtocol

    init(repository: NotificationHistoryRepositoryProtocol) {
        self.repository = repository
    }

    func execute() throws -> [NotificationItem] {
        try repository.fetchAll()
    }
}

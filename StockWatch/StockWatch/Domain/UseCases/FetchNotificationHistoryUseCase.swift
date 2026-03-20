//
//  FetchNotificationHistoryUseCase.swift
//  StockWatch
//

import Foundation

@MainActor
protocol FetchNotificationHistoryUseCaseProtocol {
    func execute() throws -> [NotificationItem]
}

@MainActor
final class FetchNotificationHistoryUseCase: FetchNotificationHistoryUseCaseProtocol {

    private let repository: NotificationHistoryRepositoryProtocol

    init(repository: NotificationHistoryRepositoryProtocol) {
        self.repository = repository
    }

    func execute() throws -> [NotificationItem] {
        try repository.fetchAll()
    }
}

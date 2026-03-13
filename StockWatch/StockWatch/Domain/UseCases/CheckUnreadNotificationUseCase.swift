//
//  CheckUnreadNotificationUseCase.swift
//  StockWatch
//

protocol CheckUnreadNotificationUseCaseProtocol {
    func execute() throws -> Bool
}

final class CheckUnreadNotificationUseCase: CheckUnreadNotificationUseCaseProtocol {

    private let repository: NotificationHistoryRepositoryProtocol

    init(repository: NotificationHistoryRepositoryProtocol) {
        self.repository = repository
    }

    func execute() throws -> Bool {
        try repository.fetchAll().contains { !$0.isRead }
    }
}

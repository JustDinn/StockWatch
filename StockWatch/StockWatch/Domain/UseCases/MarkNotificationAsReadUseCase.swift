//
//  MarkNotificationAsReadUseCase.swift
//  StockWatch
//

import Foundation

protocol MarkNotificationAsReadUseCaseProtocol {
    /// 알림을 읽음 처리한다.
    /// - Returns: true = 방금 읽음 처리됨 (뱃지 감소 필요), false = 이미 읽었거나 존재하지 않음
    func execute(id: String) throws -> Bool
}

final class MarkNotificationAsReadUseCase: MarkNotificationAsReadUseCaseProtocol {

    private let repository: NotificationHistoryRepositoryProtocol

    init(repository: NotificationHistoryRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: String) throws -> Bool {
        let items = try repository.fetchAll()
        guard let item = items.first(where: { $0.id == id }), !item.isRead else { return false }
        try repository.markAsRead(id: id)
        return true
    }
}

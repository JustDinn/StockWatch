//
//  NotificationHistoryStore.swift
//  StockWatch
//

import SwiftUI

/// NotificationHistory 화면 Store
/// Intent를 처리하고 State를 업데이트한다.
@MainActor
final class NotificationHistoryStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: NotificationHistoryState

    private let fetchUseCase: FetchNotificationHistoryUseCaseProtocol
    private let markAsReadUseCase: MarkNotificationAsReadUseCaseProtocol

    // MARK: - Init

    init(
        fetchUseCase: FetchNotificationHistoryUseCaseProtocol,
        markAsReadUseCase: MarkNotificationAsReadUseCaseProtocol,
        state: NotificationHistoryState = NotificationHistoryState()
    ) {
        self.fetchUseCase = fetchUseCase
        self.markAsReadUseCase = markAsReadUseCase
        self.state = state
    }

    // MARK: - Action

    func action(_ intent: NotificationHistoryIntent) {
        switch intent {
        case .loadNotifications:
            loadNotifications()
        case .selectNotification(let item):
            handleSelectNotification(item)
        case .markAsRead(let id):
            handleMarkAsRead(id: id)
        }
    }

    // MARK: - Navigation Binding

    var selectedNotificationBinding: Binding<NotificationItem?> {
        Binding(
            get: { self.state.selectedNotification },
            set: { self.state.selectedNotification = $0 }
        )
    }

    // MARK: - Sections

    /// 오늘 수신한 알림
    var todayNotifications: [NotificationItem] {
        let calendar = Calendar.current
        return state.notifications.filter { calendar.isDateInToday($0.receivedAt) }
    }

    /// 오늘 제외 최근 7일 이내 알림
    var recentNotifications: [NotificationItem] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return state.notifications.filter {
            !calendar.isDateInToday($0.receivedAt) && $0.receivedAt >= sevenDaysAgo
        }
    }

    /// 7일 초과 이전 알림
    var olderNotifications: [NotificationItem] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return state.notifications.filter { $0.receivedAt < sevenDaysAgo }
    }
}

// MARK: - Private

private extension NotificationHistoryStore {

    func loadNotifications() {
        do {
            state.notifications = try fetchUseCase.execute()
        } catch {
            state.notifications = []
        }
    }

    func handleSelectNotification(_ item: NotificationItem) {
        state.selectedNotification = item
        handleMarkAsRead(id: item.id)
    }

    func handleMarkAsRead(id: String) {
        Task {
            let didChange = (try? markAsReadUseCase.execute(id: id)) ?? false
            if didChange {
                await BadgeResetService.decrement()
                state.notifications = state.notifications.map { item in
                    guard item.id == id else { return item }
                    return NotificationItem(
                        id: item.id,
                        conditionId: item.conditionId,
                        ticker: item.ticker,
                        logoURL: item.logoURL,
                        strategyName: item.strategyName,
                        body: item.body,
                        receivedAt: item.receivedAt,
                        isRead: true
                    )
                }
            }
        }
    }
}

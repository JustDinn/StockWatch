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

    // MARK: - Init

    init(
        fetchUseCase: FetchNotificationHistoryUseCaseProtocol,
        state: NotificationHistoryState = NotificationHistoryState()
    ) {
        self.fetchUseCase = fetchUseCase
        self.state = state
    }

    // MARK: - Action

    func action(_ intent: NotificationHistoryIntent) {
        switch intent {
        case .loadNotifications:
            loadNotifications()
        case .selectNotification(let item):
            state.selectedNotification = item
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
            print("<< loadNotifications - count: \(state.notifications.count)")
        } catch {
            print("<< loadNotifications error: \(error)")
            state.notifications = []
        }
    }
}

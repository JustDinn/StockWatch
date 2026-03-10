//
//  NotificationHistoryStore.swift
//  StockWatch
//

import SwiftUI

/// NotificationHistory 화면 Store
/// Intent를 처리하고 State를 업데이트한다. (더미 데이터 기반)
@MainActor
final class NotificationHistoryStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: NotificationHistoryState

    // MARK: - Init

    init(state: NotificationHistoryState = NotificationHistoryState()) {
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
        state.notifications = Self.dummyNotifications
    }

    // MARK: - Dummy Data

    static var dummyNotifications: [NotificationItem] {
        let now = Date()
        let calendar = Calendar.current

        func date(hoursAgo: Int) -> Date {
            calendar.date(byAdding: .hour, value: -hoursAgo, to: now) ?? now
        }
        func date(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        }

        return [
            // 오늘
            NotificationItem(
                id: "1",
                ticker: "AAPL",
                strategyName: "SMA 골든크로스 발생",
                body: "매수 신호 감지",
                receivedAt: date(hoursAgo: 1)
            ),
            NotificationItem(
                id: "2",
                ticker: "MSFT",
                strategyName: "RSI 과매도 구간 진입",
                body: "매수 신호 감지",
                receivedAt: date(hoursAgo: 3)
            ),
            NotificationItem(
                id: "3",
                ticker: "NVDA",
                strategyName: "EMA 골든크로스 발생",
                body: "매수 신호 감지",
                receivedAt: date(hoursAgo: 5)
            ),
            // 최근 7일
            NotificationItem(
                id: "4",
                ticker: "TSLA",
                strategyName: "EMA 데드크로스 발생",
                body: "매도 신호 감지",
                receivedAt: date(daysAgo: 2)
            ),
            NotificationItem(
                id: "5",
                ticker: "GOOGL",
                strategyName: "RSI 과매수 구간 진입",
                body: "매도 신호 감지",
                receivedAt: date(daysAgo: 3)
            ),
            NotificationItem(
                id: "6",
                ticker: "AMZN",
                strategyName: "SMA 골든크로스 발생",
                body: "매수 신호 감지",
                receivedAt: date(daysAgo: 5)
            ),
            NotificationItem(
                id: "7",
                ticker: "META",
                strategyName: "RSI 과매도 구간 진입",
                body: "매수 신호 감지",
                receivedAt: date(daysAgo: 6)
            ),
            // 이전 알림
            NotificationItem(
                id: "8",
                ticker: "NFLX",
                strategyName: "EMA 데드크로스 발생",
                body: "매도 신호 감지",
                receivedAt: date(daysAgo: 10)
            ),
            NotificationItem(
                id: "9",
                ticker: "AMD",
                strategyName: "SMA 골든크로스 발생",
                body: "매수 신호 감지",
                receivedAt: date(daysAgo: 14)
            ),
            NotificationItem(
                id: "10",
                ticker: "INTC",
                strategyName: "RSI 과매수 구간 진입",
                body: "매도 신호 감지",
                receivedAt: date(daysAgo: 20)
            ),
        ]
    }
}

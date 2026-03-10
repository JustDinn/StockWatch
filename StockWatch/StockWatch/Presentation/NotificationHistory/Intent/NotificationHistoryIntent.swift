//
//  NotificationHistoryIntent.swift
//  StockWatch
//

/// NotificationHistory 화면 사용자 액션 정의
enum NotificationHistoryIntent {
    /// 알림 목록 로드
    case loadNotifications
    /// 알림 항목 탭 → 종목 상세 화면 이동
    case selectNotification(NotificationItem)
}

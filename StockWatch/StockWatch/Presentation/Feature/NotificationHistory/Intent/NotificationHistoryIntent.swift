//
//  NotificationHistoryIntent.swift
//  StockWatch
//

/// NotificationHistory 화면 사용자 액션 정의
enum NotificationHistoryIntent {
    /// 알림 목록 로드
    case loadNotifications
    /// 알림 항목 탭 → 종목 상세 화면 이동 + 읽음 처리
    case selectNotification(NotificationItem)
    /// 개별 알림 읽음 처리 (알림센터 탭 등 외부에서 직접 호출 시)
    case markAsRead(id: String)
}

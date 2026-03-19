//
//  NotificationHistoryState.swift
//  StockWatch
//

import Foundation

// MARK: - NotificationItem

/// 푸시 알림 수신 내역 항목
struct NotificationItem: Identifiable, Equatable, Hashable {
    /// 고유 식별자
    let id: String
    /// 알림 조건 ID (중복 방지 및 읽음 처리에 사용)
    let conditionId: String
    /// 종목 티커 (예: "AAPL")
    let ticker: String
    /// 기업 로고 이미지 URL (빈 문자열이면 이니셜 표시)
    let logoURL: String
    /// 전략 신호명 (예: "SMA 골든크로스 발생")
    let strategyName: String
    /// 알림 본문 (예: "매수 신호 감지")
    let body: String
    /// 수신 시각
    let receivedAt: Date
    /// 읽음 여부
    var isRead: Bool
}

// MARK: - NotificationHistoryState

/// NotificationHistory 화면 UI 상태
struct NotificationHistoryState: Equatable {
    /// 수신한 알림 전체 목록
    var notifications: [NotificationItem] = []
    /// 선택된 알림 항목 (nil이면 상세 화면 미표시)
    var selectedNotification: NotificationItem? = nil
}

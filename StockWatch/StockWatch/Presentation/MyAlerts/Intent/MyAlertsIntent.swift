//
//  MyAlertsIntent.swift
//  StockWatch
//

/// MyAlerts 화면 사용자 액션 정의
enum MyAlertsIntent {
    /// 조건 목록 로드
    case loadConditions
    /// 조건 삭제
    case deleteCondition(id: String)
    /// 조건 알림 토글
    case toggleNotification(condition: StockCondition)
}

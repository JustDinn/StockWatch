//
//  MyAlertsIntent.swift
//  StockWatch
//

/// MyAlerts 화면 사용자 액션 정의
enum MyAlertsIntent {
    /// 조건 목록 로드
    case loadConditions
    /// 조건 삭제 확인 요청
    case requestDeleteCondition(id: String)
    /// 조건 삭제 확정
    case confirmDeleteCondition
    /// 조건 삭제 취소
    case cancelDeleteCondition
    /// 조건 알림 토글
    case toggleNotification(condition: StockCondition)
}

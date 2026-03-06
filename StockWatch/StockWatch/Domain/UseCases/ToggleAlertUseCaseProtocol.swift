//
//  ToggleAlertUseCaseProtocol.swift
//  StockWatch
//

/// 조건의 알림 활성/비활성 토글 UseCase 인터페이스
protocol ToggleAlertUseCaseProtocol {
    /// 조건의 알림 상태를 토글하고 새 상태를 반환한다.
    /// - Returns: 토글 후 isNotificationEnabled 상태
    func execute(condition: StockCondition, fcmToken: String) async throws -> Bool
}

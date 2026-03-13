//
//  RegisterAlertUseCaseProtocol.swift
//  StockWatch
//

/// 알림 등록/해제 UseCase 인터페이스
protocol RegisterAlertUseCaseProtocol {
    /// 알림을 Firestore에 등록하고 FCM 토큰을 연결한다.
    func register(condition: StockCondition, fcmToken: String) async throws
    /// 알림을 Firestore에서 해제한다.
    func unregister(conditionId: String) async throws
}

//
//  AlertRegistrationRepositoryProtocol.swift
//  StockWatch
//

/// 원격 알림 등록 저장소 인터페이스 (Firebase Firestore + FCM 기반)
/// 구현체는 Data 레이어에 위치하며, Domain은 이 Protocol에만 의존한다.
protocol AlertRegistrationRepositoryProtocol {
    /// 알림 조건을 원격 저장소에 등록한다.
    func register(condition: StockCondition, fcmToken: String) async throws
    /// 알림 조건을 원격 저장소에서 삭제한다.
    func unregister(conditionId: String) async throws
    /// 알림 조건의 활성 상태를 업데이트한다.
    func updateActive(conditionId: String, isActive: Bool) async throws
}

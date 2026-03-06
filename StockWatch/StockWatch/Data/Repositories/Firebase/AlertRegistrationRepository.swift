//
//  AlertRegistrationRepository.swift
//  StockWatch
//
//  NOTE: Firebase SDK (firebase-ios-sdk) 설치 후 이 파일을 교체해야 한다.
//  SPM에서 https://github.com/firebase/firebase-ios-sdk 를 추가하고
//  FirebaseFirestore, FirebaseMessaging 타겟을 선택한다.
//  이후 아래 주석 처리된 구현으로 교체한다.
//

import Foundation

/// 알림 조건 원격 등록 Repository
/// Firebase SDK 설치 전 placeholder 구현체 — 실제 로직은 주석으로 남김
final class AlertRegistrationRepository: AlertRegistrationRepositoryProtocol {

    func register(condition: StockCondition, fcmToken: String) async throws {
        // TODO: Firebase SDK 설치 후 구현
        //
        // let db = Firestore.firestore()
        // let data: [String: Any] = [
        //     "conditionId": condition.id,
        //     "ticker": condition.ticker,
        //     "strategyId": condition.strategyId,
        //     "parameters": StrategyParametersMapper.encodeToDict(condition.parameters),
        //     "fcmToken": fcmToken,
        //     "isActive": condition.isActive,
        //     "createdAt": Timestamp(date: condition.createdAt)
        // ]
        // try await db.collection("alertConditions").document(condition.id).setData(data)
    }

    func unregister(conditionId: String) async throws {
        // TODO: Firebase SDK 설치 후 구현
        //
        // let db = Firestore.firestore()
        // try await db.collection("alertConditions").document(conditionId).delete()
    }

    func updateActive(conditionId: String, isActive: Bool) async throws {
        // TODO: Firebase SDK 설치 후 구현
        //
        // let db = Firestore.firestore()
        // try await db.collection("alertConditions").document(conditionId).updateData([
        //     "isActive": isActive
        // ])
    }
}

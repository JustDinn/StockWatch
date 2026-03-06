//
//  AlertRegistrationRepository.swift
//  StockWatch
//

import Foundation
import FirebaseFirestore

/// 알림 조건 원격 등록 Repository
final class AlertRegistrationRepository: AlertRegistrationRepositoryProtocol {

    private let db = Firestore.firestore()

    func register(condition: StockCondition, fcmToken: String) async throws {
        let data: [String: Any] = [
            "conditionId": condition.id,
            "ticker": condition.ticker,
            "strategyId": condition.strategyId,
            "parameters": StrategyParametersMapper.encode(condition.parameters),
            "fcmToken": fcmToken,
            "isActive": condition.isActive,
            "createdAt": Timestamp(date: condition.createdAt)
        ]
        try await db.collection("alertConditions").document(condition.id).setData(data)
    }

    func unregister(conditionId: String) async throws {
        try await db.collection("alertConditions").document(conditionId).delete()
    }

    func updateActive(conditionId: String, isActive: Bool) async throws {
        try await db.collection("alertConditions").document(conditionId).updateData([
            "isActive": isActive
        ])
    }
}

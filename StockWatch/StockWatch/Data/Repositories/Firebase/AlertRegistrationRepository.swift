//
//  AlertRegistrationRepository.swift
//  StockWatch
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AlertRegistrationError: Error {
    case unauthenticated
}

/// 알림 조건 원격 등록 Repository
final class AlertRegistrationRepository: AlertRegistrationRepositoryProtocol {

    private let db = Firestore.firestore()

    func register(condition: StockCondition, fcmToken: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AlertRegistrationError.unauthenticated
        }
        let data: [String: Any] = [
            "conditionId": condition.id,
            "ticker": condition.ticker,
            "strategyId": condition.strategyId,
            "parameters": StrategyParametersMapper.encode(condition.parameters),
            "fcmToken": fcmToken,
            "userId": userId,
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

    func updateFCMToken(userId: String, newToken: String) async throws {
        let snapshot = try await db.collection("alertConditions")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["fcmToken": newToken], forDocument: doc.reference)
        }
        try await batch.commit()
    }
}

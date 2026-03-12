//
//  BadgeResetService.swift
//  StockWatch
//

import Foundation
import UserNotifications
import FirebaseFunctions

/// 서버의 badgeCount를 0으로 리셋하고 앱 아이콘 뱃지를 초기화하는 서비스
enum BadgeResetService {

    private static let functions = Functions.functions()

    static func reset() async {
        do {
            _ = try await functions.httpsCallable("resetBadgeCount").call()
        } catch {
            print("[BadgeResetService] 뱃지 리셋 실패: \(error)")
        }

        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

//
//  BadgeResetService.swift
//  StockWatch
//

import Foundation
import UIKit
import UserNotifications
import FirebaseFunctions

/// 서버의 badgeCount를 0으로 리셋하고 앱 아이콘 뱃지를 초기화하는 서비스
enum BadgeResetService {

    private static let functions = Functions.functions()

    static func reset() async {
        do {
            _ = try await functions.httpsCallable("resetBadgeCount").call()
        } catch { }

        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }

    static func decrement() async {
        do {
            _ = try await functions.httpsCallable("decrementBadgeCount").call()
        } catch { }

        let current = await MainActor.run { UIApplication.shared.applicationIconBadgeNumber }
        try? await UNUserNotificationCenter.current().setBadgeCount(max(0, current - 1))
    }
}

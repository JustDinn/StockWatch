//
//  NotificationCenterService.swift
//  StockWatch
//

import Foundation
import UserNotifications

protocol NotificationCenterServiceProtocol {
    func removeDeliveredNotification(matchingId id: String) async
}

final class NotificationCenterService: NotificationCenterServiceProtocol {

    func removeDeliveredNotification(matchingId id: String) async {
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()
        let toRemove = delivered.filter { notification in
            let computedId = Self.computeId(
                userInfo: notification.request.content.userInfo,
                receivedAt: notification.date
            )
            return computedId == id
        }
        let identifiers = toRemove.map { $0.request.identifier }
        guard !identifiers.isEmpty else { return }
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// userInfo와 receivedAt으로부터 결정적 알림 ID를 계산한다.
    /// AppDelegate.computeNotificationId와 동일한 로직.
    static func computeId(userInfo: [AnyHashable: Any], receivedAt: Date) -> String {
        guard let ticker = userInfo["ticker"] as? String else { return "" }
        let conditionId = userInfo["conditionId"] as? String ?? ""
        let minuteKey = Int(receivedAt.timeIntervalSince1970 / 60)
        guard !conditionId.isEmpty else { return "" }
        return "\(conditionId)_\(ticker)_\(minuteKey)"
    }
}

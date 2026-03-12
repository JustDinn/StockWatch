//
//  StockWatchApp.swift
//  StockWatch
//
//  Created by HyoTaek on 2/22/26.
//

import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {

    var modelContainer: ModelContainer? {
        didSet {
            flushPendingNotifications()
        }
    }

    var pendingItems: [(userInfo: [AnyHashable: Any], receivedAt: Date)] = []

    /// 알림센터 탭 시 SwiftData에 미저장 상태인 알림의 읽음 예약 집합
    var pendingReadIds: Set<String> = []

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        application.registerForRemoteNotifications()

        // 앱이 foreground로 돌아올 때 delivered notifications 스캔
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    @objc private func appWillEnterForeground() {
        saveDeliveredNotifications()
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        FCMTokenManager.shared.save(token: token)

        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            try? await AlertRegistrationRepository().updateFCMToken(userId: uid, newToken: token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// 포그라운드에서 알림 수신 시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        saveNotification(from: notification.request.content.userInfo, receivedAt: notification.date)
        // .badge 포함 → FCM payload의 badge 절대값으로 앱 아이콘 뱃지 업데이트 (포그라운드 수신 시 뱃지 증가)
        completionHandler([.banner, .sound, .badge])
    }

    /// 백그라운드/종료 상태에서 알림 탭 시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let notifId = computeNotificationId(from: userInfo, receivedAt: response.notification.date)

        // 탭된 알림만 알림센터에서 제거
        let identifier = response.notification.request.identifier
        center.removeDeliveredNotifications(withIdentifiers: [identifier])

        // 개별 알림 읽음 처리 + 뱃지 -1
        if let container = modelContainer {
            Task { @MainActor in
                let repo = NotificationHistoryRepository(modelContext: container.mainContext)
                let didChange = (try? MarkNotificationAsReadUseCase(repository: repo).execute(id: notifId)) ?? false
                if didChange {
                    await BadgeResetService.decrement()
                } else {
                    // 아직 SwiftData에 미저장 → 저장 완료 후 읽음 처리 예약
                    pendingReadIds.insert(notifId)
                }
            }
        } else {
            pendingReadIds.insert(notifId)
        }

        saveNotification(from: userInfo, receivedAt: response.notification.date)

        if let ticker = userInfo["ticker"] as? String {
            Task { @MainActor in
                DeepLinkManager.shared.pendingTicker = ticker
            }
        }

        completionHandler()
    }
}

// MARK: - Private

private extension AppDelegate {

    /// 알림센터에 남아있는 delivered notifications를 모두 스캔하여 저장
    func saveDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notifications in
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                self?.saveNotification(from: userInfo, receivedAt: notification.date)
            }
        }
    }

    func saveNotification(from userInfo: [AnyHashable: Any], receivedAt: Date = Date()) {
        guard let container = modelContainer else {
            pendingItems.append((userInfo: userInfo, receivedAt: receivedAt))
            return
        }

        persistNotification(userInfo, receivedAt: receivedAt, container: container)
    }

    func flushPendingNotifications() {
        guard !pendingItems.isEmpty, let container = modelContainer else { return }
        let pending = pendingItems
        pendingItems = []
        for item in pending {
            persistNotification(item.userInfo, receivedAt: item.receivedAt, container: container)
        }
    }

    /// 알림 userInfo로부터 결정적 ID를 계산한다.
    /// receivedAt 기준 minuteKey를 사용하여 탭 시점과 무관하게 일치를 보장한다.
    func computeNotificationId(from userInfo: [AnyHashable: Any], receivedAt: Date) -> String {
        guard let ticker = userInfo["ticker"] as? String else { return UUID().uuidString }
        let conditionId = userInfo["conditionId"] as? String ?? ""
        let minuteKey = Int(receivedAt.timeIntervalSince1970 / 60)
        return conditionId.isEmpty
            ? UUID().uuidString
            : "\(conditionId)_\(ticker)_\(minuteKey)"
    }

    private func persistNotification(_ userInfo: [AnyHashable: Any], receivedAt: Date, container: ModelContainer) {
        guard let ticker = userInfo["ticker"] as? String else { return }

        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]

        let strategyName = userInfo["strategyName"] as? String
            ?? (alert?["title"] as? String)
            ?? "알림"
        let body = userInfo["body"] as? String
            ?? (alert?["body"] as? String)
            ?? ""
        let logoURL = userInfo["logoURL"] as? String ?? ""

        let conditionId = userInfo["conditionId"] as? String ?? ""
        let itemId = computeNotificationId(from: userInfo, receivedAt: receivedAt)

        let item = NotificationItem(
            id: itemId,
            conditionId: conditionId,
            ticker: ticker,
            logoURL: logoURL,
            strategyName: strategyName,
            body: body,
            receivedAt: receivedAt,
            isRead: false
        )

        Task { @MainActor in
            let context = container.mainContext
            let repo = NotificationHistoryRepository(modelContext: context)
            try? SaveNotificationUseCase(repository: repo).execute(item)

            // pendingReadIds 확인: 저장 완료 직후 읽음 처리 (알림센터 탭 후 미저장 시나리오)
            if pendingReadIds.contains(itemId) {
                pendingReadIds.remove(itemId)
                let didChange = (try? MarkNotificationAsReadUseCase(repository: repo).execute(id: itemId)) ?? false
                if didChange {
                    await BadgeResetService.decrement()
                }
            }
        }
    }
}

// MARK: - App

@main
struct StockWatchApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var isAuthReady = false

    var body: some Scene {
        WindowGroup {
            if isAuthReady {
                MainTabView()
            } else {
                ProgressView()
                    .task {
                        if Auth.auth().currentUser == nil {
                            try? await Auth.auth().signInAnonymously()
                        }
                        isAuthReady = true
                    }
            }
        }
        .modelContainer(
            for: [FavoriteStock.self, SavedStrategy.self, StockConditionModel.self, NotificationHistoryModel.self]
        ) { result in
            if case .success(let container) = result {
                delegate.modelContainer = container
            }
        }
    }
}

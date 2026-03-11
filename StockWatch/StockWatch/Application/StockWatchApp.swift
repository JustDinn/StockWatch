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
        completionHandler([.banner, .badge, .sound])
    }

    /// 백그라운드/종료 상태에서 알림 탭 시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
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
            // 저장 완료 후 delivered 목록 초기화 → 다음 스캔 시 중복 방지
            if !notifications.isEmpty {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
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

        // deterministic ID: 같은 conditionId+ticker+분 조합은 동일 ID → SwiftData unique constraint가 중복 방지
        let conditionId = userInfo["conditionId"] as? String ?? ""
        let minuteKey = Int(Date().timeIntervalSince1970 / 60)
        let itemId = conditionId.isEmpty
            ? UUID().uuidString
            : "\(conditionId)_\(ticker)_\(minuteKey)"

        let item = NotificationItem(
            id: itemId,
            ticker: ticker,
            logoURL: logoURL,
            strategyName: strategyName,
            body: body,
            receivedAt: receivedAt
        )

        Task { @MainActor in
            let context = container.mainContext
            let repo = NotificationHistoryRepository(modelContext: context)
            try? SaveNotificationUseCase(repository: repo).execute(item)
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

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

    var pendingUserInfos: [[AnyHashable: Any]] = []

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
        print("<< appWillEnterForeground - scanning delivered notifications")
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
        print("<< willPresent (foreground)")
        saveNotification(from: notification.request.content.userInfo)
        completionHandler([.banner, .badge, .sound])
    }

    /// 백그라운드/종료 상태에서 알림 탭 시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("<< didReceive (tapped)")
        let userInfo = response.notification.request.content.userInfo
        saveNotification(from: userInfo)

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
            print("<< delivered notifications count: \(notifications.count)")
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                self?.saveNotification(from: userInfo)
            }
        }
    }

    func saveNotification(from userInfo: [AnyHashable: Any]) {
        print("<< saveNotification called")
        guard let container = modelContainer else {
            print("<< modelContainer is nil, pending")
            pendingUserInfo = userInfo
            return
        }

        persistNotification(userInfo, container: container)
    }

    func flushPendingNotification() {
        guard let userInfo = pendingUserInfo, let container = modelContainer else { return }
        pendingUserInfo = nil
        persistNotification(userInfo, container: container)
    }

    private func persistNotification(_ userInfo: [AnyHashable: Any], container: ModelContainer) {
        guard let ticker = userInfo["ticker"] as? String else {
            print("<< persistNotification - ticker not found in userInfo")
            return
        }

        print("<< persistNotification - ticker: \(ticker)")

        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]

        let strategyName = userInfo["strategyName"] as? String
            ?? (alert?["title"] as? String)
            ?? "알림"
        let body = userInfo["body"] as? String
            ?? (alert?["body"] as? String)
            ?? ""
        let logoURL = userInfo["logoURL"] as? String ?? ""

        // 같은 ticker + strategyName 조합이 같은 분(minute) 내 중복 저장 방지
        let deduplicationKey = "\(ticker)_\(strategyName)_\(Int(Date().timeIntervalSince1970 / 60))"
        guard !recentlySavedIds.contains(deduplicationKey) else {
            print("<< deduplication skip: \(deduplicationKey)")
            return
        }
        recentlySavedIds.insert(deduplicationKey)

        let item = NotificationItem(
            id: UUID().uuidString,
            ticker: ticker,
            logoURL: logoURL,
            strategyName: strategyName,
            body: body,
            receivedAt: Date()
        )

        Task { @MainActor in
            let context = container.mainContext
            let repo = NotificationHistoryRepository(modelContext: context)
            do {
                try SaveNotificationUseCase(repository: repo).execute(item)
                print("<< notification saved successfully")
            } catch {
                print("<< notification save error: \(error)")
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

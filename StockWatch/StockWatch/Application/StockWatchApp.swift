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
            flushPendingNotification()
        }
    }

    var pendingUserInfo: [AnyHashable: Any]?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        application.registerForRemoteNotifications()

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
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

    /// 포그라운드에서 알림 수신 시 (앱이 열려 있을 때)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        saveNotification(from: notification.request.content.userInfo)
        completionHandler([.banner, .badge, .sound])
    }

    /// 백그라운드/종료 상태에서 알림 탭 시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        saveNotification(from: response.notification.request.content.userInfo)
        completionHandler()
    }
}

// MARK: - Private

private extension AppDelegate {

    func saveNotification(from userInfo: [AnyHashable: Any]) {
        guard let container = modelContainer else {
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
        guard
            let ticker = userInfo["ticker"] as? String,
            let strategyName = userInfo["strategyName"] as? String,
            let body = userInfo["body"] as? String
        else {
            // TODO: 에러 처리
            
            return
        }

        let logoURL = userInfo["logoURL"] as? String ?? ""
        let item = NotificationItem(
            id: UUID().uuidString,
            ticker: ticker,
            logoURL: logoURL,
            strategyName: strategyName,
            body: body,
            receivedAt: Date()
        )

        let context = ModelContext(container)
        let repo = NotificationHistoryRepository(modelContext: context)
        do {
            try SaveNotificationUseCase(repository: repo).execute(item)
        } catch {
            
            // TODO: 에러 처리
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

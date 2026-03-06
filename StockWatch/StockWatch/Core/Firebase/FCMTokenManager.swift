//
//  FCMTokenManager.swift
//  StockWatch
//
//  NOTE: Firebase Messaging SDK 설치 후 아래 구현을 활성화한다.
//

import Foundation

/// FCM 디바이스 토큰 관리
/// UserDefaults에 토큰을 캐시하여 제공한다.
final class FCMTokenManager {

    static let shared = FCMTokenManager()
    private let tokenKey = "fcm_device_token"
    private init() {}

    /// 저장된 FCM 토큰 반환 (없으면 빈 문자열)
    var currentToken: String {
        UserDefaults.standard.string(forKey: tokenKey) ?? ""
    }

    /// FCM 토큰 저장
    func save(token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    // TODO: Firebase Messaging SDK 설치 후 AppDelegate에 아래 코드 추가
    //
    // import FirebaseMessaging
    //
    // func application(_ application: UIApplication,
    //   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    //     Messaging.messaging().apnsToken = deviceToken
    // }
    //
    // extension AppDelegate: MessagingDelegate {
    //     func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    //         guard let token = fcmToken else { return }
    //         FCMTokenManager.shared.save(token: token)
    //     }
    // }
}

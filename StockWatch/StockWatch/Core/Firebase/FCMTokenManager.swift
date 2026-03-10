//
//  FCMTokenManager.swift
//  StockWatch
//

import Foundation

/// FCM 디바이스 토큰 관리
/// UserDefaults에 토큰을 캐시하여 제공한다.
final class FCMTokenManager: ObservableObject {

    static let shared = FCMTokenManager()
    private let tokenKey = "fcm_device_token"
    private init() {}

    /// 저장된 FCM 토큰 (없으면 빈 문자열, 변경 시 @Published 트리거)
    @Published private(set) var currentToken: String = UserDefaults.standard.string(forKey: "fcm_device_token") ?? ""

    /// FCM 토큰 저장
    func save(token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        currentToken = token
    }
}

//
//  DeepLinkManager.swift
//  StockWatch
//

import SwiftUI

/// 앱 전역 딥링크 상태 관리
/// 푸시 알림 탭 시 StockDetailView로 이동을 조율한다.
@MainActor
final class DeepLinkManager: ObservableObject {

    static let shared = DeepLinkManager()

    @Published var pendingTicker: String?

    private init() {}
}

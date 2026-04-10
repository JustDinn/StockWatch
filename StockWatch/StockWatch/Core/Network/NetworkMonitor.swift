//
//  NetworkMonitor.swift
//  StockWatch
//

import Foundation
import Network
import Combine

// MARK: - Protocol

protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    /// 연결 복구 이벤트를 수신하는 AsyncStream을 새로 생성한다.
    /// 여러 소비자가 독립적으로 구독할 수 있도록 호출마다 새 스트림을 반환한다.
    func makeConnectionRestoredStream() -> AsyncStream<Void>
}

// MARK: - Implementation

/// NWPathMonitor 기반 네트워크 연결 상태 감지 서비스.
/// 연결이 끊겼다가 복구되는 시점에 등록된 모든 구독자에게 이벤트를 방출한다.
/// `ObservableObject`를 채택하여 SwiftUI View에서 연결 상태 변화를 실시간으로 반영할 수 있다.
@MainActor
final class NetworkMonitor: ObservableObject, NetworkMonitorProtocol {

    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.stockwatch.networkmonitor")

    /// 등록된 모든 구독자의 continuation 목록 (multicast)
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    @Published private(set) var isConnected: Bool = true

    private init() {
        nonisolated(unsafe) var previousStatus: NWPath.Status?

        monitor.pathUpdateHandler = { [weak self] path in
            let current = path.status
            let isNowConnected = current == .satisfied
            let wasDisconnected = previousStatus.map { $0 != .satisfied } ?? false
            previousStatus = current

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = isNowConnected

                // .unsatisfied → .satisfied 전환 시 모든 구독자에게 이벤트 방출
                if wasDisconnected && isNowConnected {
                    self.continuations.values.forEach { $0.yield() }
                }
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        continuations.values.forEach { $0.finish() }
    }

    /// 연결 복구 이벤트 스트림을 생성한다. 구독 해제 시 자동으로 등록이 취소된다.
    func makeConnectionRestoredStream() -> AsyncStream<Void> {
        let id = UUID()
        return AsyncStream<Void> { [weak self] continuation in
            Task { @MainActor [weak self] in
                self?.continuations[id] = continuation
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }
}

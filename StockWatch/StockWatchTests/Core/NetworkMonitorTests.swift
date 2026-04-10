//
//  NetworkMonitorTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

// MARK: - Mock

final class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool
    private var continuations: [AsyncStream<Void>.Continuation] = []

    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }

    func makeConnectionRestoredStream() -> AsyncStream<Void> {
        AsyncStream<Void> { [weak self] continuation in
            self?.continuations.append(continuation)
        }
    }

    func simulateRestored() {
        isConnected = true
        continuations.forEach { $0.yield() }
    }

    func simulateDisconnected() {
        isConnected = false
    }
}

// MARK: - Tests

@MainActor
final class NetworkMonitorTests: XCTestCase {

    // isConnected 초기값은 true
    func test_initialState_isConnected() {
        let mock = MockNetworkMonitor(isConnected: true)
        XCTAssertTrue(mock.isConnected)
    }

    // 연결 끊김 시뮬레이션 후 isConnected == false
    func test_simulateDisconnected_setsIsConnectedFalse() {
        let mock = MockNetworkMonitor(isConnected: true)
        mock.simulateDisconnected()
        XCTAssertFalse(mock.isConnected)
    }

    // 복구 시뮬레이션 시 makeConnectionRestoredStream이 이벤트를 방출
    func test_simulateRestored_yieldsConnectionRestoredEvent() async {
        let mock = MockNetworkMonitor(isConnected: false)
        let expectation = expectation(description: "connectionRestored 이벤트 수신")

        let task = Task {
            for await _ in mock.makeConnectionRestoredStream() {
                expectation.fulfill()
                break
            }
        }

        // 구독 Task가 스트림을 등록할 시간을 확보
        try? await Task.sleep(nanoseconds: 10_000_000)
        mock.simulateRestored()
        await fulfillment(of: [expectation], timeout: 1.0)
        task.cancel()

        XCTAssertTrue(mock.isConnected)
    }

    // 여러 소비자가 동시에 이벤트를 받을 수 있는지 확인 (multicast)
    func test_simulateRestored_notifiesMultipleSubscribers() async {
        let mock = MockNetworkMonitor(isConnected: false)
        let exp1 = expectation(description: "subscriber 1")
        let exp2 = expectation(description: "subscriber 2")

        let task1 = Task {
            for await _ in mock.makeConnectionRestoredStream() { exp1.fulfill(); break }
        }
        let task2 = Task {
            for await _ in mock.makeConnectionRestoredStream() { exp2.fulfill(); break }
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
        mock.simulateRestored()
        await fulfillment(of: [exp1, exp2], timeout: 1.0)
        task1.cancel(); task2.cancel()
    }

    // NetworkMonitor.shared는 싱글톤
    func test_shared_isSingleton() {
        let a = NetworkMonitor.shared
        let b = NetworkMonitor.shared
        XCTAssertTrue(a === b)
    }

    // NetworkMonitor.shared의 초기 isConnected는 Bool (타입 확인)
    func test_shared_isConnectedIsAvailable() {
        let monitor = NetworkMonitor.shared
        _ = monitor.isConnected
        _ = monitor.makeConnectionRestoredStream()
    }
}

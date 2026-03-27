//
//  MAIndicatorStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

@MainActor
final class MAIndicatorStoreTests: XCTestCase {

    private var store: MAIndicatorStore!

    override func setUp() {
        super.setUp()
        store = MAIndicatorStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_hasTwoDefaultPeriods() {
        XCTAssertEqual(store.state.periods.count, 2)
    }

    // MARK: - addPeriod

    func test_action_addPeriod_appendsPeriod() {
        store.action(.addPeriod)

        XCTAssertEqual(store.state.periods.count, 3)
    }

    func test_action_addPeriod_whenMaxReached_doesNotAppend() {
        for _ in 0..<3 {
            store.action(.addPeriod)
        }

        XCTAssertEqual(store.state.periods.count, MAIndicatorState.maxPeriodCount)

        store.action(.addPeriod)

        XCTAssertEqual(store.state.periods.count, MAIndicatorState.maxPeriodCount)
    }

    // MARK: - removePeriod

    func test_action_removePeriod_removesPeriod() {
        let targetId = store.state.periods[0].id

        store.action(.removePeriod(id: targetId))

        XCTAssertEqual(store.state.periods.count, 1)
        XCTAssertFalse(store.state.periods.contains { $0.id == targetId })
    }

    func test_action_removePeriod_withUnknownId_doesNothing() {
        store.action(.removePeriod(id: UUID()))

        XCTAssertEqual(store.state.periods.count, 2)
    }

    // MARK: - updatePeriod

    func test_action_updatePeriod_updatesPeriodValue() {
        let targetId = store.state.periods[0].id

        store.action(.updatePeriod(id: targetId, period: 50))

        XCTAssertEqual(store.state.periods[0].period, 50)
    }

    func test_action_updatePeriod_withUnknownId_doesNothing() {
        let originalPeriods = store.state.periods

        store.action(.updatePeriod(id: UUID(), period: 99))

        XCTAssertEqual(store.state.periods, originalPeriods)
    }

    // MARK: - reset

    func test_action_reset_restoresDefaultTwoPeriods() {
        store.action(.addPeriod)
        store.action(.addPeriod)
        XCTAssertEqual(store.state.periods.count, 4)

        store.action(.reset)

        XCTAssertEqual(store.state.periods.count, 2)
    }

    func test_action_reset_restoresDefaultPeriodValues() {
        let targetId = store.state.periods[0].id
        store.action(.updatePeriod(id: targetId, period: 999))

        store.action(.reset)

        XCTAssertEqual(store.state.periods[0].period, MAIndicatorState.defaultPeriods[0].period)
        XCTAssertEqual(store.state.periods[1].period, MAIndicatorState.defaultPeriods[1].period)
    }
}

//
//  VolumeIndicatorStoreTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

@MainActor
final class VolumeIndicatorStoreTests: XCTestCase {

    private var store: VolumeIndicatorStore!

    override func setUp() {
        super.setUp()
        store = VolumeIndicatorStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_isDisabled() {
        XCTAssertFalse(store.state.line.isEnabled)
    }

    func test_initialState_hasDefaultValues() {
        XCTAssertEqual(store.state.line.period, 20)
        XCTAssertEqual(store.state.line.colorHex, "#4CAF50")
        XCTAssertEqual(store.state.line.lineWidth, 1)
    }

    // MARK: - toggleEnabled

    func test_action_toggleEnabled_enablesLine() {
        store.action(.toggleEnabled)

        XCTAssertTrue(store.state.line.isEnabled)
    }

    func test_action_toggleEnabled_twice_disablesLine() {
        store.action(.toggleEnabled)
        store.action(.toggleEnabled)

        XCTAssertFalse(store.state.line.isEnabled)
    }

    // MARK: - updatePeriod

    func test_action_updatePeriod_changesPeriod() {
        store.action(.updatePeriod(50))

        XCTAssertEqual(store.state.line.period, 50)
    }

    // MARK: - updateColor

    func test_action_updateColor_changesColor() {
        store.action(.updateColor("#FF0000"))

        XCTAssertEqual(store.state.line.colorHex, "#FF0000")
    }

    // MARK: - updateLineWidth

    func test_action_updateLineWidth_changesWidth() {
        store.action(.updateLineWidth(3))

        XCTAssertEqual(store.state.line.lineWidth, 3)
    }

    // MARK: - reset

    func test_action_reset_restoresDefaultValues() {
        store.action(.toggleEnabled)
        store.action(.updatePeriod(50))
        store.action(.updateColor("#FF0000"))
        store.action(.updateLineWidth(3))

        store.action(.reset)

        XCTAssertFalse(store.state.line.isEnabled)
        XCTAssertEqual(store.state.line.period, 20)
        XCTAssertEqual(store.state.line.colorHex, "#4CAF50")
        XCTAssertEqual(store.state.line.lineWidth, 1)
    }

    // MARK: - confirm

    func test_action_confirm_callsOnConfirmWithCurrentConfiguration() {
        store.action(.toggleEnabled)
        store.action(.updatePeriod(30))

        var confirmedConfig: VolumeMAConfiguration?
        let storeWithCallback = VolumeIndicatorStore(
            state: store.state,
            onConfirm: { confirmedConfig = $0 }
        )

        storeWithCallback.action(.confirm)

        XCTAssertNotNil(confirmedConfig)
        XCTAssertTrue(confirmedConfig!.line.isEnabled)
        XCTAssertEqual(confirmedConfig!.line.period, 30)
    }

    func test_action_confirm_withoutCallback_doesNotCrash() {
        XCTAssertNoThrow(store.action(.confirm))
    }
}

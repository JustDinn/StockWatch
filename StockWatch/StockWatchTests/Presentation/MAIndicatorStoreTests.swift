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

    func test_initialState_hasTwoDefaultLines() {
        XCTAssertEqual(store.state.lines.count, 2)
    }

    // MARK: - addLine

    func test_action_addLine_appendsLine() {
        store.action(.addLine)

        XCTAssertEqual(store.state.lines.count, 3)
    }

    func test_action_addLine_whenMaxReached_doesNotAppend() {
        for _ in 0..<3 {
            store.action(.addLine)
        }

        XCTAssertEqual(store.state.lines.count, MAIndicatorState.maxLineCount)

        store.action(.addLine)

        XCTAssertEqual(store.state.lines.count, MAIndicatorState.maxLineCount)
    }

    // MARK: - removeLine

    func test_action_removeLine_removesLine() {
        let targetId = store.state.lines[0].id

        store.action(.removeLine(id: targetId))

        XCTAssertEqual(store.state.lines.count, 1)
        XCTAssertFalse(store.state.lines.contains { $0.id == targetId })
    }

    func test_action_removeLine_withUnknownId_doesNothing() {
        store.action(.removeLine(id: UUID()))

        XCTAssertEqual(store.state.lines.count, 2)
    }

    // MARK: - updatePeriod

    func test_action_updatePeriod_updatesPeriodValue() {
        let targetId = store.state.lines[0].id

        store.action(.updatePeriod(id: targetId, period: 50))

        XCTAssertEqual(store.state.lines[0].period, 50)
    }

    func test_action_updatePeriod_withUnknownId_doesNothing() {
        let originalLines = store.state.lines

        store.action(.updatePeriod(id: UUID(), period: 99))

        XCTAssertEqual(store.state.lines, originalLines)
    }

    // MARK: - reset

    func test_action_reset_restoresDefaultTwoLines() {
        store.action(.addLine)
        store.action(.addLine)
        XCTAssertEqual(store.state.lines.count, 4)

        store.action(.reset)

        XCTAssertEqual(store.state.lines.count, 2)
    }

    func test_action_reset_restoresDefaultLineValues() {
        let targetId = store.state.lines[0].id
        store.action(.updatePeriod(id: targetId, period: 999))

        store.action(.reset)

        XCTAssertEqual(store.state.lines[0].period, MAIndicatorState.defaultLines[0].period)
        XCTAssertEqual(store.state.lines[1].period, MAIndicatorState.defaultLines[1].period)
    }
}

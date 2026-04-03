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

    // MARK: - updateColor

    func test_action_updateColor_updatesColorHex() {
        let targetId = store.state.lines[0].id

        store.action(.updateColor(id: targetId, colorHex: "#FF0000"))

        XCTAssertEqual(store.state.lines[0].colorHex, "#FF0000")
    }

    func test_action_updateColor_withUnknownId_doesNothing() {
        let original = store.state.lines

        store.action(.updateColor(id: UUID(), colorHex: "#FF0000"))

        XCTAssertEqual(store.state.lines, original)
    }

    // MARK: - updateLineWidth

    func test_action_updateLineWidth_updatesValue() {
        let targetId = store.state.lines[0].id

        store.action(.updateLineWidth(id: targetId, lineWidth: 3))

        XCTAssertEqual(store.state.lines[0].lineWidth, 3)
    }

    func test_action_updateLineWidth_withUnknownId_doesNothing() {
        let original = store.state.lines

        store.action(.updateLineWidth(id: UUID(), lineWidth: 2))

        XCTAssertEqual(store.state.lines, original)
    }

    // MARK: - updatePriceSource

    func test_action_updatePriceSource_updatesValue() {
        let targetId = store.state.lines[0].id

        store.action(.updatePriceSource(id: targetId, priceSource: .open))

        XCTAssertEqual(store.state.lines[0].priceSource, .open)
    }

    func test_action_updatePriceSource_withUnknownId_doesNothing() {
        let original = store.state.lines

        store.action(.updatePriceSource(id: UUID(), priceSource: .open))

        XCTAssertEqual(store.state.lines, original)
    }

    func test_action_addLine_hasDefaultPriceSourceClose() {
        store.action(.addLine)

        XCTAssertEqual(store.state.lines.last?.priceSource, .close)
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

    func test_action_reset_restoresDefaultPriceSource() {
        let targetId = store.state.lines[0].id
        store.action(.updatePriceSource(id: targetId, priceSource: .open))

        store.action(.reset)

        XCTAssertEqual(store.state.lines[0].priceSource, .close)
    }
}

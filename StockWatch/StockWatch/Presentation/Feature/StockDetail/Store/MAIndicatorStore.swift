//
//  MAIndicatorStore.swift
//  StockWatch
//

import Foundation

@MainActor
final class MAIndicatorStore: ObservableObject {

    @Published private(set) var state: MAIndicatorState
    private let onConfirm: ((MAIndicatorConfiguration) -> Void)?

    init(
        state: MAIndicatorState = MAIndicatorState(),
        onConfirm: ((MAIndicatorConfiguration) -> Void)? = nil
    ) {
        self.state = state
        self.onConfirm = onConfirm
    }

    func action(_ intent: MAIndicatorIntent) {
        switch intent {
        case .addLine:
            addLine()
        case .removeLine(let id):
            removeLine(id: id)
        case .updatePeriod(let id, let period):
            updatePeriod(id: id, period: period)
        case .updateColor(let id, let colorHex):
            updateColor(id: id, colorHex: colorHex)
        case .updateLineWidth(let id, let lineWidth):
            updateLineWidth(id: id, lineWidth: lineWidth)
        case .updatePriceSource(let id, let priceSource):
            updatePriceSource(id: id, priceSource: priceSource)
        case .reset:
            reset()
        case .confirm:
            confirm()
        }
    }

    private func addLine() {
        guard state.lines.count < MAIndicatorState.maxLineCount else { return }
        let colorIndex = state.lines.count % MAIndicatorState.defaultColors.count
        let newLine = MALine(
            period: 20,
            colorHex: MAIndicatorState.defaultColors[colorIndex],
            lineWidth: 1
        )
        state.lines.append(newLine)
    }

    private func removeLine(id: UUID) {
        state.lines.removeAll { $0.id == id }
    }

    private func updatePeriod(id: UUID, period: Int) {
        guard let index = state.lines.firstIndex(where: { $0.id == id }) else { return }
        state.lines[index].period = period
    }

    private func updateColor(id: UUID, colorHex: String) {
        guard let index = state.lines.firstIndex(where: { $0.id == id }) else { return }
        state.lines[index].colorHex = colorHex
    }

    private func updateLineWidth(id: UUID, lineWidth: Int) {
        guard let index = state.lines.firstIndex(where: { $0.id == id }) else { return }
        state.lines[index].lineWidth = lineWidth
    }

    private func updatePriceSource(id: UUID, priceSource: MAPriceSource) {
        guard let index = state.lines.firstIndex(where: { $0.id == id }) else { return }
        state.lines[index].priceSource = priceSource
    }

    private func reset() {
        state.lines = MAIndicatorState.defaultLines
    }

    private func confirm() {
        onConfirm?(state.toConfiguration())
    }
}

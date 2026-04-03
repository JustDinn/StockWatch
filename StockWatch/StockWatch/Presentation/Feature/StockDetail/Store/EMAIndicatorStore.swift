//
//  EMAIndicatorStore.swift
//  StockWatch
//

import Foundation

@MainActor
final class EMAIndicatorStore: ObservableObject {

    @Published private(set) var state: EMAIndicatorState
    private let onConfirm: ((EMAIndicatorConfiguration) -> Void)?

    init(
        state: EMAIndicatorState = EMAIndicatorState(),
        onConfirm: ((EMAIndicatorConfiguration) -> Void)? = nil
    ) {
        self.state = state
        self.onConfirm = onConfirm
    }

    func action(_ intent: EMAIndicatorIntent) {
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
        guard state.lines.count < EMAIndicatorState.maxLineCount else { return }
        let colorIndex = state.lines.count % EMAIndicatorState.defaultColors.count
        let newLine = EMALine(
            period: 20,
            colorHex: EMAIndicatorState.defaultColors[colorIndex],
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

    private func updatePriceSource(id: UUID, priceSource: EMAPriceSource) {
        guard let index = state.lines.firstIndex(where: { $0.id == id }) else { return }
        state.lines[index].priceSource = priceSource
    }

    private func reset() {
        state.lines = EMAIndicatorState.defaultLines
    }

    private func confirm() {
        onConfirm?(state.toConfiguration())
    }
}

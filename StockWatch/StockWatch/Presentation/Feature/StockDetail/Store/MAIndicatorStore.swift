//
//  MAIndicatorStore.swift
//  StockWatch
//

import Foundation

@MainActor
final class MAIndicatorStore: ObservableObject {

    @Published private(set) var state: MAIndicatorState

    init(state: MAIndicatorState = MAIndicatorState()) {
        self.state = state
    }

    func action(_ intent: MAIndicatorIntent) {
        switch intent {
        case .addPeriod:
            addPeriod()
        case .removePeriod(let id):
            removePeriod(id: id)
        case .updatePeriod(let id, let period):
            updatePeriod(id: id, period: period)
        case .reset:
            reset()
        case .confirm:
            break
        }
    }

    private func addPeriod() {
        guard state.periods.count < MAIndicatorState.maxPeriodCount else { return }
        let colorIndex = state.periods.count % MAIndicatorState.defaultColors.count
        let newPeriod = MAIndicatorPeriod(
            id: UUID(),
            period: 20,
            colorHex: MAIndicatorState.defaultColors[colorIndex],
            lineWidth: 1
        )
        state.periods.append(newPeriod)
    }

    private func removePeriod(id: UUID) {
        state.periods.removeAll { $0.id == id }
    }

    private func updatePeriod(id: UUID, period: Int) {
        guard let index = state.periods.firstIndex(where: { $0.id == id }) else { return }
        state.periods[index].period = period
    }

    private func reset() {
        state.periods = MAIndicatorState.defaultPeriods
    }
}

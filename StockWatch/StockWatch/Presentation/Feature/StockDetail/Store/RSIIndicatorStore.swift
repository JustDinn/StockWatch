//
//  RSIIndicatorStore.swift
//  StockWatch
//

import Foundation

@MainActor
final class RSIIndicatorStore: ObservableObject {

    @Published private(set) var state: RSIIndicatorState
    private let onConfirm: ((RSIConfiguration) -> Void)?

    init(
        state: RSIIndicatorState = RSIIndicatorState(),
        onConfirm: ((RSIConfiguration) -> Void)? = nil
    ) {
        self.state = state
        self.onConfirm = onConfirm
    }

    func action(_ intent: RSIIndicatorIntent) {
        switch intent {
        case .updatePeriod(let period):
            state.line.period = period
        case .updateLineColor(let colorHex):
            state.line.colorHex = colorHex
        case .updateLineWidth(let lineWidth):
            state.line.lineWidth = lineWidth
        case .toggleLineEnabled:
            state.line.isEnabled.toggle()
        case .updateUpperLevel(let value):
            state.upperLevel.value = value
        case .toggleUpperLevel:
            state.upperLevel.isEnabled.toggle()
        case .updateMiddleLevel(let value):
            state.middleLevel.value = value
        case .toggleMiddleLevel:
            state.middleLevel.isEnabled.toggle()
        case .updateLowerLevel(let value):
            state.lowerLevel.value = value
        case .toggleLowerLevel:
            state.lowerLevel.isEnabled.toggle()
        case .updateBackgroundColor(let colorHex):
            state.background.colorHex = colorHex
        case .toggleBackground:
            state.background.isEnabled.toggle()
        case .reset:
            state = RSIIndicatorState()
        case .confirm:
            onConfirm?(state.toConfiguration())
        }
    }
}

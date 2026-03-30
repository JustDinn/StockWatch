//
//  VolumeIndicatorStore.swift
//  StockWatch
//

import Foundation

@MainActor
final class VolumeIndicatorStore: ObservableObject {

    @Published private(set) var state: VolumeIndicatorState
    private let onConfirm: ((VolumeMAConfiguration) -> Void)?

    init(
        state: VolumeIndicatorState = VolumeIndicatorState(),
        onConfirm: ((VolumeMAConfiguration) -> Void)? = nil
    ) {
        self.state = state
        self.onConfirm = onConfirm
    }

    func action(_ intent: VolumeIndicatorIntent) {
        switch intent {
        case .toggleEnabled:
            state.line.isEnabled.toggle()
        case .updatePeriod(let period):
            state.line.period = period
        case .updateColor(let colorHex):
            state.line.colorHex = colorHex
        case .updateLineWidth(let lineWidth):
            state.line.lineWidth = lineWidth
        case .reset:
            state = VolumeIndicatorState()
        case .confirm:
            onConfirm?(state.toConfiguration())
        }
    }
}

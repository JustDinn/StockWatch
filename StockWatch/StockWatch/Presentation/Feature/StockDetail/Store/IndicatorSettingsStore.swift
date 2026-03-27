//
//  IndicatorSettingsStore.swift
//  StockWatch
//

import Foundation
import SwiftUI

@MainActor
final class IndicatorSettingsStore: ObservableObject {

    @Published private(set) var state: IndicatorSettingsState = .init()

    func action(_ intent: IndicatorSettingsIntent) {
        switch intent {
        case .toggleIndicator(let indicator):
            if state.enabledIndicators.contains(indicator) {
                state.enabledIndicators.remove(indicator)
            } else {
                state.enabledIndicators.insert(indicator)
            }
        case .resetAll:
            state.enabledIndicators = []
        case .selectTab(let tab):
            state.selectedTab = tab
        case .apply:
            break
        }
    }

    func enabledBinding(for indicator: TechnicalIndicator) -> Binding<Bool> {
        Binding(
            get: { self.state.isEnabled(indicator) },
            set: { _ in self.action(.toggleIndicator(indicator)) }
        )
    }
}

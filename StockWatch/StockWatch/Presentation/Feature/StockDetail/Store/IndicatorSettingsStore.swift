//
//  IndicatorSettingsStore.swift
//  StockWatch
//

import Foundation
import SwiftUI

@MainActor
final class IndicatorSettingsStore: ObservableObject {

    @Published private(set) var state: IndicatorSettingsState

    private let manager = TechnicalIndicatorSettingsManager.shared

    init() {
        // Manager에서 현재 설정 로드
        var initialState = IndicatorSettingsState()
        if manager.isMAEnabled {
            initialState.enabledIndicators.insert(.movingAverage)
        }
        self.state = initialState
    }

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
            state.stagedMAConfig = nil
        case .selectTab(let tab):
            state.selectedTab = tab
        case .apply:
            apply()
        case .stageMAConfig(let config):
            state.stagedMAConfig = config
        }
    }

    var currentMAState: MAIndicatorState {
        MAIndicatorState(configuration: manager.maConfiguration)
    }

    func enabledBinding(for indicator: TechnicalIndicator) -> Binding<Bool> {
        Binding(
            get: { self.state.isEnabled(indicator) },
            set: { _ in self.action(.toggleIndicator(indicator)) }
        )
    }

    private func apply() {
        // 이동평균선 설정 적용
        if let config = state.stagedMAConfig {
            manager.updateMAConfiguration(config)
        }

        // 활성화 상태 적용
        manager.updateMAEnabled(state.enabledIndicators.contains(.movingAverage))

        // staged 설정 초기화
        state.stagedMAConfig = nil
    }
}

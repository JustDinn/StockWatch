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
        if manager.isVolumeEnabled {
            initialState.enabledIndicators.insert(.volume)
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
        case .stageVolumeConfig(let config):
            state.stagedVolumeConfig = config
        }
    }

    var currentMAState: MAIndicatorState {
        MAIndicatorState(configuration: manager.maConfiguration)
    }

    var currentVolumeState: VolumeIndicatorState {
        VolumeIndicatorState(configuration: manager.volumeMAConfiguration)
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
        manager.updateVolumeEnabled(state.enabledIndicators.contains(.volume))

        // 거래량 이동평균선 설정 적용
        if let volumeConfig = state.stagedVolumeConfig {
            manager.updateVolumeMAConfiguration(volumeConfig)
        }

        // TODO: 차트에 거래량 이평선 실제 적용

        // staged 설정 초기화
        state.stagedMAConfig = nil
        state.stagedVolumeConfig = nil
    }
}

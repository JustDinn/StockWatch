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
        if manager.isEMAEnabled {
            initialState.enabledIndicators.insert(.exponentialMovingAverage)
        }
        if manager.isVolumeEnabled {
            initialState.enabledIndicators.insert(.volume)
        }
        if manager.isRSIEnabled {
            initialState.enabledIndicators.insert(.rsi)
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
            state.stagedEMAConfig = nil
            state.stagedRSIConfig = nil
        case .selectTab(let tab):
            state.selectedTab = tab
        case .apply:
            apply()
        case .stageMAConfig(let config):
            state.stagedMAConfig = config
        case .stageEMAConfig(let config):
            state.stagedEMAConfig = config
        case .stageVolumeConfig(let config):
            state.stagedVolumeConfig = config
        case .stageRSIConfig(let config):
            state.stagedRSIConfig = config
        }
    }

    var currentMAState: MAIndicatorState {
        MAIndicatorState(configuration: manager.maConfiguration)
    }

    var currentEMAState: EMAIndicatorState {
        EMAIndicatorState(configuration: manager.emaConfiguration)
    }

    var currentVolumeState: VolumeIndicatorState {
        VolumeIndicatorState(configuration: manager.volumeMAConfiguration)
    }

    var currentRSIState: RSIIndicatorState {
        RSIIndicatorState(configuration: manager.rsiConfiguration)
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

        // 지수이동평균선 설정 적용
        if let config = state.stagedEMAConfig {
            manager.updateEMAConfiguration(config)
        }

        // 활성화 상태 적용
        manager.updateMAEnabled(state.enabledIndicators.contains(.movingAverage))
        manager.updateEMAEnabled(state.enabledIndicators.contains(.exponentialMovingAverage))
        manager.updateVolumeEnabled(state.enabledIndicators.contains(.volume))
        manager.updateRSIEnabled(state.enabledIndicators.contains(.rsi))

        // 거래량 이동평균선 설정 적용
        if let volumeConfig = state.stagedVolumeConfig {
            manager.updateVolumeMAConfiguration(volumeConfig)
        }

        // RSI 설정 적용
        if let rsiConfig = state.stagedRSIConfig {
            manager.updateRSIConfiguration(rsiConfig)
        }

        // staged 설정 초기화
        state.stagedMAConfig = nil
        state.stagedEMAConfig = nil
        state.stagedVolumeConfig = nil
        state.stagedRSIConfig = nil
    }
}

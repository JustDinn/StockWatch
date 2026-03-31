//
//  IndicatorSettingsState.swift
//  StockWatch
//

struct IndicatorSettingsState: Equatable {
    var selectedTab: IndicatorTab = .upper
    var enabledIndicators: Set<TechnicalIndicator> = []
    var stagedMAConfig: MAIndicatorConfiguration?
    var stagedVolumeConfig: VolumeMAConfiguration?
    var stagedRSIConfig: RSIConfiguration?

    func isEnabled(_ indicator: TechnicalIndicator) -> Bool {
        enabledIndicators.contains(indicator)
    }
}

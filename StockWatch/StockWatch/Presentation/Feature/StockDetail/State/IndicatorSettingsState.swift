//
//  IndicatorSettingsState.swift
//  StockWatch
//

struct IndicatorSettingsState: Equatable {
    var selectedTab: IndicatorTab = .upper
    var enabledIndicators: Set<TechnicalIndicator> = []
    var stagedMAConfig: MAIndicatorConfiguration?

    func isEnabled(_ indicator: TechnicalIndicator) -> Bool {
        enabledIndicators.contains(indicator)
    }
}

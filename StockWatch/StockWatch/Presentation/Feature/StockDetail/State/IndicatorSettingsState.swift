//
//  IndicatorSettingsState.swift
//  StockWatch
//

struct IndicatorSettingsState: Equatable {
    var selectedTab: IndicatorTab = .upper
    var enabledIndicators: Set<TechnicalIndicator> = []

    func isEnabled(_ indicator: TechnicalIndicator) -> Bool {
        enabledIndicators.contains(indicator)
    }
}

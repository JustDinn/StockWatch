//
//  IndicatorSettingsIntent.swift
//  StockWatch
//

enum IndicatorSettingsIntent {
    case toggleIndicator(TechnicalIndicator)
    case resetAll
    case apply
    case selectTab(IndicatorTab)
    case stageMAConfig(MAIndicatorConfiguration)
    case stageVolumeConfig(VolumeMAConfiguration)
}

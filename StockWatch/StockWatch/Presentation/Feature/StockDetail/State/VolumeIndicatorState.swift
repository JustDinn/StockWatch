//
//  VolumeIndicatorState.swift
//  StockWatch
//

import Foundation

struct VolumeIndicatorState: Equatable {
    var line: VolumeMALine

    static let defaultLine = VolumeMALine(period: 20, colorHex: "#4CAF50", lineWidth: 1, isEnabled: false)

    init(line: VolumeMALine = defaultLine) {
        self.line = line
    }

    init(configuration: VolumeMAConfiguration) {
        self.line = configuration.line
    }

    func toConfiguration() -> VolumeMAConfiguration {
        VolumeMAConfiguration(line: line)
    }
}

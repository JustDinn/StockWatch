//
//  SettingsStore.swift
//  StockWatch
//

import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: SettingsState

    @AppStorage("candle_up_color_hex") private var upColorHex: String = "#ef5350"
    @AppStorage("candle_down_color_hex") private var downColorHex: String = "#1976d2"

    // MARK: - Init

    init() {
        self.state = SettingsState(
            upColor: Color(hex: UserDefaults.standard.string(forKey: "candle_up_color_hex") ?? "#ef5350"),
            downColor: Color(hex: UserDefaults.standard.string(forKey: "candle_down_color_hex") ?? "#1976d2")
        )
    }

    // MARK: - Action

    func action(_ intent: SettingsIntent) {
        switch intent {
        case .updateUpColor(let color):
            updateUpColor(color)
        case .updateDownColor(let color):
            updateDownColor(color)
        }
    }

    // MARK: - Private

    private func updateUpColor(_ color: Color) {
        state.upColor = color
        upColorHex = color.toHex()
    }

    private func updateDownColor(_ color: Color) {
        state.downColor = color
        downColorHex = color.toHex()
    }
}

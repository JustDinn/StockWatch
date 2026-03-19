//
//  SettingsStore.swift
//  StockWatch
//

import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: SettingsState

    @AppStorage("candle_body_up_color_hex") private var bodyUpColorHex: String = "#ef5350"
    @AppStorage("candle_body_down_color_hex") private var bodyDownColorHex: String = "#1976d2"
    @AppStorage("candle_border_up_color_hex") private var borderUpColorHex: String = "#ef5350"
    @AppStorage("candle_border_down_color_hex") private var borderDownColorHex: String = "#1976d2"
    @AppStorage("candle_wick_up_color_hex") private var wickUpColorHex: String = "#ef5350"
    @AppStorage("candle_wick_down_color_hex") private var wickDownColorHex: String = "#1976d2"

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.state = SettingsState(
            bodyUpColor: Color(hex: defaults.string(forKey: "candle_body_up_color_hex") ?? "#ef5350"),
            bodyDownColor: Color(hex: defaults.string(forKey: "candle_body_down_color_hex") ?? "#1976d2"),
            borderUpColor: Color(hex: defaults.string(forKey: "candle_border_up_color_hex") ?? "#ef5350"),
            borderDownColor: Color(hex: defaults.string(forKey: "candle_border_down_color_hex") ?? "#1976d2"),
            wickUpColor: Color(hex: defaults.string(forKey: "candle_wick_up_color_hex") ?? "#ef5350"),
            wickDownColor: Color(hex: defaults.string(forKey: "candle_wick_down_color_hex") ?? "#1976d2")
        )
    }

    // MARK: - Action

    func action(_ intent: SettingsIntent) {
        switch intent {
        case .updateBodyUpColor(let color):
            state.bodyUpColor = color
            bodyUpColorHex = color.toHex()
        case .updateBodyDownColor(let color):
            state.bodyDownColor = color
            bodyDownColorHex = color.toHex()
        case .updateBorderUpColor(let color):
            state.borderUpColor = color
            borderUpColorHex = color.toHex()
        case .updateBorderDownColor(let color):
            state.borderDownColor = color
            borderDownColorHex = color.toHex()
        case .updateWickUpColor(let color):
            state.wickUpColor = color
            wickUpColorHex = color.toHex()
        case .updateWickDownColor(let color):
            state.wickDownColor = color
            wickDownColorHex = color.toHex()
        }
    }
}

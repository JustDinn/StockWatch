//
//  CandleSettingsView.swift
//  StockWatch
//

import SwiftUI

struct CandleSettingsView: View {

    @ObservedObject var store: SettingsStore

    var body: some View {
        List {
            Section {
                candleRow(
                    label: "바디",
                    upColor: Binding(
                        get: { store.state.upColor },
                        set: { store.action(.updateUpColor($0)) }
                    ),
                    downColor: Binding(
                        get: { store.state.downColor },
                        set: { store.action(.updateDownColor($0)) }
                    )
                )
                candleRow(
                    label: "윅",
                    upColor: Binding(
                        get: { store.state.upColor },
                        set: { store.action(.updateUpColor($0)) }
                    ),
                    downColor: Binding(
                        get: { store.state.downColor },
                        set: { store.action(.updateDownColor($0)) }
                    )
                )
            }
        }
        .navigationTitle("캔들 설정")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func candleRow(
        label: String,
        upColor: Binding<Color>,
        downColor: Binding<Color>
    ) -> some View {
        HStack {
            Image(systemName: "checkmark.square.fill")
                .foregroundStyle(.primary)
            Text(label)
            Spacer()
            ColorPicker("", selection: upColor, supportsOpacity: false)
                .labelsHidden()
            ColorPicker("", selection: downColor, supportsOpacity: false)
                .labelsHidden()
        }
    }
}

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
                        get: { store.state.bodyUpColor },
                        set: { store.action(.updateBodyUpColor($0)) }
                    ),
                    downColor: Binding(
                        get: { store.state.bodyDownColor },
                        set: { store.action(.updateBodyDownColor($0)) }
                    )
                )
                candleRow(
                    label: "경계선",
                    upColor: Binding(
                        get: { store.state.borderUpColor },
                        set: { store.action(.updateBorderUpColor($0)) }
                    ),
                    downColor: Binding(
                        get: { store.state.borderDownColor },
                        set: { store.action(.updateBorderDownColor($0)) }
                    )
                )
                candleRow(
                    label: "윅",
                    upColor: Binding(
                        get: { store.state.wickUpColor },
                        set: { store.action(.updateWickUpColor($0)) }
                    ),
                    downColor: Binding(
                        get: { store.state.wickDownColor },
                        set: { store.action(.updateWickDownColor($0)) }
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

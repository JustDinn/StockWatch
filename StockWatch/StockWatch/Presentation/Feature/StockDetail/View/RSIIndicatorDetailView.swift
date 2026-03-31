//
//  RSIIndicatorDetailView.swift
//  StockWatch
//

import SwiftUI

struct RSIIndicatorDetailView: View {

    @StateObject private var store: RSIIndicatorStore
    @Environment(\.dismiss) private var dismiss

    init(
        initialState: RSIIndicatorState? = nil,
        onConfirm: @escaping (RSIConfiguration) -> Void
    ) {
        let state = initialState ?? RSIIndicatorState()
        _store = StateObject(wrappedValue: RSIIndicatorStore(
            state: state,
            onConfirm: onConfirm
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    lineSection
                    upperSection
                    middleSection
                    lowerSection
                    backgroundSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }

            confirmButton
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("초기화") {
                    store.action(.reset)
                }
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RSI")
                .font(.title2)
                .fontWeight(.bold)
            Text("현재 시장의 매수/매도가 과도한지를 측정해 %로 표시한 지표")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var lineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("기간")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                colorAndWidthControl
                RSIPeriodTextField(
                    period: store.state.line.period,
                    isEnabled: store.state.line.isEnabled,
                    onPeriodChange: { store.action(.updatePeriod($0)) }
                )
                Toggle("", isOn: Binding(
                    get: { store.state.line.isEnabled },
                    set: { _ in store.action(.toggleLineEnabled) }
                ))
                .labelsHidden()
                .tint(.blue)
            }
        }
    }

    private var colorAndWidthControl: some View {
        HStack(spacing: 6) {
            ColorPicker("", selection: Binding(
                get: { Color(hex: store.state.line.colorHex) ?? .purple },
                set: { store.action(.updateLineColor($0.toHex())) }
            ), supportsOpacity: false)
            .labelsHidden()
            .frame(width: 24, height: 24)

            Menu {
                ForEach([1, 2, 3], id: \.self) { width in
                    Button("\(width)px") { store.action(.updateLineWidth(width)) }
                }
            } label: {
                Text("\(store.state.line.lineWidth)px")
                    .font(.footnote)
                    .foregroundStyle(.primary)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .disabled(!store.state.line.isEnabled)
        .opacity(store.state.line.isEnabled ? 1 : 0.4)
    }

    private var upperSection: some View {
        levelSection(
            title: "상한선",
            value: store.state.upperLevel.value,
            isEnabled: store.state.upperLevel.isEnabled,
            onValueChange: { store.action(.updateUpperLevel($0)) },
            onToggle: { store.action(.toggleUpperLevel) }
        )
    }

    private var middleSection: some View {
        levelSection(
            title: "중간선",
            value: store.state.middleLevel.value,
            isEnabled: store.state.middleLevel.isEnabled,
            onValueChange: { store.action(.updateMiddleLevel($0)) },
            onToggle: { store.action(.toggleMiddleLevel) }
        )
    }

    private var lowerSection: some View {
        levelSection(
            title: "하한선",
            value: store.state.lowerLevel.value,
            isEnabled: store.state.lowerLevel.isEnabled,
            onValueChange: { store.action(.updateLowerLevel($0)) },
            onToggle: { store.action(.toggleLowerLevel) }
        )
    }

    private func levelSection(
        title: String,
        value: Int,
        isEnabled: Bool,
        onValueChange: @escaping (Int) -> Void,
        onToggle: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                RSILevelTextField(
                    value: value,
                    isEnabled: isEnabled,
                    onValueChange: onValueChange
                )
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(.blue)
            }
        }
    }

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("배경색")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ColorPicker("", selection: Binding(
                    get: { Color(hex: store.state.background.colorHex) ?? Color(.darkGray) },
                    set: { store.action(.updateBackgroundColor($0.toHex())) }
                ), supportsOpacity: false)
                .labelsHidden()
                .frame(width: 36, height: 36)
                .padding(.horizontal, 10)
                .frame(height: 44)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(!store.state.background.isEnabled)
                .opacity(store.state.background.isEnabled ? 1 : 0.4)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { store.state.background.isEnabled },
                    set: { _ in store.action(.toggleBackground) }
                ))
                .labelsHidden()
                .tint(.blue)
            }
        }
    }

    private var confirmButton: some View {
        Button {
            store.action(.confirm)
            dismiss()
        } label: {
            Text("확인")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - RSIPeriodTextField

private struct RSIPeriodTextField: View {

    let period: Int
    let isEnabled: Bool
    let onPeriodChange: (Int) -> Void

    @State private var periodText: String

    init(period: Int, isEnabled: Bool, onPeriodChange: @escaping (Int) -> Void) {
        self.period = period
        self.isEnabled = isEnabled
        self.onPeriodChange = onPeriodChange
        self._periodText = State(initialValue: "\(period)")
    }

    var body: some View {
        TextField("", text: $periodText)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.4)
            .onChange(of: periodText) { _, newValue in
                if let value = Int(newValue), value > 0 {
                    onPeriodChange(value)
                }
            }
            .onSubmit {
                if let value = Int(periodText), value > 0 {
                    onPeriodChange(value)
                } else {
                    periodText = "\(period)"
                }
            }
            .onChange(of: period) { _, newPeriod in
                periodText = "\(newPeriod)"
            }
    }
}

// MARK: - RSILevelTextField

private struct RSILevelTextField: View {

    let value: Int
    let isEnabled: Bool
    let onValueChange: (Int) -> Void

    @State private var valueText: String

    init(value: Int, isEnabled: Bool, onValueChange: @escaping (Int) -> Void) {
        self.value = value
        self.isEnabled = isEnabled
        self.onValueChange = onValueChange
        self._valueText = State(initialValue: "\(value)")
    }

    var body: some View {
        TextField("", text: $valueText)
            .keyboardType(.numberPad)
            .font(.subheadline)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.4)
            .onChange(of: valueText) { _, newValue in
                if let v = Int(newValue), v >= 0, v <= 100 {
                    onValueChange(v)
                }
            }
            .onSubmit {
                if let v = Int(valueText), v >= 0, v <= 100 {
                    onValueChange(v)
                } else {
                    valueText = "\(value)"
                }
            }
            .onChange(of: value) { _, newValue in
                valueText = "\(newValue)"
            }
    }
}

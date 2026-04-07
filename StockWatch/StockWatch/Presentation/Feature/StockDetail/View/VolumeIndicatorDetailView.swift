//
//  VolumeIndicatorDetailView.swift
//  StockWatch
//

import SwiftUI

struct VolumeIndicatorDetailView: View {

    @StateObject private var store: VolumeIndicatorStore
    @Environment(\.dismiss) private var dismiss

    init(
        initialState: VolumeIndicatorState? = nil,
        onConfirm: @escaping (VolumeMAConfiguration) -> Void
    ) {
        let state = initialState ?? VolumeIndicatorState()
        _store = StateObject(wrappedValue: VolumeIndicatorStore(
            state: state,
            onConfirm: onConfirm
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    maSection
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
            Text("거래량")
                .font(.title2)
                .fontWeight(.bold)
            Text("시장에서 주식이 거래된 양을 막대그래프로 표시한 지표")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var maSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("거래량 이동평균선")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                colorAndWidthControl
                periodTextField
                Toggle("", isOn: Binding(
                    get: { store.state.line.isEnabled },
                    set: { _ in store.action(.toggleEnabled) }
                ))
                .labelsHidden()
                .tint(.blue)
            }
        }
    }

    private var colorAndWidthControl: some View {
        HStack(spacing: 6) {
            ColorPicker("", selection: Binding(
                get: { Color(hex: store.state.line.colorHex) ?? .green },
                set: { store.action(.updateColor($0.toHex())) }
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

    private var periodTextField: some View {
        PeriodTextField(
            period: store.state.line.period,
            isEnabled: store.state.line.isEnabled,
            onPeriodChange: { store.action(.updatePeriod($0)) }
        )
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

// MARK: - PeriodTextField

private struct PeriodTextField: View {

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

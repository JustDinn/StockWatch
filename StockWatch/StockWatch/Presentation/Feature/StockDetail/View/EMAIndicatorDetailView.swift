//
//  EMAIndicatorDetailView.swift
//  StockWatch
//

import SwiftUI

struct EMAIndicatorDetailView: View {

    @StateObject private var store: EMAIndicatorStore
    @Environment(\.dismiss) private var dismiss

    init(
        initialState: EMAIndicatorState? = nil,
        onConfirm: @escaping (EMAIndicatorConfiguration) -> Void
    ) {
        let state = initialState ?? EMAIndicatorState()
        _store = StateObject(wrappedValue: EMAIndicatorStore(
            state: state,
            onConfirm: onConfirm
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    lineList
                    if store.state.lines.count < EMAIndicatorState.maxLineCount {
                        addLineButton
                    }
                    footerNote
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
            Text("지수이동평균선")
                .font(.title2)
                .fontWeight(.bold)
            Text("주가의 평균 가격 중 최근 가격에 더 높은 가중치를 부여한 이동평균선")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var lineList: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(store.state.lines.enumerated()), id: \.element.id) { index, line in
                lineSection(index: index, line: line)
            }
        }
    }

    private func lineSection(index: Int, line: EMALine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("기간 \(index + 1)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            EMALineRowView(
                line: line,
                isFirst: index == 0,
                onDelete: { store.action(.removeLine(id: line.id)) },
                onPeriodChange: { store.action(.updatePeriod(id: line.id, period: $0)) },
                onColorChange: { store.action(.updateColor(id: line.id, colorHex: $0)) },
                onLineWidthChange: { store.action(.updateLineWidth(id: line.id, lineWidth: $0)) },
                onPriceSourceChange: { store.action(.updatePriceSource(id: line.id, priceSource: $0)) }
            )
        }
    }

    private var addLineButton: some View {
        Button {
            store.action(.addLine)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                }
                Text("기간 추가")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var footerNote: some View {
        Text("입력한 기간 값보다 종목이 상장된 기간이 짧으면 이동평균선이 보이지 않아요.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
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

// MARK: - EMALineRowView

private struct EMALineRowView: View {

    let line: EMALine
    let isFirst: Bool
    let onDelete: () -> Void
    let onPeriodChange: (Int) -> Void
    let onColorChange: (String) -> Void
    let onLineWidthChange: (Int) -> Void
    let onPriceSourceChange: (EMAPriceSource) -> Void

    @State private var periodText: String
    @State private var selectedColor: Color

    init(
        line: EMALine,
        isFirst: Bool,
        onDelete: @escaping () -> Void,
        onPeriodChange: @escaping (Int) -> Void,
        onColorChange: @escaping (String) -> Void,
        onLineWidthChange: @escaping (Int) -> Void,
        onPriceSourceChange: @escaping (EMAPriceSource) -> Void
    ) {
        self.line = line
        self.isFirst = isFirst
        self.onDelete = onDelete
        self.onPeriodChange = onPeriodChange
        self.onColorChange = onColorChange
        self.onLineWidthChange = onLineWidthChange
        self.onPriceSourceChange = onPriceSourceChange
        self._periodText = State(initialValue: "\(line.period)")
        self._selectedColor = State(initialValue: Color(hex: line.colorHex) ?? .yellow)
    }

    var body: some View {
        HStack(spacing: 8) {
            colorSwatch
            sourcePill
            periodTextField
            deleteButton
                .opacity(isFirst ? 0 : 1)
                .allowsHitTesting(!isFirst)
        }
    }

    private var colorSwatch: some View {
        HStack(spacing: 6) {
            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 24, height: 24)
                .onChange(of: selectedColor) { _, newColor in
                    onColorChange(newColor.toHex())
                }
            Menu {
                ForEach([1, 2, 3], id: \.self) { width in
                    Button("\(width)px") { onLineWidthChange(width) }
                }
            } label: {
                Text("\(line.lineWidth)px")
                    .font(.footnote)
                    .foregroundStyle(.primary)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var sourcePill: some View {
        Menu {
            ForEach(EMAPriceSource.allCases, id: \.self) { source in
                Button(source.displayName) { onPriceSourceChange(source) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(line.priceSource.displayName)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundStyle(.primary)
            .frame(height: 44)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var periodTextField: some View {
        TextField("", text: $periodText)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onChange(of: periodText) { _, newValue in
                if let value = Int(newValue), value > 0 {
                    onPeriodChange(value)
                }
            }
            .onSubmit {
                if let value = Int(periodText), value > 0 {
                    onPeriodChange(value)
                } else {
                    periodText = "\(line.period)"
                }
            }
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

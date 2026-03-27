//
//  MAIndicatorDetailView.swift
//  StockWatch
//

import SwiftUI

struct MAIndicatorDetailView: View {

    @StateObject private var store: MAIndicatorStore
    @Environment(\.dismiss) private var dismiss

    init(
        initialState: MAIndicatorState? = nil,
        onConfirm: @escaping (MAIndicatorConfiguration) -> Void
    ) {
        let state = initialState ?? MAIndicatorState()
        _store = StateObject(wrappedValue: MAIndicatorStore(
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
                    if store.state.lines.count < MAIndicatorState.maxLineCount {
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
            Text("이동평균선")
                .font(.title2)
                .fontWeight(.bold)
            Text("지난 n일 동안의 주가 평균값을 이은 선")
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

    private func lineSection(index: Int, line: MALine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("기간 \(index + 1)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            LineRowView(
                line: line,
                isFirst: index == 0,
                onDelete: { store.action(.removeLine(id: line.id)) },
                onPeriodChange: { newValue in
                    store.action(.updatePeriod(id: line.id, period: newValue))
                }
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
        Text("① 입력한 기간 값보다 종목이 상장된 기간이 짧으면 이동평균선이 보이지 않아요.")
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

// MARK: - LineRowView

private struct LineRowView: View {

    let line: MALine
    let isFirst: Bool
    let onDelete: () -> Void
    let onPeriodChange: (Int) -> Void

    @State private var periodText: String

    init(line: MALine, isFirst: Bool, onDelete: @escaping () -> Void, onPeriodChange: @escaping (Int) -> Void) {
        self.line = line
        self.isFirst = isFirst
        self.onDelete = onDelete
        self.onPeriodChange = onPeriodChange
        self._periodText = State(initialValue: "\(line.period)")
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
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: line.colorHex) ?? .yellow)
                .frame(width: 24, height: 24)
            Text("\(line.lineWidth)px")
                .font(.footnote)
                .foregroundStyle(.primary)
        }
        .frame(height: 44)
        .padding(.horizontal, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var sourcePill: some View {
        HStack(spacing: 4) {
            Text("종가")
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


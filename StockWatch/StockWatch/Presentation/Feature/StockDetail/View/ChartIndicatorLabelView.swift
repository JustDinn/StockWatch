//
//  ChartIndicatorLabelView.swift
//  StockWatch
//

import SwiftUI

/// 차트 좌상단에 표시되는 기술적 지표 라벨 오버레이
struct ChartIndicatorLabelView: View {

    let labels: [UpperIndicatorLabel]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        if labels.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 2) {
                if isExpanded {
                    ForEach(labels) { label in
                        indicatorRow(label)
                    }
                } else {
                    HStack(spacing: 4) {
                        if let first = labels.first {
                            indicatorRow(first)
                        }
                        if labels.count > 1 {
                            Button(action: onToggle) {
                                HStack(spacing: 2) {
                                    Text("외 \(labels.count - 1)개")
                                        .font(.pretendardCaption)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if isExpanded && labels.count > 1 {
                    Button(action: onToggle) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
    }

    @ViewBuilder
    private func indicatorRow(_ label: UpperIndicatorLabel) -> some View {
        HStack(spacing: 4) {
            Text(label.name)
                .font(.pretendardCaption)
                .foregroundStyle(.primary)

            ForEach(label.values.indices, id: \.self) { index in
                Text("\(label.values[index].period)")
                    .font(.pretendardCaption)
                    .foregroundStyle(Color(hex: label.values[index].colorHex))
            }
        }
    }
}

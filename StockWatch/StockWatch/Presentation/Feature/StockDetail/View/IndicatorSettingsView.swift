//
//  IndicatorSettingsView.swift
//  StockWatch
//

import SwiftUI

struct IndicatorSettingsView: View {
    enum Tab: String, CaseIterable {
        case upper = "상단지표"
        case lower = "하단지표"
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .upper
    @State private var isMAEnabled: Bool = false
    @State private var isVolumeEnabled: Bool = false
    @State private var isRSIEnabled: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            indicatorList
            applyButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("초기화 하기") {
                    isMAEnabled = false
                    isVolumeEnabled = false
                    isRSIEnabled = false
                }
                .foregroundStyle(.blue)
            }
        }
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabBarItem(tab)
                }
            }
            .padding(.top, 8)
            Divider()
        }
    }

    private func tabBarItem(_ tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 8) {
                Text(tab.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(isSelected ? Color.primary : Color.clear)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var indicatorList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                switch selectedTab {
                case .upper:
                    IndicatorRow(
                        title: "이동평균선",
                        description: "지난 n일 동안의 주가 평균값을 이은 선",
                        isEnabled: $isMAEnabled
                    ) {
                        // 추후 상세 설정 화면으로 교체
                    } detailDestination: {
                        Text("이동평균선 상세 설정")
                            .navigationTitle("이동평균선")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                case .lower:
                    IndicatorRow(
                        title: "거래량",
                        description: "거래량을 가격대별로 비교할 수 있는 막대그래프",
                        isEnabled: $isVolumeEnabled
                    ) {
                        // 추후 상세 설정 화면으로 교체
                    } detailDestination: {
                        Text("거래량 상세 설정")
                            .navigationTitle("거래량")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    IndicatorRow(
                        title: "RSI",
                        description: "주가의 상승/하락 강도를 나타내는 0~100 사이의 지표",
                        isEnabled: $isRSIEnabled
                    ) {
                        // 추후 상세 설정 화면으로 교체
                    } detailDestination: {
                        Text("RSI 상세 설정")
                            .navigationTitle("RSI")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
        }
    }

    private var applyButton: some View {
        Button {
            dismiss()
        } label: {
            Text("적용하기")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct IndicatorRow<Destination: View>: View {
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let onDetailTap: () -> Void
    @ViewBuilder let detailDestination: () -> Destination

    @State private var isShowingDetail: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            if isEnabled {
                Button {
                    onDetailTap()
                    isShowingDetail = true
                } label: {
                    HStack {
                        Text("상세 설정하기")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.blue)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .navigationDestination(isPresented: $isShowingDetail) {
                    detailDestination()
                }
            }
        }
    }
}

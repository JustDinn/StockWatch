//
//  IndicatorSettingsView.swift
//  StockWatch
//

import SwiftUI

struct IndicatorSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = IndicatorSettingsStore()

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
                    store.action(.resetAll)
                }
                .foregroundStyle(.blue)
            }
        }
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(IndicatorTab.allCases, id: \.self) { tab in
                    tabBarItem(tab)
                }
            }
            .padding(.top, 8)
            Divider()
        }
    }

    private func tabBarItem(_ tab: IndicatorTab) -> some View {
        let isSelected = store.state.selectedTab == tab
        return Button {
            store.action(.selectTab(tab))
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

    private var indicatorList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(TechnicalIndicator.indicators(for: store.state.selectedTab)) { indicator in
                    IndicatorRow(
                        title: indicator.title,
                        description: indicator.description,
                        isEnabled: store.enabledBinding(for: indicator),
                        onDetailTap: { }
                    ) {
                        IndicatorDetailDestination(
                            indicator: indicator,
                            onMAConfirm: { config in
                                store.action(.stageMAConfig(config))
                            }
                        )
                    }
                }
            }
        }
    }

    private var applyButton: some View {
        Button {
            store.action(.apply)
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

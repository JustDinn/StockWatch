//
//  WatchListView.swift
//  StockWatch
//

import SwiftUI
import SwiftData
import Kingfisher

/// WatchList 화면 진입점 — modelContext를 Environment에서 받아 ContentView에 전달한다.
struct WatchListView: View {

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        WatchListContentView(modelContext: modelContext)
    }
}

// MARK: - Content View

private struct WatchListContentView: View {

    @StateObject private var store: WatchListStore
    @State private var isShowingAddGroupAlert = false
    @State private var isShowingGroupManageModal = false
    @State private var newGroupName = ""

    init(modelContext: ModelContext) {
        let repository = FavoriteRepository(modelContext: modelContext)
        let groupRepository = WatchListGroupRepository(modelContext: modelContext)
        _store = StateObject(wrappedValue: WatchListStore(
            fetchFavoritesUseCase: FetchFavoritesUseCase(repository: repository),
            toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository),
            manageGroupUseCase: ManageWatchListGroupUseCase(repository: groupRepository),
            fetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCase(repository: repository)
        ))
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    if store.state.dbGroups.isEmpty {
                        WatchListGroupOnboardingView(onCreateGroup: { isShowingAddGroupAlert = true })
                    } else {
                        WatchListGroupTabBar(
                            groups: store.state.groups,
                            selectedIndex: store.state.selectedGroupIndex,
                            onSelect: { store.action(.selectGroup(index: $0)) },
                            onAddGroup: { isShowingGroupManageModal = true }
                        )
                        Group {
                            if store.state.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if store.state.favorites.isEmpty {
                                emptyView
                            } else {
                                stockList
                            }
                        }
                    }
                }
                .navigationTitle("워치리스트")
                .navigationDestination(item: store.selectedTickerBinding) { ticker in
                    StockDetailView(ticker: ticker)
                }
                .onAppear {
                    store.action(.loadGroups)
                }
            }

            if isShowingGroupManageModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { isShowingGroupManageModal = false }

                VStack {
                    Spacer()
                    WatchListGroupManageModalView(
                        groups: store.state.dbGroups,
                        onAddGroup: {
                            isShowingGroupManageModal = false
                            isShowingAddGroupAlert = true
                        },
                        onDeleteGroup: { id in
                            store.action(.deleteGroup(id: id))
                        }
                    )
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isShowingGroupManageModal)
        .alert("새 그룹 추가", isPresented: $isShowingAddGroupAlert) {
            TextField("그룹 이름", text: $newGroupName)
            Button("추가") {
                let name = newGroupName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    store.action(.createGroup(name))
                }
                newGroupName = ""
            }
            Button("취소", role: .cancel) {
                newGroupName = ""
            }
        } message: {
            Text("새로운 워치리스트 그룹 이름을 입력하세요.")
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("관심 종목이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("종목 상세 화면에서\n하트를 눌러 관심 종목을 추가해보세요")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button(action: { }) {
                Label("추가하기", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stockList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.state.favorites, id: \.ticker) { item in
                    WatchListStockRow(
                        item: item,
                        mockData: store.state.mockPriceData[item.ticker],
                        displayName: displayName(for: item),
                        onTap: { store.action(.selectTicker(item.ticker)) }
                    )
                }
                WatchListAddStockRow(onTap: { })
            }
        }
    }

    /// 표시 이름: 한국어명 → 영어명 → 티커 fallback
    private func displayName(for item: FavoriteItem) -> String {
        KoreanStockDictionary.shared.entries
            .first(where: { $0.ticker == item.ticker })?.nameKo
            ?? (item.companyName.isEmpty ? item.ticker : item.companyName)
    }
}

// MARK: - Group Onboarding View

private struct WatchListGroupOnboardingView: View {
    let onCreateGroup: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("워치리스트 그룹이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("그룹을 만들어 워치리스트를 구성해보세요")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button("그룹 만들기", action: onCreateGroup)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Group Tab Bar

private struct WatchListGroupTabBar: View {
    let groups: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    let onAddGroup: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(groups.indices, id: \.self) { idx in
                    groupTab(groups[idx], isSelected: selectedIndex == idx) {
                        onSelect(idx)
                    }
                }
                Button("그룹관리", action: onAddGroup)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private func groupTab(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                    }
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Group Manage Modal

private struct WatchListGroupManageModalView: View {
    let groups: [WatchListGroup]
    let onAddGroup: () -> Void
    let onDeleteGroup: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onAddGroup) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    Text("새 그룹 추가")
                        .foregroundStyle(.blue)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)
            }
            .buttonStyle(.plain)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(groups, id: \.id) { group in
                        groupRow(group)
                    }
                }
            }
        }
        .frame(maxHeight: 420)
    }

    private func groupRow(_ group: WatchListGroup) -> some View {
        HStack(spacing: 12) {
            Button {
                onDeleteGroup(group.id)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            Text(group.name)
                .font(.subheadline)
            Image(systemName: "pencil")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundStyle(Color(.systemGray3))
                .font(.subheadline)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Stock Row

private struct WatchListStockRow: View {
    let item: FavoriteItem
    let mockData: WatchListRowMockData?
    let displayName: String
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            logoView
            nameColumn
            Spacer()
            priceColumn
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var logoView: some View {
        let size: CGFloat = 44
        if !item.logoURL.isEmpty, let url = URL(string: item.logoURL) {
            KFImage(url)
                .placeholder { initialsCircle(size: size) }
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            initialsCircle(size: size)
        }
    }

    private func initialsCircle(size: CGFloat) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Text(String(item.ticker.prefix(2)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            )
    }

    private var nameColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(displayName)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Text(item.ticker)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var priceColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let data = mockData {
                let positive = data.priceChangePercent >= 0
                Text(String(format: "%@%.1f%%", positive ? "+" : "", data.priceChangePercent))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(positive ? Color(hex: "#ef5350") : Color(hex: "#1976d2"))
                Text(formattedPrice(data.currentPrice, currency: data.currency))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedPrice(_ price: Double, currency: String) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = currency.isEmpty ? "USD" : currency
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}

// MARK: - Add Stock Row

private struct WatchListAddStockRow: View {
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "plus")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                )
            Text("종목 추가하기")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    WatchListView()
}

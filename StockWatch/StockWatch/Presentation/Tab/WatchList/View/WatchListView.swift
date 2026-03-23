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
    @State private var isShowingRenameGroupAlert = false
    @State private var isShowingGroupManageModal = false
    @State private var isShowingAddStock = false
    @State private var newGroupName = ""
    @State private var renameGroupName = ""
    @State private var isEditingGroups = false

    init(modelContext: ModelContext) {
        let repository = FavoriteRepository(modelContext: modelContext)
        let groupRepository = WatchListGroupRepository(modelContext: modelContext)
        _store = StateObject(wrappedValue: WatchListStore(
            fetchFavoritesUseCase: FetchFavoritesUseCase(repository: repository),
            toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository),
            manageGroupUseCase: ManageWatchListGroupUseCase(repository: groupRepository),
            fetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCase(repository: repository),
            addFavoriteToGroupUseCase: AddFavoriteToGroupUseCase(repository: repository),
            fetchStockQuoteUseCase: FetchStockQuoteUseCase(repository: StockQuoteRepository())
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
                            groups: store.state.dbGroups,
                            selectedIndex: store.state.selectedGroupIndex,
                            draggedGroupId: store.state.draggedGroupId,
                            dragTargetIndex: store.state.dragTargetIndex,
                            isEditingGroups: $isEditingGroups,
                            onSelect: { store.action(.selectGroup(index: $0)) },
                            onAddGroup: { isShowingGroupManageModal = true },
                            onBeginDrag: { store.action(.beginGroupDrag(groupId: $0)) },
                            onUpdateDragTarget: { store.action(.updateGroupDragTarget(index: $0)) },
                            onEndDrag: { store.action(.reorderGroups(orderedIds: $0)) }
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isEditingGroups {
                                isEditingGroups = false
                            }
                        }
                    }
                }
                .navigationTitle("워치리스트")
                .navigationDestination(item: store.selectedTickerBinding) { ticker in
                    StockDetailView(ticker: ticker)
                }
                .navigationDestination(isPresented: $isShowingAddStock) {
                    AddStockToGroupView(groupName: currentGroupName) { selectedStocks, logoURLs in
                        store.action(.addStocksToGroup(selectedStocks, logoURLs))
                        isShowingAddStock = false
                    }
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
                        },
                        onRenameGroup: { group in
                            isShowingGroupManageModal = false
                            renameGroupName = group.name
                            store.action(.setGroupToRename(group))
                            isShowingRenameGroupAlert = true
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
        .alert("그룹 수정", isPresented: $isShowingRenameGroupAlert) {
            TextField("그룹 이름", text: $renameGroupName)
            Button("수정") {
                let name = renameGroupName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty, let group = store.state.groupToRename {
                    store.action(.renameGroup(id: group.id, name: name))
                }
                renameGroupName = ""
            }
            Button("취소", role: .cancel) {
                renameGroupName = ""
            }
        } message: {
            Text("수정할 그룹 이름을 입력하세요.")
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

            Button(action: { isShowingAddStock = true }) {
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
                        quoteData: store.state.priceData[item.ticker],
                        displayName: displayName(for: item),
                        onTap: { store.action(.selectTicker(item.ticker)) }
                    )
                }
                WatchListAddStockRow(onTap: { isShowingAddStock = true })
            }
        }
    }

    private var currentGroupName: String {
        let groups = store.state.groups
        let idx = store.state.selectedGroupIndex
        guard idx < groups.count else { return "그룹" }
        return groups[idx]
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

private struct TabFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct WatchListGroupTabBar: View {
    let groups: [WatchListGroup]
    let selectedIndex: Int
    let draggedGroupId: UUID?
    let dragTargetIndex: Int?
    @Binding var isEditingGroups: Bool
    let onSelect: (Int) -> Void
    let onAddGroup: () -> Void
    let onBeginDrag: (UUID) -> Void
    let onUpdateDragTarget: (Int) -> Void
    let onEndDrag: ([UUID]) -> Void

    @State private var tabFrames: [UUID: CGRect] = [:]
    @State private var dragOffsets: [UUID: CGFloat] = [:]
    @State private var isWiggling: Bool = false
    @State private var longPressedGroupId: UUID? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(displayGroups, id: \.id) { group in
                    let idx = displayGroups.firstIndex(where: { $0.id == group.id }) ?? 0
                    groupTab(group, idx: idx)
                }
                Button("그룹관리", action: onAddGroup)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .scrollDisabled(draggedGroupId != nil)
        .coordinateSpace(name: "tabBarScroll")
        .onPreferenceChange(TabFramePreferenceKey.self) { frames in
            tabFrames = frames
        }
        .onChange(of: longPressedGroupId) {
            print("<< onChange longPressedGroupId: \(String(describing: longPressedGroupId)), isWiggling=\(isWiggling), isEditingGroups=\(isEditingGroups)")
            if longPressedGroupId != nil {
                isWiggling = true
                print("<< → isWiggling=true")
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    isWiggling = false
                }
                isEditingGroups = false
                print("<< → isWiggling=false (withAnimation easeOut), isEditingGroups=false")
            }
        }
        .onChange(of: draggedGroupId) {
            print("<< onChange draggedGroupId: \(String(describing: draggedGroupId))")
            if draggedGroupId == nil {
                dragOffsets.removeAll()
                withAnimation(.easeOut(duration: 0.15)) {
                    isWiggling = false
                }
                isEditingGroups = false
                longPressedGroupId = nil
                print("<< → dragEnd cleanup: isWiggling=false, isEditingGroups=false, longPressedGroupId=nil, dragOffsets cleared")
            }
        }
        .onChange(of: isEditingGroups) {
            print("<< onChange isEditingGroups: \(isEditingGroups)")
            if !isEditingGroups {
                longPressedGroupId = nil
                print("<< → longPressedGroupId=nil (isEditingGroups became false)")
            }
        }
    }

    // 드래그 중 삽입 위치 미리보기를 반영한 순서
    private var displayGroups: [WatchListGroup] {
        guard let dragId = draggedGroupId,
              let targetIdx = dragTargetIndex,
              let fromIdx = groups.firstIndex(where: { $0.id == dragId }) else {
            return groups
        }
        var reordered = groups
        let item = reordered.remove(at: fromIdx)
        let clampedTarget = min(max(targetIdx, 0), reordered.count)
        reordered.insert(item, at: clampedTarget)
        return reordered
    }

    @ViewBuilder
    private func groupTab(_ group: WatchListGroup, idx: Int) -> some View {
        let isDragged = group.id == draggedGroupId || group.id == longPressedGroupId
        let isSelected = groups.firstIndex(where: { $0.id == group.id }) == selectedIndex
        let wiggleCondition = !isDragged && longPressedGroupId != nil && isWiggling
        let _ = print("<< groupTab[\(group.name)] isDragged=\(isDragged), longPressedGroupId=\(String(describing: longPressedGroupId)), isWiggling=\(isWiggling), wiggleCondition=\(wiggleCondition)")

        Text(group.name)
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background {
                if isSelected && !isDragged {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                }
                if isDragged {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                }
            }
            .scaleEffect(isDragged ? 1.15 : 1.0)
            .shadow(color: isDragged ? .black.opacity(0.25) : .clear, radius: 10, x: 0, y: 5)
            .zIndex(isDragged ? 1 : 0)
            .rotationEffect(.degrees(wiggleCondition ? 2 : 0))
            .offset(x: dragOffsets[group.id] ?? 0)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: TabFramePreferenceKey.self,
                        value: [group.id: geo.frame(in: .named("tabBarScroll"))]
                    )
                }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragged)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragTargetIndex)
            .animation(
                wiggleCondition
                    ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                    : .easeOut(duration: 0.15),
                value: isWiggling
            )
            .onTapGesture {
                guard longPressedGroupId == nil && draggedGroupId == nil else { return }
                if let originalIndex = groups.firstIndex(where: { $0.id == group.id }) {
                    onSelect(originalIndex)
                }
            }
            .gesture(combinedGesture(for: group))
            .simultaneousGesture(endDragGesture(for: group))
    }

    private func combinedGesture(for group: WatchListGroup) -> some Gesture {
        let longPress = LongPressGesture(minimumDuration: 0.4)
        let drag = DragGesture(minimumDistance: 0, coordinateSpace: .named("tabBarScroll"))

        return longPress
            .sequenced(before: drag)
            .onChanged { value in
                switch value {
                case .first(true):
                    print("<< longPress recognized for: \(group.name)")
                    if longPressedGroupId != group.id {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        longPressedGroupId = group.id
                    }
                case .second(true, let dragValue?):
                    print("<< drag onChange for: \(group.name)")
                    if draggedGroupId != group.id {
                        onBeginDrag(group.id)
                    }
                    dragOffsets[group.id] = dragValue.translation.width
                    let targetIdx = computeTargetIndex(
                        draggedId: group.id,
                        translation: dragValue.translation.width,
                        location: dragValue.location.x
                    )
                    onUpdateDragTarget(targetIdx)
                default:
                    break
                }
            }
            .onEnded { value in
                // endDragGesture가 드래그 종료를 처리하므로 여기서는 백업으로만 동작
                print("<< sequenced onEnded[\(group.name)] (backup)")
                if case .second(true, _) = value, draggedGroupId != nil {
                    let orderedIds = displayGroups.map(\.id)
                    stopWiggle()
                    onEndDrag(orderedIds)
                }
            }
    }

    /// sequenced gesture의 onEnded가 신뢰할 수 없으므로,
    /// 독립적인 DragGesture로 손가락 올라감을 감지해 정리한다.
    private func endDragGesture(for group: WatchListGroup) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("tabBarScroll"))
            .onEnded { _ in
                guard draggedGroupId != nil else { return }
                print("<< endDragGesture onEnded[\(group.name)]")
                let orderedIds = displayGroups.map(\.id)
                stopWiggle()
                onEndDrag(orderedIds)
            }
    }

    private func stopWiggle() {
        dragOffsets.removeAll()
        withAnimation(.easeOut(duration: 0.15)) {
            isWiggling = false
        }
        isEditingGroups = false
        longPressedGroupId = nil
    }

    private func computeTargetIndex(draggedId: UUID, translation: CGFloat, location: CGFloat) -> Int {
        guard let draggedFrame = tabFrames[draggedId] else {
            return groups.firstIndex(where: { $0.id == draggedId }) ?? 0
        }
        let draggedCenter = draggedFrame.midX + translation

        var bestIdx = 0
        var bestDist = CGFloat.infinity
        for (idx, group) in groups.enumerated() {
            guard group.id != draggedId, let frame = tabFrames[group.id] else { continue }
            let dist = abs(frame.midX - draggedCenter)
            if dist < bestDist {
                bestDist = dist
                // 드래그 방향에 따라 삽입 위치 결정
                let fromIdx = groups.firstIndex(where: { $0.id == draggedId }) ?? 0
                bestIdx = (draggedCenter > frame.midX) ? idx : max(0, idx - 1)
                if draggedCenter > frame.midX && idx > fromIdx {
                    bestIdx = idx
                } else if draggedCenter < frame.midX && idx < fromIdx {
                    bestIdx = idx
                }
            }
        }
        return bestIdx
    }
}

// MARK: - Group Manage Modal

private struct WatchListGroupManageModalView: View {
    let groups: [WatchListGroup]
    let onAddGroup: () -> Void
    let onDeleteGroup: (UUID) -> Void
    let onRenameGroup: (WatchListGroup) -> Void

    @State private var groupToDelete: WatchListGroup? = nil

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
        .alert(
            "\(groupToDelete?.name ?? "") 그룹을 삭제할까요?",
            isPresented: Binding(
                get: { groupToDelete != nil },
                set: { if !$0 { groupToDelete = nil } }
            )
        ) {
            Button("취소", role: .cancel) {
                groupToDelete = nil
            }
            Button("삭제하기", role: .destructive) {
                if let group = groupToDelete {
                    onDeleteGroup(group.id)
                }
                groupToDelete = nil
            }
        } message: {
            Text("그룹 내 종목도 함께 삭제돼요.")
        }
    }

    private func groupRow(_ group: WatchListGroup) -> some View {
        HStack(spacing: 12) {
            Button {
                groupToDelete = group
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            Text(group.name)
                .font(.subheadline)
            Button { onRenameGroup(group) } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
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
    let quoteData: StockQuote?
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
            if let data = quoteData {
                let positive = data.priceChangePercent >= 0
                Text(String(format: "%@%.2f%%", positive ? "+" : "", data.priceChangePercent))
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
        fmt.maximumFractionDigits = 2
        fmt.roundingMode = .halfUp
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

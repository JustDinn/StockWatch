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
    @State private var isShowingGroupManageModal = false
    @State private var isShowingAddStock = false
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
            fetchStockQuoteUseCase: FetchStockQuoteUseCase(repository: StockQuoteRepository()),
            fetchGroupIdsForTickerUseCase: FetchGroupIdsForTickerUseCase(repository: repository),
            updateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCase(repository: repository)
        ))
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    if store.state.dbGroups.isEmpty {
                        WatchListGroupOnboardingView(onCreateGroup: { store.action(.showAddGroupModal) })
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
                            onEndDrag: { store.action(.reorderGroups(orderedIds: $0)) },
                            onCancelDrag: { store.action(.endGroupDrag) }
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
                            store.action(.showAddGroupModal)
                        },
                        onDeleteGroup: { id in
                            store.action(.deleteGroup(id: id))
                        },
                        onRenameGroup: { group in
                            isShowingGroupManageModal = false
                            store.action(.showRenameGroupModal(group))
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

            if store.state.isShowingAddGroupModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { store.action(.hideAddGroupModal) }

                VStack {
                    Spacer()
                    GroupNameInputModalView(
                        title: "새 그룹 추가",
                        placeholder: "그룹 이름",
                        confirmLabel: "추가",
                        name: store.state.addGroupName,
                        errorMessage: store.state.addGroupNameError,
                        onNameChange: { store.action(.updateAddGroupName($0)) },
                        onConfirm: { store.action(.createGroup) },
                        onCancel: { store.action(.hideAddGroupModal) }
                    )
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
            }

            if store.state.isShowingRenameGroupModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { store.action(.hideRenameGroupModal) }

                VStack {
                    Spacer()
                    GroupNameInputModalView(
                        title: "그룹 수정",
                        placeholder: "그룹 이름",
                        confirmLabel: "수정",
                        name: store.state.renameGroupName,
                        errorMessage: store.state.renameGroupNameError,
                        onNameChange: { store.action(.updateRenameGroupName($0)) },
                        onConfirm: { store.action(.renameGroup) },
                        onCancel: { store.action(.hideRenameGroupModal) }
                    )
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
            }

            if store.state.isShowingToast, let message = store.state.toastMessage {
                VStack {
                    Spacer()
                    ToastView(
                        icon: "heart.slash",
                        message: message,
                        actionLabel: "되돌리기",
                        onAction: { store.action(.undoRemoveFavorite) }
                    )
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isShowingGroupManageModal)
        .animation(.easeInOut(duration: 0.35), value: store.state.isShowingAddGroupModal)
        .animation(.easeInOut(duration: 0.35), value: store.state.isShowingRenameGroupModal)
        .animation(.easeInOut(duration: 0.3), value: store.state.isShowingToast)
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
                        onTap: { store.action(.selectTicker(item.ticker)) },
                        onRemove: { store.action(.removeFavoriteWithUndo(ticker: item.ticker)) }
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
    let onCancelDrag: () -> Void

    @State private var tabFrames: [UUID: CGRect] = [:]
    @State private var dragOffsets: [UUID: CGFloat] = [:]
    @State private var longPressedGroupId: UUID? = nil
    @State private var isDragging = false
    @State private var lastHapticTargetIndex: Int? = nil

    private var isInEditMode: Bool { longPressedGroupId != nil }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(displayGroups, id: \.id) { group in
                        let idx = displayGroups.firstIndex(where: { $0.id == group.id }) ?? 0
                        groupTab(group, idx: idx)
                            .id(group.id)
                    }
                    Button("그룹관리", action: onAddGroup)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .scrollDisabled(isInEditMode || draggedGroupId != nil)
            .coordinateSpace(name: "tabBarScroll")
            .onPreferenceChange(TabFramePreferenceKey.self) { frames in
                tabFrames = frames
            }
            .onChange(of: groups) { oldGroups, newGroups in
                let oldIds = Set(oldGroups.map(\.id))
                let newIds = Set(newGroups.map(\.id))
                guard oldIds != newIds else { return }
                guard selectedIndex < newGroups.count else { return }
                let targetId = newGroups[selectedIndex].id
                withAnimation {
                    proxy.scrollTo(targetId, anchor: .center)
                }
            }
            .onChange(of: selectedIndex) { _, newIndex in
                guard newIndex < groups.count else { return }
                let targetId = groups[newIndex].id
                withAnimation {
                    proxy.scrollTo(targetId, anchor: .center)
                }
            }
        }
        .onChange(of: isEditingGroups) {
            if !isEditingGroups {
                longPressedGroupId = nil
                dragOffsets.removeAll()
                if draggedGroupId != nil {
                    onCancelDrag()
                }
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
        let wiggleCondition = !isDragged && isInEditMode

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
            .animation(dragTargetIndex != nil ? .spring(response: 0.3, dampingFraction: 0.7) : .default, value: dragTargetIndex)
            .animation(
                wiggleCondition
                    ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                    : .easeOut(duration: 0.15),
                value: longPressedGroupId
            )
            .onTapGesture {
                guard longPressedGroupId == nil && draggedGroupId == nil else {
                    finishDrag()
                    return
                }
                if let originalIndex = groups.firstIndex(where: { $0.id == group.id }) {
                    onSelect(originalIndex)
                }
            }
            .onLongPressGesture(minimumDuration: 0.4, pressing: { isPressing in
                if !isPressing && isEditingGroups && !isDragging {
                    finishDrag()
                }
            }) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                longPressedGroupId = group.id
                isEditingGroups = true
            }
            .simultaneousGesture(
                DragGesture(coordinateSpace: .named("tabBarScroll"))
                    .onChanged { dragValue in
                        guard longPressedGroupId != nil else { return }
                        isDragging = true
                        if draggedGroupId != group.id {
                            onBeginDrag(group.id)
                        }
                        dragOffsets[group.id] = dragValue.translation.width
                        let targetIdx = computeTargetIndex(
                            draggedId: group.id,
                            translation: dragValue.translation.width,
                            location: dragValue.location.x
                        )
                        if targetIdx != lastHapticTargetIndex {
                            lastHapticTargetIndex = targetIdx
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        onUpdateDragTarget(targetIdx)
                    }
                    .onEnded { _ in
                        guard longPressedGroupId != nil else { return }
                        let orderedIds = displayGroups.map(\.id)
                        dragOffsets.removeAll()
                        isDragging = false
                        lastHapticTargetIndex = nil
                        DispatchQueue.main.async {
                            onEndDrag(orderedIds)
                            longPressedGroupId = nil
                            isEditingGroups = false
                        }
                    }
            )
    }

    private func finishDrag() {
        isDragging = false
        dragOffsets.removeAll()
        longPressedGroupId = nil
        isEditingGroups = false
    }

    private func computeTargetIndex(draggedId: UUID, translation: CGFloat, location: CGFloat) -> Int {
        guard let draggedFrame = tabFrames[draggedId] else {
            return groups.firstIndex(where: { $0.id == draggedId }) ?? 0
        }
        let draggedCenter = draggedFrame.midX + translation
        let fromIdx = groups.firstIndex(where: { $0.id == draggedId }) ?? 0

        if translation > 0 {
            // 오른쪽으로 이동: 바로 다음 탭(fromIdx+1)만 체크
            let nextIdx = fromIdx + 1
            guard nextIdx < groups.count,
                  let frame = tabFrames[groups[nextIdx].id] else { return fromIdx }
            if draggedCenter > frame.midX - frame.width * 0.5 {
                return nextIdx
            }
        } else if translation < 0 {
            // 왼쪽으로 이동: 바로 이전 탭(fromIdx-1)만 체크
            let prevIdx = fromIdx - 1
            guard prevIdx >= 0,
                  let frame = tabFrames[groups[prevIdx].id] else { return fromIdx }
            if draggedCenter < frame.midX + frame.width * 0.5 {
                return prevIdx
            }
        }
        return fromIdx
    }
}

// MARK: - Group Name Input Modal

private struct GroupNameInputModalView: View {
    let title: String
    let placeholder: String
    let confirmLabel: String
    let name: String
    let errorMessage: String?
    let onNameChange: (String) -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private let maxLength = 20

    @FocusState private var isFocused: Bool
    @State private var isShowingLimitError = false
    @State private var errorTimer: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.top, 24)
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 6) {
                TextField(placeholder, text: Binding(
                    get: { name },
                    set: { newValue in
                        if newValue.count <= maxLength {
                            onNameChange(newValue)
                        } else {
                            // 20자 초과 시도 시 피드백
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isShowingLimitError = true
                            }
                            // 기존 타이머 취소 후 새 타이머 시작 (Debounce)
                            errorTimer?.cancel()
                            errorTimer = Task {
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                if !Task.isCancelled {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isShowingLimitError = false
                                    }
                                }
                            }
                            // 실제 값은 20자로 유지
                            onNameChange(String(newValue.prefix(maxLength)))
                        }
                    }
                ))
                .focused($isFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack(alignment: .top) {
                    if isShowingLimitError {
                        Text("그룹 이름은 20자 이내로 입력해주세요.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Text("\(name.count)/\(maxLength)")
                        .font(.caption)
                        .foregroundStyle(isShowingLimitError ? .red : .secondary)
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("취소")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primary)

                let isConfirmDisabled = name.count > maxLength || isShowingLimitError || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                Button(action: onConfirm) {
                    Text(confirmLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isConfirmDisabled ? Color.blue.opacity(0.5) : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.white)
                .disabled(isConfirmDisabled)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .onAppear { isFocused = true }
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
//            Image(systemName: "ellipsis")
//                .rotationEffect(.degrees(90))
//                .foregroundStyle(Color(.systemGray3))
//                .font(.subheadline)
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
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            logoView
            nameColumn
            Spacer()
            priceColumn
            heartButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var heartButton: some View {
        Button {
            onRemove()
        } label: {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
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

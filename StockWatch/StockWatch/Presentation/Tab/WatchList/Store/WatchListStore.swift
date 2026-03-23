//
//  WatchListStore.swift
//  StockWatch
//

import Foundation
import SwiftUI

/// WatchList 화면 Store
@MainActor
final class WatchListStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: WatchListState
    private let fetchFavoritesUseCase: FetchFavoritesUseCaseProtocol
    private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol
    private let manageGroupUseCase: ManageWatchListGroupUseCaseProtocol
    private let fetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCaseProtocol
    private let addFavoriteToGroupUseCase: AddFavoriteToGroupUseCaseProtocol
    private let fetchStockQuoteUseCase: FetchStockQuoteUseCaseProtocol
    private let fetchGroupIdsForTickerUseCase: FetchGroupIdsForTickerUseCaseProtocol
    private let updateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCaseProtocol
    private var toastDismissTask: Task<Void, Never>?

    // MARK: - Init

    init(
        fetchFavoritesUseCase: FetchFavoritesUseCaseProtocol,
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        manageGroupUseCase: ManageWatchListGroupUseCaseProtocol,
        fetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCaseProtocol,
        addFavoriteToGroupUseCase: AddFavoriteToGroupUseCaseProtocol,
        fetchStockQuoteUseCase: FetchStockQuoteUseCaseProtocol,
        fetchGroupIdsForTickerUseCase: FetchGroupIdsForTickerUseCaseProtocol,
        updateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCaseProtocol,
        state: WatchListState = WatchListState()
    ) {
        self.state = state
        self.fetchFavoritesUseCase = fetchFavoritesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.manageGroupUseCase = manageGroupUseCase
        self.fetchFavoritesByGroupUseCase = fetchFavoritesByGroupUseCase
        self.addFavoriteToGroupUseCase = addFavoriteToGroupUseCase
        self.fetchStockQuoteUseCase = fetchStockQuoteUseCase
        self.fetchGroupIdsForTickerUseCase = fetchGroupIdsForTickerUseCase
        self.updateFavoriteGroupsUseCase = updateFavoriteGroupsUseCase
    }

    // MARK: - Action

    func action(_ intent: WatchListIntent) {
        switch intent {
        case .loadFavorites:
            loadFavorites()
        case .removeFavorite(let ticker):
            removeFavorite(ticker: ticker)
        case .selectTicker(let ticker):
            state.selectedTicker = ticker
        case .selectGroup(let index):
            guard index >= 0 && index < state.groups.count else { return }
            state.selectedGroupIndex = index
            saveLastSelectedGroupId()
            loadFavorites()
        case .loadGroups:
            loadGroups()
        case .createGroup(let name):
            createGroup(name: name)
        case .deleteGroup(let id):
            deleteGroup(id: id)
        case .addStocksToGroup(let results, let logoURLs):
            addStocksToGroup(results, logoURLs: logoURLs)
        case .setGroupToRename(let group):
            state.groupToRename = group
            state.renameGroupName = group.name
        case .renameGroup(let id, let name):
            renameGroup(id: id, name: name)
        case .reorderGroups(let orderedIds):
            reorderGroups(orderedIds: orderedIds)
        case .beginGroupDrag(let groupId):
            state.draggedGroupId = groupId
        case .updateGroupDragTarget(let index):
            state.dragTargetIndex = index
        case .endGroupDrag:
            state.draggedGroupId = nil
            state.dragTargetIndex = nil
        case .removeFavoriteWithUndo(let ticker):
            Task { await removeFavoriteWithUndo(ticker: ticker) }
        case .undoRemoveFavorite:
            Task { await undoRemoveFavorite() }
        }
    }

    // MARK: - Navigation Binding

    var selectedTickerBinding: Binding<String?> {
        Binding(
            get: {
                return self.state.selectedTicker
            },
            set: {
                self.state.selectedTicker = $0
            }
        )
    }
}

// MARK: - Private

private extension WatchListStore {

    func loadFavorites() {
        state.isLoading = true
        Task {
            let index = state.selectedGroupIndex
            guard !state.dbGroups.isEmpty else {
                state.favorites = []
                state.isLoading = false
                return
            }
            guard index < state.dbGroups.count else {
                state.favorites = []
                state.isLoading = false
                return
            }
            let groupId = state.dbGroups[index].id
            state.favorites = await fetchFavoritesByGroupUseCase.execute(groupId: groupId)
            state.isLoading = false
            loadPrices(for: state.favorites.map(\.ticker))
        }
    }

    func loadGroups() {
        Task {
            let groups = await manageGroupUseCase.fetchGroups()
            state.dbGroups = groups
            restoreLastSelectedGroupIndex(from: groups)
            loadFavorites()
        }
    }

    func createGroup(name: String) {
        Task {
            do {
                _ = try await manageGroupUseCase.createGroup(name: name)
            } catch {
                // 그룹 생성 실패 시 무시
            }
            state.dbGroups = await manageGroupUseCase.fetchGroups()
        }
    }

    func deleteGroup(id: UUID) {
        Task {
            do {
                try await manageGroupUseCase.deleteGroup(id: id)
            } catch {
                return
            }
            let groups = await manageGroupUseCase.fetchGroups()
            state.dbGroups = groups
            if groups.isEmpty {
                state.selectedGroupIndex = 0
                state.favorites = []
                state.isLoading = false
            } else {
                if state.selectedGroupIndex >= groups.count {
                    state.selectedGroupIndex = 0
                }
                saveLastSelectedGroupId()
                loadFavorites()
            }
        }
    }

    func saveLastSelectedGroupId() {
        guard state.selectedGroupIndex < state.dbGroups.count else { return }
        let groupId = state.dbGroups[state.selectedGroupIndex].id.uuidString
        UserDefaults.standard.set(groupId, forKey: "lastSelectedGroupId")
    }

    func restoreLastSelectedGroupIndex(from groups: [WatchListGroup]) {
        guard !groups.isEmpty else {
            state.selectedGroupIndex = 0
            return
        }
        guard let savedId = UserDefaults.standard.string(forKey: "lastSelectedGroupId"),
              let uuid = UUID(uuidString: savedId),
              let index = groups.firstIndex(where: { $0.id == uuid }) else {
            state.selectedGroupIndex = 0
            return
        }
        state.selectedGroupIndex = index
    }

    func renameGroup(id: UUID, name: String) {
        Task {
            do {
                try await manageGroupUseCase.renameGroup(id: id, name: name)
            } catch {
                return
            }
            state.dbGroups = await manageGroupUseCase.fetchGroups()
            state.groupToRename = nil
            state.renameGroupName = ""
        }
    }

    func addStocksToGroup(_ results: [SearchResult], logoURLs: [String: String]) {
        guard state.selectedGroupIndex < state.dbGroups.count else { return }
        let groupId = state.dbGroups[state.selectedGroupIndex].id
        Task {
            for result in results {
                let logoURL = logoURLs[result.displayTicker] ?? logoURLs[result.ticker] ?? ""
                try? await addFavoriteToGroupUseCase.execute(
                    ticker: result.displayTicker,
                    companyName: result.description,
                    logoURL: logoURL,
                    groupId: groupId
                )
            }
            loadFavorites()
        }
    }

    func loadPrices(for tickers: [String]) {
        guard !tickers.isEmpty else { return }
        state.isPriceLoading = true
        Task {
            var result: [String: StockQuote] = [:]
            await withTaskGroup(of: (String, StockQuote?).self) { group in
                for ticker in tickers {
                    group.addTask {
                        let quote = try? await self.fetchStockQuoteUseCase.execute(ticker: ticker)
                        return (ticker, quote)
                    }
                }
                for await (ticker, quote) in group {
                    if let quote { result[ticker] = quote }
                }
            }
            state.priceData = result
            state.isPriceLoading = false
        }
    }

    func reorderGroups(orderedIds: [UUID]) {
        let previous = state.dbGroups
        let selectedId = state.selectedGroupIndex < state.dbGroups.count
            ? state.dbGroups[state.selectedGroupIndex].id
            : nil
        let reordered = orderedIds.compactMap { id in
            state.dbGroups.first { $0.id == id }
        }
        guard !reordered.isEmpty, reordered.count == state.dbGroups.count else {
            state.draggedGroupId = nil
            state.dragTargetIndex = nil
            return
        }
        state.dbGroups = reordered
        if let selectedId,
           let newIndex = state.dbGroups.firstIndex(where: { $0.id == selectedId }) {
            state.selectedGroupIndex = newIndex
        }
        state.draggedGroupId = nil
        state.dragTargetIndex = nil
        Task {
            do {
                try await manageGroupUseCase.reorderGroups(orderedIds: orderedIds)
            } catch {
                state.dbGroups = previous
            }
        }
    }

    /// 낙관적 UI 업데이트 후 SwiftData에서 제거한다.
    /// 실패 시 이전 목록으로 rollback한다.
    func removeFavorite(ticker: String) {
        let previous = state.favorites
        state.favorites.removeAll { $0.ticker == ticker }

        Task {
            do {
                _ = try await toggleFavoriteUseCase.execute(ticker: ticker, companyName: "")
            } catch {
                state.favorites = previous
            }
        }
    }

    /// 하트 버튼 탭 시 현재 그룹에서만 제거하고 되돌리기 토스트를 표시한다.
    func removeFavoriteWithUndo(ticker: String) async {
        guard state.selectedGroupIndex < state.dbGroups.count else { return }
        guard let item = state.favorites.first(where: { $0.ticker == ticker }) else { return }

        let currentGroupId = state.dbGroups[state.selectedGroupIndex].id
        let allGroupIds = await fetchGroupIdsForTickerUseCase.execute(ticker: ticker)
        let remainingGroupIds = allGroupIds.filter { $0 != currentGroupId }

        // 낙관적 UI 업데이트
        state.favorites.removeAll { $0.ticker == ticker }

        do {
            try await updateFavoriteGroupsUseCase.execute(
                ticker: item.ticker,
                companyName: item.companyName,
                logoURL: item.logoURL,
                groupIds: remainingGroupIds
            )
            state.undoInfo = WatchListUndoFavoriteInfo(
                ticker: item.ticker,
                companyName: item.companyName,
                logoURL: item.logoURL,
                groupId: currentGroupId
            )
            state.toastMessage = "워치리스트에서 삭제됐어요."
            state.isShowingToast = true
            scheduleToastDismiss()
        } catch {
            // 실패 시 rollback
            loadFavorites()
        }
    }

    /// 토스트 "되돌리기" 탭 시 삭제된 그룹에 다시 추가한다.
    func undoRemoveFavorite() async {
        guard let info = state.undoInfo else { return }
        toastDismissTask?.cancel()
        state.isShowingToast = false
        state.toastMessage = nil

        let allGroupIds = await fetchGroupIdsForTickerUseCase.execute(ticker: info.ticker)
        do {
            try await updateFavoriteGroupsUseCase.execute(
                ticker: info.ticker,
                companyName: info.companyName,
                logoURL: info.logoURL,
                groupIds: allGroupIds + [info.groupId]
            )
        } catch {
            // 복원 실패 시 무시
        }
        state.undoInfo = nil
        loadFavorites()
    }

    func scheduleToastDismiss() {
        toastDismissTask?.cancel()
        toastDismissTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            state.isShowingToast = false
            state.toastMessage = nil
            state.undoInfo = nil
        }
    }
}

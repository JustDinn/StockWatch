//
//  FavoriteGroupModalStore.swift
//  StockWatch
//

import Foundation
import SwiftUI

@MainActor
final class FavoriteGroupModalStore: ObservableObject {

    @Published private(set) var state: FavoriteGroupModalState

    private let manageGroupUseCase: ManageWatchListGroupUseCaseProtocol
    private let updateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCaseProtocol
    private let fetchGroupIdsUseCase: FetchGroupIdsForTickerUseCaseProtocol

    init(
        ticker: String,
        companyName: String,
        logoURL: String,
        manageGroupUseCase: ManageWatchListGroupUseCaseProtocol,
        updateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCaseProtocol,
        fetchGroupIdsUseCase: FetchGroupIdsForTickerUseCaseProtocol
    ) {
        self.state = FavoriteGroupModalState(ticker: ticker, companyName: companyName, logoURL: logoURL)
        self.manageGroupUseCase = manageGroupUseCase
        self.updateFavoriteGroupsUseCase = updateFavoriteGroupsUseCase
        self.fetchGroupIdsUseCase = fetchGroupIdsUseCase
    }

    func action(_ intent: FavoriteGroupModalIntent) {
        switch intent {
        case .loadGroups:
            loadGroups()
        case .toggleGroup(let id):
            if state.selectedGroupIds.contains(id) {
                state.selectedGroupIds.remove(id)
            } else {
                state.selectedGroupIds.insert(id)
            }
        case .createNewGroup(let name):
            createNewGroup(name: name)
        case .confirm:
            confirmSelection()
        case .dismiss:
            state.isDismissed = true
        }
    }
}

private extension FavoriteGroupModalStore {

    func loadGroups() {
        state.isLoading = true
        Task {
            async let groups = manageGroupUseCase.fetchGroups()
            async let currentGroupIds = fetchGroupIdsUseCase.execute(ticker: state.ticker)
            state.groups = await groups
            state.selectedGroupIds = Set(await currentGroupIds)
            state.isLoading = false
        }
    }

    func createNewGroup(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task {
            do {
                let newGroup = try await manageGroupUseCase.createGroup(name: trimmed)
                state.groups.append(newGroup)
                state.selectedGroupIds.insert(newGroup.id)
            } catch {
                // 중복 이름 등 에러 - 무시 (추후 에러 메시지 표시 가능)
            }
        }
    }

    func confirmSelection() {
        Task {
            do {
                try await updateFavoriteGroupsUseCase.execute(
                    ticker: state.ticker,
                    companyName: state.companyName,
                    logoURL: state.logoURL,
                    groupIds: Array(state.selectedGroupIds)
                )
                state.isDismissed = true
            } catch {
                // 에러 처리
            }
        }
    }
}

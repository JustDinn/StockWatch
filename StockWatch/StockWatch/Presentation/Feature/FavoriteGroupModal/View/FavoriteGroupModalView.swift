//
//  FavoriteGroupModalView.swift
//  StockWatch
//

import SwiftUI
import SwiftData
import Kingfisher

struct FavoriteGroupModalView: View {
    @Environment(\.modelContext) private var modelContext
    let ticker: String
    let companyName: String
    let logoURL: String
    let onDismiss: () -> Void

    var body: some View {
        FavoriteGroupModalContentView(
            ticker: ticker,
            companyName: companyName,
            logoURL: logoURL,
            modelContext: modelContext,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Content View

private struct FavoriteGroupModalContentView: View {
    @StateObject private var store: FavoriteGroupModalStore
    @State private var isShowingNewGroupInput = false
    @State private var newGroupName = ""
    let onDismiss: () -> Void

    init(ticker: String, companyName: String, logoURL: String, modelContext: ModelContext, onDismiss: @escaping () -> Void) {
        let repository = FavoriteRepository(modelContext: modelContext)
        let groupRepository = WatchListGroupRepository(modelContext: modelContext)
        _store = StateObject(wrappedValue: FavoriteGroupModalStore(
            ticker: ticker,
            companyName: companyName,
            logoURL: logoURL,
            manageGroupUseCase: ManageWatchListGroupUseCase(repository: groupRepository),
            updateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCase(repository: repository),
            fetchGroupIdsUseCase: FetchGroupIdsForTickerUseCase(repository: repository)
        ))
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            addGroupButton
            if isShowingNewGroupInput { newGroupInputRow }
            groupList
            bottomButtons
        }
        .frame(maxHeight: 420)
        .onAppear { store.action(.loadGroups) }
        .onChange(of: store.state.isDismissed) { _, v in if v { onDismiss() } }
    }

    private var addGroupButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingNewGroupInput.toggle()
                if !isShowingNewGroupInput { newGroupName = "" }
            }
        } label: {
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
    }

    private var newGroupInputRow: some View {
        HStack(spacing: 8) {
            TextField("그룹 이름", text: $newGroupName)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submitNewGroup() }
            Button("추가") { submitNewGroup() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func submitNewGroup() {
        store.action(.createNewGroup(newGroupName))
        newGroupName = ""
        withAnimation { isShowingNewGroupInput = false }
    }

    private var groupList: some View {
        Group {
            if store.state.isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.state.groups, id: \.id) { group in
                            groupRow(group)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func groupRow(_ group: WatchListGroup) -> some View {
        let isSelected = store.state.selectedGroupIds.contains(group.id)
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)
                .font(.title3)
            Text(group.name)
                .font(.subheadline)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : Color(.systemGray3))
                .font(.title3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture { store.action(.toggleGroup(group.id)) }
    }

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button("취소") { onDismiss() }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Button("확인") { store.action(.confirm) }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var logoView: some View {
        let size: CGFloat = 44
        if !store.state.logoURL.isEmpty, let url = URL(string: store.state.logoURL) {
            KFImage(url)
                .placeholder { initialsView(size: size) }
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            initialsView(size: size)
        }
    }

    private func initialsView(size: CGFloat) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Text(String(store.state.ticker.prefix(2)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            )
    }
}

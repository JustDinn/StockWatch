//
//  WatchListState.swift
//  StockWatch
//

import Foundation

/// 되돌리기를 위한 삭제 전 즐겨찾기 정보
struct WatchListUndoFavoriteInfo: Equatable {
    let ticker: String
    let companyName: String
    let logoURL: String
    let groupId: UUID
}

/// WatchList 화면 UI 상태
struct WatchListState {
    var favorites: [FavoriteItem] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var selectedTicker: String? = nil  /// 선택된 종목 (nil이면 상세 화면 미표시)

    /// DB에서 로드된 그룹 목록
    var dbGroups: [WatchListGroup] = []
    var selectedGroupIndex: Int = 0

    /// DB 그룹명 목록
    var groups: [String] { dbGroups.map(\.name) }

    /// 그룹 추가 모달
    var isShowingAddGroupModal: Bool = false
    var addGroupName: String = ""
    var addGroupNameError: String? = nil

    /// 그룹 수정 모달
    var isShowingRenameGroupModal: Bool = false
    var groupToRename: WatchListGroup? = nil
    var renameGroupName: String = ""
    var renameGroupNameError: String? = nil

    /// 티커 → 실제 가격 데이터
    var priceData: [String: StockQuote] = [:]
    var isPriceLoading: Bool = false

    /// 그룹 탭 드래그 상태
    var draggedGroupId: UUID? = nil
    var dragTargetIndex: Int? = nil
    var isDraggingGroup: Bool { draggedGroupId != nil }

    /// 토스트 표시 여부
    var isShowingToast: Bool = false
    /// 토스트 메시지
    var toastMessage: String? = nil
    /// 되돌리기용 삭제 정보
    var undoInfo: WatchListUndoFavoriteInfo? = nil

    /// 테스트 편의용 이니셜라이저
    init(favorites: [FavoriteItem] = []) {
        self.favorites = favorites
    }
}

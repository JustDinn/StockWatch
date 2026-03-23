//
//  WatchListIntent.swift
//  StockWatch
//

import Foundation

/// WatchList 화면 사용자 액션 정의
enum WatchListIntent {
    /// 관심 종목 목록 로드
    case loadFavorites
    /// 특정 종목을 관심 목록에서 제거
    case removeFavorite(ticker: String)
    /// 종목 상세 화면으로 이동
    case selectTicker(String)
    /// 그룹 탭 선택
    case selectGroup(index: Int)
    /// 그룹 목록 로드
    case loadGroups
    /// 그룹 추가 모달 표시
    case showAddGroupModal
    /// 그룹 추가 모달 숨김
    case hideAddGroupModal
    /// 그룹 추가 이름 입력 업데이트
    case updateAddGroupName(String)
    /// 새 그룹 생성
    case createGroup
    /// 그룹 삭제
    case deleteGroup(id: UUID)
    /// 선택된 종목들을 현재 그룹에 추가
    case addStocksToGroup([SearchResult], [String: String])
    /// 그룹 수정 모달 표시
    case showRenameGroupModal(WatchListGroup)
    /// 그룹 수정 모달 숨김
    case hideRenameGroupModal
    /// 그룹 수정 이름 입력 업데이트
    case updateRenameGroupName(String)
    /// 그룹 이름 수정 확정
    case renameGroup
    /// 그룹 순서 변경
    case reorderGroups(orderedIds: [UUID])
    /// 그룹 드래그 시작
    case beginGroupDrag(groupId: UUID)
    /// 그룹 드래그 목표 인덱스 업데이트
    case updateGroupDragTarget(index: Int)
    /// 그룹 드래그 종료
    case endGroupDrag
    /// 하트 버튼 탭 → 현재 그룹에서 제거 + 되돌리기 토스트 표시
    case removeFavoriteWithUndo(ticker: String)
    /// 토스트 "되돌리기" 탭 → 관심 목록 복원
    case undoRemoveFavorite
}

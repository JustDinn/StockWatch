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
    /// 새 그룹 생성
    case createGroup(String)
    /// 그룹 삭제
    case deleteGroup(id: UUID)
    /// 선택된 종목들을 현재 그룹에 추가
    case addStocksToGroup([SearchResult], [String: String])
    /// 수정 대상 그룹 설정
    case setGroupToRename(WatchListGroup)
    /// 그룹 이름 수정
    case renameGroup(id: UUID, name: String)
    /// 그룹 순서 변경
    case reorderGroups(orderedIds: [UUID])
    /// 그룹 드래그 시작
    case beginGroupDrag(groupId: UUID)
    /// 그룹 드래그 목표 인덱스 업데이트
    case updateGroupDragTarget(index: Int)
    /// 그룹 드래그 종료
    case endGroupDrag
}

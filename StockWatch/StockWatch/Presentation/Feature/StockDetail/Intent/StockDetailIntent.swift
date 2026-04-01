//
//  StockDetailIntent.swift
//  StockWatch
//

/// StockDetail 화면 사용자 액션 정의
enum StockDetailIntent {
    /// 화면 진입 시 종목 상세 데이터 로드
    case loadDetail
    /// 뒤로 가기 (현재 단계에서는 SwiftUI 내장 뒤로 가기를 사용하므로 예약)
    case dismiss
    /// 관심 종목 그룹 선택 모달 표시
    case showFavoriteModal
    /// 하트 탭 — 그룹 수에 따라 모달 표시 or 즉시 삭제
    case toggleFavorite
    /// 관심 종목 상태 재조회 (모달 닫힌 후)
    case reloadFavoriteStatus
    /// 워치리스트 단일 삭제 되돌리기
    case undoRemoveFavorite
    /// 토스트 닫기
    case dismissToast
    /// 전략 적용 화면으로 이동
    case navigateToApplyStrategy
    /// 기술적 지표 설정 화면으로 이동
    case navigateToIndicatorSettings
    /// 봉 주기 선택
    case selectPeriod(ChartPeriod)
    /// 차트 좌측 끝 도달 시 과거 데이터 로드
    case loadOlderCandles
    /// 과거 캔들 차트 주입 완료 후 pending 초기화
    case clearPendingOlderCandles
    /// 기술적 지표 설정 리로드
    case reloadIndicatorSettings
    /// 차트 상단 지표 라벨 펼침/접힘 토글
    case toggleIndicatorLabelExpanded
}

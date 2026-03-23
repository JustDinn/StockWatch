//
//  ForceUpdateStore.swift
//  StockWatch
//

import Foundation

@MainActor
final class ForceUpdateStore: ObservableObject {

    @Published private(set) var state: ForceUpdateState

    private let checkVersionUseCase: CheckAppVersionUseCaseProtocol

    init(
        checkVersionUseCase: CheckAppVersionUseCaseProtocol = CheckAppVersionUseCase(
            repository: AppVersionRepository()
        ),
        state: ForceUpdateState = ForceUpdateState()
    ) {
        self.checkVersionUseCase = checkVersionUseCase
        self.state = state
    }

    func action(_ intent: ForceUpdateIntent) {
        switch intent {
        case .checkVersion(let currentVersion):
            Task { await checkVersionAsync(currentVersion: currentVersion) }
        case .openAppStore:
            openAppStore()
        }
    }

    /// 버전 체크 완료를 await할 수 있는 메서드 (앱 진입 전 블로킹용)
    func checkVersionAsync(currentVersion: String) async {
        do {
            let status = try await checkVersionUseCase.execute(currentVersion: currentVersion)
            if case .updateRequired(_, let storeURL) = status {
                state.showUpdate = true
                state.storeURL = storeURL
            }
        } catch {
            // fail-open: 에러 시 앱 사용 차단하지 않음
        }
    }

    private func openAppStore() {
        guard let urlString = state.storeURL, let url = URL(string: urlString) else { return }
        AppStoreHelper.open(url: url)
    }
}

//
//  CheckAppVersionUseCase.swift
//  StockWatch
//

final class CheckAppVersionUseCase: CheckAppVersionUseCaseProtocol {

    private let repository: AppVersionRepositoryProtocol

    init(repository: AppVersionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(currentVersion: String) async throws -> AppVersionStatus {
        let config = try await repository.fetchMinimumVersion()
        let isUpdateRequired = isVersion(currentVersion, lessThan: config.minimumVersion)
        return isUpdateRequired
            ? .updateRequired(minimumVersion: config.minimumVersion, storeURL: config.storeURL)
            : .upToDate
    }

    // MARK: - Private

    /// 시맨틱 버전 비교 (e.g. "1.2.3" < "1.3.0")
    private func isVersion(_ lhs: String, lessThan rhs: String) -> Bool {
        let lhsParts = lhs.split(separator: ".").compactMap { Int($0) }
        let rhsParts = rhs.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(lhsParts.count, rhsParts.count)
        for i in 0..<maxCount {
            let l = i < lhsParts.count ? lhsParts[i] : 0
            let r = i < rhsParts.count ? rhsParts[i] : 0
            if l < r { return true }
            if l > r { return false }
        }
        return false
    }
}

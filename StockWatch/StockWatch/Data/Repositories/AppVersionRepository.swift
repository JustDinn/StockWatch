//
//  AppVersionRepository.swift
//  StockWatch
//

import FirebaseRemoteConfig

// MARK: - RemoteConfig Abstraction (for testability)

protocol RemoteConfigProviding {
    func fetchAndActivate() async throws
    func stringValue(forKey key: String) -> String
}

final class FirebaseRemoteConfigProvider: RemoteConfigProviding {

    private let remoteConfig: RemoteConfig

    init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        remoteConfig.configSettings = settings
    }

    func fetchAndActivate() async throws {
        try await remoteConfig.fetchAndActivate()
    }

    func stringValue(forKey key: String) -> String {
        remoteConfig.configValue(forKey: key).stringValue ?? ""
    }
}

// MARK: - Repository

final class AppVersionRepository: AppVersionRepositoryProtocol {

    private let remoteConfigProvider: RemoteConfigProviding

    init(remoteConfigProvider: RemoteConfigProviding = FirebaseRemoteConfigProvider()) {
        self.remoteConfigProvider = remoteConfigProvider
    }

    func fetchMinimumVersion() async throws -> (minimumVersion: String, storeURL: String) {
        try await remoteConfigProvider.fetchAndActivate()
        let minimumVersion = remoteConfigProvider.stringValue(forKey: "minimum_app_version")
        let storeURL = remoteConfigProvider.stringValue(forKey: "app_store_url")
        return (minimumVersion: minimumVersion, storeURL: storeURL)
    }
}

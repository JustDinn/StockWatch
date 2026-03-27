//
//  TechnicalIndicatorSettingsManager.swift
//  StockWatch
//

import Foundation
import Combine

/// 기술적 지표 설정을 관리하는 Singleton Manager
@MainActor
final class TechnicalIndicatorSettingsManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TechnicalIndicatorSettingsManager()

    // MARK: - Published Properties

    @Published private(set) var maConfiguration: MAIndicatorConfiguration {
        didSet {
            saveMAConfiguration()
        }
    }

    @Published private(set) var isMAEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMAEnabled, forKey: Keys.isMAEnabled)
        }
    }

    // MARK: - Private Properties

    private enum Keys {
        static let maConfiguration = "technical_indicator_ma_configuration"
        static let isMAEnabled = "technical_indicator_ma_enabled"
    }

    // MARK: - Init

    private init() {
        self.maConfiguration = Self.loadMAConfiguration()
        self.isMAEnabled = UserDefaults.standard.bool(forKey: Keys.isMAEnabled)
    }

    // MARK: - Public Methods

    /// 이동평균선 설정 업데이트
    func updateMAConfiguration(_ configuration: MAIndicatorConfiguration) {
        self.maConfiguration = configuration
    }

    /// 이동평균선 활성화 상태 업데이트
    func updateMAEnabled(_ enabled: Bool) {
        self.isMAEnabled = enabled
    }

    /// 모든 설정 초기화
    func reset() {
        self.maConfiguration = MAIndicatorConfiguration.defaultConfiguration
        self.isMAEnabled = false
    }

    // MARK: - Private Methods

    private func saveMAConfiguration() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(maConfiguration)
            UserDefaults.standard.set(data, forKey: Keys.maConfiguration)
        } catch {
            print("Failed to save MA configuration: \(error)")
        }
    }

    private static func loadMAConfiguration() -> MAIndicatorConfiguration {
        guard let data = UserDefaults.standard.data(forKey: Keys.maConfiguration) else {
            return MAIndicatorConfiguration.defaultConfiguration
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(MAIndicatorConfiguration.self, from: data)
        } catch {
            print("Failed to load MA configuration: \(error)")
            return MAIndicatorConfiguration.defaultConfiguration
        }
    }
}

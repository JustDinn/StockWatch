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

    @Published private(set) var emaConfiguration: EMAIndicatorConfiguration {
        didSet {
            saveEMAConfiguration()
        }
    }

    @Published private(set) var isEMAEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEMAEnabled, forKey: Keys.isEMAEnabled)
        }
    }

    @Published private(set) var isVolumeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isVolumeEnabled, forKey: Keys.isVolumeEnabled)
        }
    }

    @Published private(set) var volumeMAConfiguration: VolumeMAConfiguration {
        didSet {
            saveVolumeMAConfiguration()
        }
    }

    @Published private(set) var isRSIEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isRSIEnabled, forKey: Keys.isRSIEnabled)
        }
    }

    @Published private(set) var rsiConfiguration: RSIConfiguration {
        didSet {
            saveRSIConfiguration()
        }
    }

    // MARK: - Private Properties

    private enum Keys {
        static let maConfiguration = "technical_indicator_ma_configuration"
        static let isMAEnabled = "technical_indicator_ma_enabled"
        static let emaConfiguration = "technical_indicator_ema_configuration"
        static let isEMAEnabled = "technical_indicator_ema_enabled"
        static let isVolumeEnabled = "technical_indicator_volume_enabled"
        static let volumeMAConfiguration = "technical_indicator_volume_ma_configuration"
        static let isRSIEnabled = "technical_indicator_rsi_enabled"
        static let rsiConfiguration = "technical_indicator_rsi_configuration"
    }

    // MARK: - Init

    private init() {
        self.maConfiguration = Self.loadMAConfiguration()
        self.isMAEnabled = UserDefaults.standard.bool(forKey: Keys.isMAEnabled)
        self.emaConfiguration = Self.loadEMAConfiguration()
        self.isEMAEnabled = UserDefaults.standard.bool(forKey: Keys.isEMAEnabled)
        self.isVolumeEnabled = UserDefaults.standard.bool(forKey: Keys.isVolumeEnabled)
        self.volumeMAConfiguration = Self.loadVolumeMAConfiguration()
        self.isRSIEnabled = UserDefaults.standard.bool(forKey: Keys.isRSIEnabled)
        self.rsiConfiguration = Self.loadRSIConfiguration()
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

    /// 지수이동평균선 설정 업데이트
    func updateEMAConfiguration(_ configuration: EMAIndicatorConfiguration) {
        self.emaConfiguration = configuration
    }

    /// 지수이동평균선 활성화 상태 업데이트
    func updateEMAEnabled(_ enabled: Bool) {
        self.isEMAEnabled = enabled
    }

    /// 거래량 활성화 상태 업데이트
    func updateVolumeEnabled(_ enabled: Bool) {
        self.isVolumeEnabled = enabled
    }

    /// 거래량 이동평균선 설정 업데이트
    func updateVolumeMAConfiguration(_ configuration: VolumeMAConfiguration) {
        self.volumeMAConfiguration = configuration
    }

    /// RSI 활성화 상태 업데이트
    func updateRSIEnabled(_ enabled: Bool) {
        self.isRSIEnabled = enabled
    }

    /// RSI 설정 업데이트
    func updateRSIConfiguration(_ configuration: RSIConfiguration) {
        self.rsiConfiguration = configuration
    }

    /// 모든 설정 초기화
    func reset() {
        self.maConfiguration = MAIndicatorConfiguration.defaultConfiguration
        self.isMAEnabled = false
        self.emaConfiguration = EMAIndicatorConfiguration.defaultConfiguration
        self.isEMAEnabled = false
        self.isVolumeEnabled = false
        self.volumeMAConfiguration = VolumeMAConfiguration.defaultConfiguration
        self.isRSIEnabled = false
        self.rsiConfiguration = RSIConfiguration.defaultConfiguration
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

    private func saveEMAConfiguration() {
        do {
            let data = try JSONEncoder().encode(emaConfiguration)
            UserDefaults.standard.set(data, forKey: Keys.emaConfiguration)
        } catch {
            print("Failed to save EMA configuration: \(error)")
        }
    }

    private func saveVolumeMAConfiguration() {
        do {
            let data = try JSONEncoder().encode(volumeMAConfiguration)
            UserDefaults.standard.set(data, forKey: Keys.volumeMAConfiguration)
        } catch {
            print("Failed to save VolumeMA configuration: \(error)")
        }
    }

    private static func loadVolumeMAConfiguration() -> VolumeMAConfiguration {
        guard let data = UserDefaults.standard.data(forKey: Keys.volumeMAConfiguration) else {
            return VolumeMAConfiguration.defaultConfiguration
        }
        do {
            return try JSONDecoder().decode(VolumeMAConfiguration.self, from: data)
        } catch {
            print("Failed to load VolumeMA configuration: \(error)")
            return VolumeMAConfiguration.defaultConfiguration
        }
    }

    private func saveRSIConfiguration() {
        do {
            let data = try JSONEncoder().encode(rsiConfiguration)
            UserDefaults.standard.set(data, forKey: Keys.rsiConfiguration)
        } catch {
            print("Failed to save RSI configuration: \(error)")
        }
    }

    private static func loadRSIConfiguration() -> RSIConfiguration {
        guard let data = UserDefaults.standard.data(forKey: Keys.rsiConfiguration) else {
            return RSIConfiguration.defaultConfiguration
        }
        do {
            return try JSONDecoder().decode(RSIConfiguration.self, from: data)
        } catch {
            print("Failed to load RSI configuration: \(error)")
            return RSIConfiguration.defaultConfiguration
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

    private static func loadEMAConfiguration() -> EMAIndicatorConfiguration {
        guard let data = UserDefaults.standard.data(forKey: Keys.emaConfiguration) else {
            return EMAIndicatorConfiguration.defaultConfiguration
        }

        do {
            return try JSONDecoder().decode(EMAIndicatorConfiguration.self, from: data)
        } catch {
            print("Failed to load EMA configuration: \(error)")
            return EMAIndicatorConfiguration.defaultConfiguration
        }
    }
}

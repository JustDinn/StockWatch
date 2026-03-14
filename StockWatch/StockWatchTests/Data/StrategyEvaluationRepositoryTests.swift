//
//  StrategyEvaluationRepositoryTests.swift
//  StockWatchTests
//

import XCTest
@testable import StockWatch

final class StrategyEvaluationRepositoryTests: XCTestCase {

    private var sut: StrategyEvaluationRepository!
    private var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = StrategyEvaluationRepository(networkService: mockNetworkService)
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// shortPeriod > longPeriod인 SMA 조건을 만족하는 종가 배열 생성 (매수 신호)
    /// 앞 50개는 낮은 값, 뒤로 갈수록 높아지게 설계 → 단기 SMA > 장기 SMA
    private func makeClosesForGoldenCross(shortPeriod: Int = 20, longPeriod: Int = 50) -> [Double] {
        // 처음 longPeriod개: 100.0 (낮음), 이후 shortPeriod개: 200.0 (높음)
        // 결과: SMA(20) ≈ 200, SMA(50) ≈ (50*100 + 0*200)/50 이하 → 단기 > 장기
        var closes = Array(repeating: 100.0, count: longPeriod)
        closes += Array(repeating: 200.0, count: shortPeriod)
        return closes
    }

    /// shortPeriod < longPeriod인 SMA 조건을 만족하는 종가 배열 생성 (매도 신호)
    /// 앞 50개는 높은 값, 뒤로 갈수록 낮아지게 설계 → 단기 SMA < 장기 SMA
    private func makeClosesForDeadCross(shortPeriod: Int = 20, longPeriod: Int = 50) -> [Double] {
        var closes = Array(repeating: 200.0, count: longPeriod)
        closes += Array(repeating: 100.0, count: shortPeriod)
        return closes
    }

    /// RSI가 oversold 이하가 되도록 설계된 종가 배열 (매수 신호)
    /// 연속 하락으로 손실이 큰 경우 RSI < 30
    private func makeClosesForOversoldRSI(period: Int = 14) -> [Double] {
        // 기준값 100에서 각 스텝마다 5씩 하락
        let count = period + 10
        return (0..<count).map { 100.0 - Double($0) * 5.0 }
    }

    /// RSI가 overbought 이상이 되도록 설계된 종가 배열 (매도 신호)
    /// 연속 상승으로 이익이 큰 경우 RSI > 70
    private func makeClosesForOverboughtRSI(period: Int = 14) -> [Double] {
        let count = period + 10
        return (0..<count).map { 100.0 + Double($0) * 5.0 }
    }

    private func makeDTO(closes: [Double]) -> YahooFinanceChartDTO {
        YahooFinanceChartDTO(
            chart: .init(
                result: [
                    .init(indicators: .init(quote: [.init(close: closes.map { Optional($0) })]))
                ],
                error: nil
            )
        )
    }

    // MARK: - SMA Tests

    func test_evaluate_sma_whenShortAboveLong_returnsBuySignal() async throws {
        // Arrange
        let closes = makeClosesForGoldenCross()
        mockNetworkService.stubbedResult = makeDTO(closes: closes)

        // Act
        let signal = try await sut.evaluate(ticker: "AAPL", parameters: .sma(shortPeriod: 20, longPeriod: 50))

        // Assert
        XCTAssertEqual(signal.signalType, .buy)
        XCTAssertEqual(signal.ticker, "AAPL")
        XCTAssertEqual(signal.strategyId, "sma_cross")
    }

    func test_evaluate_sma_whenShortBelowLong_returnsSellSignal() async throws {
        // Arrange
        let closes = makeClosesForDeadCross()
        mockNetworkService.stubbedResult = makeDTO(closes: closes)

        // Act
        let signal = try await sut.evaluate(ticker: "AAPL", parameters: .sma(shortPeriod: 20, longPeriod: 50))

        // Assert
        XCTAssertEqual(signal.signalType, .sell)
    }

    // MARK: - EMA Tests

    func test_evaluate_ema_whenShortAboveLong_returnsBuySignal() async throws {
        // Arrange
        let closes = makeClosesForGoldenCross(shortPeriod: 12, longPeriod: 26)
        mockNetworkService.stubbedResult = makeDTO(closes: closes)

        // Act
        let signal = try await sut.evaluate(ticker: "AAPL", parameters: .ema(shortPeriod: 12, longPeriod: 26))

        // Assert
        XCTAssertEqual(signal.signalType, .buy)
        XCTAssertEqual(signal.strategyId, "ema_cross")
    }

    func test_evaluate_ema_whenShortBelowLong_returnsSellSignal() async throws {
        // Arrange
        let closes = makeClosesForDeadCross(shortPeriod: 12, longPeriod: 26)
        mockNetworkService.stubbedResult = makeDTO(closes: closes)

        // Act
        let signal = try await sut.evaluate(ticker: "AAPL", parameters: .ema(shortPeriod: 12, longPeriod: 26))

        // Assert
        XCTAssertEqual(signal.signalType, .sell)
    }

    // MARK: - RSI Tests

    func test_evaluate_rsi_whenBelowOversold_returnsBuySignal() async throws {
        // Arrange
        let closes = makeClosesForOversoldRSI(period: 14)
        mockNetworkService.stubbedResult = makeDTO(closes: closes)

        // Act
        let signal = try await sut.evaluate(
            ticker: "AAPL",
            parameters: .rsi(period: 14, oversoldThreshold: 30, overboughtThreshold: 70)
        )

        // Assert
        XCTAssertEqual(signal.signalType, .buy)
        XCTAssertEqual(signal.strategyId, "rsi")
    }

    func test_evaluate_rsi_whenAboveOverbought_returnsSellSignal() async throws {
        // Arrange
        let closes = makeClosesForOverboughtRSI(period: 14)
        mockNetworkService.stubbedResult = makeDTO(closes: closes)

        // Act
        let signal = try await sut.evaluate(
            ticker: "AAPL",
            parameters: .rsi(period: 14, oversoldThreshold: 30, overboughtThreshold: 70)
        )

        // Assert
        XCTAssertEqual(signal.signalType, .sell)
    }

    // MARK: - Edge Cases

    func test_evaluate_sma_whenInsufficientData_returnsNeutralSignal() async throws {
        // Arrange: 데이터가 5개뿐, longPeriod=50이므로 계산 불가
        let closes = [100.0, 101.0, 102.0, 103.0, 104.0]
        mockNetworkService.stubbedResult = makeDTO(closes: closes)

        // Act
        let signal = try await sut.evaluate(ticker: "AAPL", parameters: .sma(shortPeriod: 20, longPeriod: 50))

        // Assert
        XCTAssertEqual(signal.signalType, .neutral)
    }

    func test_evaluate_whenNetworkFails_throwsError() async {
        // Arrange
        mockNetworkService.stubbedError = NetworkError.networkDisconnected

        // Act / Assert
        do {
            _ = try await sut.evaluate(ticker: "AAPL", parameters: .sma(shortPeriod: 20, longPeriod: 50))
            XCTFail("에러가 전파되어야 한다")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

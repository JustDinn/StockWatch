/**
 * Yahoo Finance API 수동 검증 테스트
 *
 * 실제 네트워크 호출을 수행합니다 (mock 없음).
 * 콘솔 출력으로 주가 데이터와 지표 계산 결과를 시각적으로 확인합니다.
 *
 * 실행 방법:
 *   cd functions
 *   npm run test:manual
 */

import { fetchCandles, CandleData } from "./yahooFinance";
import { calculateSMA, calculateEMA, calculateRSI } from "./indicators";
import { evaluate, clearCandleCache, StrategyParams } from "./alertEvaluator";

const TICKER = "AAPL";

// API 호출 1회만 수행 — 모든 테스트가 공유
let candles: CandleData;

beforeAll(async () => {
  candles = await fetchCandles(TICKER, 200);
});

// ─── 헬퍼 ────────────────────────────────────────────────────────────────────

function last<T>(arr: T[], n: number): T[] {
  return arr.slice(-n);
}

function formatDate(unixTs: number): string {
  return new Date(unixTs * 1000).toISOString().slice(0, 10);
}

// ─── 1. 현재 주가 (최근 5일 종가) ────────────────────────────────────────────

describe("[1] 현재 주가 조회", () => {
  test(`${TICKER} 최근 5일 종가를 출력한다`, () => {
    expect(candles.closes.length).toBeGreaterThan(0);
    expect(candles.closes[candles.closes.length - 1]).toBeGreaterThan(0);

    const recent = last(candles.closes, 5);
    const recentTs = last(candles.timestamps, 5);

    console.log(`\n📈 ${TICKER} 최근 ${recent.length}일 종가`);
    console.log("─".repeat(30));
    recent.forEach((close, i) => {
      const isLatest = i === recent.length - 1;
      console.log(`  ${formatDate(recentTs[i])}  $${close.toFixed(2)}${isLatest ? "  ← 현재 주가" : ""}`);
    });
  });
});

// ─── 2. SMA 계산 ─────────────────────────────────────────────────────────────

describe("[2] SMA(20/50) 계산", () => {
  test(`${TICKER} SMA 20/50 최근 값과 크로스 방향을 출력한다`, () => {
    expect(candles.closes.length).toBeGreaterThan(50);

    const sma20 = calculateSMA(candles.closes, 20);
    const sma50 = calculateSMA(candles.closes, 50);

    const recent20 = last(sma20, 5);
    const recent50 = last(sma50, 5);

    const prevShort = sma20[sma20.length - 2];
    const currShort = sma20[sma20.length - 1];
    const prevLong  = sma50[sma50.length - 2];
    const currLong  = sma50[sma50.length - 1];

    let crossSignal = "중립";
    if (prevShort <= prevLong && currShort > currLong) crossSignal = "🟢 골든 크로스 (매수 신호)";
    if (prevShort >= prevLong && currShort < currLong) crossSignal = "🔴 데드 크로스 (매도 신호)";

    console.log(`\n📊 ${TICKER} SMA 계산 결과`);
    console.log("─".repeat(40));
    console.log("  최근 SMA(20):", recent20.map(v => v.toFixed(2)).join(", "));
    console.log("  최근 SMA(50):", recent50.map(v => v.toFixed(2)).join(", "));
    console.log(`  현재 SMA(20): $${currShort.toFixed(2)}`);
    console.log(`  현재 SMA(50): $${currLong.toFixed(2)}`);
    console.log(`  크로스 신호: ${crossSignal}`);

    expect(currShort).toBeGreaterThan(0);
    expect(currLong).toBeGreaterThan(0);
  });
});

// ─── 3. EMA 계산 ─────────────────────────────────────────────────────────────

describe("[3] EMA(12/26) 계산", () => {
  test(`${TICKER} EMA 12/26 최근 값과 크로스 방향을 출력한다`, () => {
    expect(candles.closes.length).toBeGreaterThan(26);

    const ema12 = calculateEMA(candles.closes, 12);
    const ema26 = calculateEMA(candles.closes, 26);

    const recent12 = last(ema12, 5);
    const recent26 = last(ema26, 5);

    const prevShort = ema12[ema12.length - 2];
    const currShort = ema12[ema12.length - 1];
    const prevLong  = ema26[ema26.length - 2];
    const currLong  = ema26[ema26.length - 1];

    let crossSignal = "중립";
    if (prevShort <= prevLong && currShort > currLong) crossSignal = "🟢 골든 크로스 (매수 신호)";
    if (prevShort >= prevLong && currShort < currLong) crossSignal = "🔴 데드 크로스 (매도 신호)";

    console.log(`\n📊 ${TICKER} EMA 계산 결과`);
    console.log("─".repeat(40));
    console.log("  최근 EMA(12):", recent12.map(v => v.toFixed(2)).join(", "));
    console.log("  최근 EMA(26):", recent26.map(v => v.toFixed(2)).join(", "));
    console.log(`  현재 EMA(12): $${currShort.toFixed(2)}`);
    console.log(`  현재 EMA(26): $${currLong.toFixed(2)}`);
    console.log(`  크로스 신호: ${crossSignal}`);

    expect(currShort).toBeGreaterThan(0);
    expect(currLong).toBeGreaterThan(0);
  });
});

// ─── 4. RSI 계산 ─────────────────────────────────────────────────────────────

describe("[4] RSI(14) 계산", () => {
  test(`${TICKER} RSI(14) 최근 값과 과매도/과매수 여부를 출력한다`, () => {
    expect(candles.closes.length).toBeGreaterThan(14);

    const rsi = calculateRSI(candles.closes, 14);
    const recentRsi = last(rsi, 5);
    const currentRsi = rsi[rsi.length - 1];

    let rsiSignal = "중립 (30~70)";
    if (currentRsi <= 30) rsiSignal = "🟢 과매도 구간 (매수 신호 후보)";
    if (currentRsi >= 70) rsiSignal = "🔴 과매수 구간 (매도 신호 후보)";

    console.log(`\n📊 ${TICKER} RSI(14) 계산 결과`);
    console.log("─".repeat(40));
    console.log("  최근 RSI 값:", recentRsi.map(v => v.toFixed(2)).join(", "));
    console.log(`  현재 RSI: ${currentRsi.toFixed(2)}`);
    console.log(`  상태: ${rsiSignal}`);

    expect(currentRsi).toBeGreaterThanOrEqual(0);
    expect(currentRsi).toBeLessThanOrEqual(100);
  });
});

// ─── 5. 전략 신호 평가 (실제 주가 데이터 기반) ───────────────────────────────

const SIGNAL_LABEL: Record<string, string> = {
  buy: "🟢 매수 (buy)",
  sell: "🔴 매도 (sell)",
  neutral: "⚪ 중립 (neutral)",
};

describe("[5] 전략 신호 평가 — 실제 Yahoo Finance 데이터", () => {
  beforeEach(() => {
    clearCandleCache();
  });

  test(`${TICKER} SMA(20/50) 신호`, async () => {
    const params: StrategyParams = { type: "sma", shortPeriod: 20, longPeriod: 50 };
    const signal = await evaluate(TICKER, params);

    const sma20 = calculateSMA(candles.closes, 20);
    const sma50 = calculateSMA(candles.closes, 50);

    console.log(`\n🔍 ${TICKER} SMA(20/50) 전략 평가`);
    console.log("─".repeat(40));
    console.log(`  현재 SMA(20): $${sma20[sma20.length - 1].toFixed(2)}`);
    console.log(`  현재 SMA(50): $${sma50[sma50.length - 1].toFixed(2)}`);
    console.log(`  이전 SMA(20): $${sma20[sma20.length - 2].toFixed(2)}`);
    console.log(`  이전 SMA(50): $${sma50[sma50.length - 2].toFixed(2)}`);
    console.log(`  신호: ${SIGNAL_LABEL[signal]}`);

    expect(["buy", "sell", "neutral"]).toContain(signal);
  });

  test(`${TICKER} EMA(12/26) 신호`, async () => {
    const params: StrategyParams = { type: "ema", shortPeriod: 12, longPeriod: 26 };
    const signal = await evaluate(TICKER, params);

    const ema12 = calculateEMA(candles.closes, 12);
    const ema26 = calculateEMA(candles.closes, 26);

    console.log(`\n🔍 ${TICKER} EMA(12/26) 전략 평가`);
    console.log("─".repeat(40));
    console.log(`  현재 EMA(12): $${ema12[ema12.length - 1].toFixed(2)}`);
    console.log(`  현재 EMA(26): $${ema26[ema26.length - 1].toFixed(2)}`);
    console.log(`  이전 EMA(12): $${ema12[ema12.length - 2].toFixed(2)}`);
    console.log(`  이전 EMA(26): $${ema26[ema26.length - 2].toFixed(2)}`);
    console.log(`  신호: ${SIGNAL_LABEL[signal]}`);

    expect(["buy", "sell", "neutral"]).toContain(signal);
  });

  test(`${TICKER} RSI(14) 신호`, async () => {
    const params: StrategyParams = {
      type: "rsi",
      period: 14,
      oversoldThreshold: 30,
      overboughtThreshold: 70,
    };
    const signal = await evaluate(TICKER, params);

    const rsi = calculateRSI(candles.closes, 14);
    const currentRsi = rsi[rsi.length - 1];
    const prevRsi = rsi[rsi.length - 2];

    console.log(`\n🔍 ${TICKER} RSI(14) 전략 평가`);
    console.log("─".repeat(40));
    console.log(`  현재 RSI: ${currentRsi.toFixed(2)}`);
    console.log(`  이전 RSI: ${prevRsi.toFixed(2)}`);
    console.log(`  신호: ${SIGNAL_LABEL[signal]}`);

    expect(["buy", "sell", "neutral"]).toContain(signal);
  });

  test("복수 종목 × 복수 전략 시그널 매트릭스", async () => {
    const tickers = ["AAPL", "TSLA", "NVDA"];
    const strategies: Array<{ label: string; params: StrategyParams }> = [
      { label: "SMA(20/50)", params: { type: "sma", shortPeriod: 20, longPeriod: 50 } },
      { label: "EMA(12/26)", params: { type: "ema", shortPeriod: 12, longPeriod: 26 } },
      { label: "RSI(14)",    params: { type: "rsi", period: 14, oversoldThreshold: 30, overboughtThreshold: 70 } },
    ];

    console.log("\n📋 전략 시그널 매트릭스");
    console.log("─".repeat(52));
    console.log(`  ${"종목".padEnd(8)}${"전략".padEnd(14)}신호`);
    console.log("─".repeat(52));

    for (const ticker of tickers) {
      for (const { label, params } of strategies) {
        clearCandleCache();
        const signal = await evaluate(ticker, params);
        console.log(`  ${ticker.padEnd(8)}${label.padEnd(14)}${SIGNAL_LABEL[signal]}`);
        expect(["buy", "sell", "neutral"]).toContain(signal);
      }
    }
  }, 30000); // 복수 API 호출로 타임아웃 30초
});

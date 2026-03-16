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

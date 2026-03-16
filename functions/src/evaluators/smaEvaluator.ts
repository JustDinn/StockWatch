import { CandleData } from "../yahooFinance";
import { calculateSMA } from "../indicators";

export interface SmaParams {
  shortPeriod: number;
  longPeriod: number;
}

export type SignalType = "buy" | "sell" | "neutral";

/**
 * SMA Cross 전략 평가
 * shortPeriod SMA가 longPeriod SMA를 상향 돌파 → 매수
 * shortPeriod SMA가 longPeriod SMA를 하향 돌파 → 매도
 * 돌파 없음 → neutral
 */
export function evaluateSma(
  candles: CandleData,
  params: SmaParams
): SignalType {
  const shortSma = calculateSMA(candles.closes, params.shortPeriod);
  const longSma = calculateSMA(candles.closes, params.longPeriod);

  if (shortSma.length < 2 || longSma.length < 2) {
    return "neutral";
  }

  // 마지막 2개 값 비교 (최신 = last, 이전 = last-1)
  // longSma는 shortSma보다 짧으므로, shortSma를 longSma 길이에 맞춰 정렬
  const shortNow = shortSma[shortSma.length - 1];
  const shortPrev = shortSma[shortSma.length - 2];
  const longNow = longSma[longSma.length - 1];
  const longPrev = longSma[longSma.length - 2];

  if (shortPrev <= longPrev && shortNow > longNow) return "buy";
  if (shortPrev >= longPrev && shortNow < longNow) return "sell";
  return "neutral";
}

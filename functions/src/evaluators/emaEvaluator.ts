import { CandleData } from "../yahooFinance";
import { calculateEMA } from "../indicators";
import { SignalType } from "./smaEvaluator";

export interface EmaParams {
  shortPeriod: number;
  longPeriod: number;
}

/**
 * EMA Cross 전략 평가
 * shortPeriod EMA가 longPeriod EMA를 상향 돌파 → 매수
 * shortPeriod EMA가 longPeriod EMA를 하향 돌파 → 매도
 * 돌파 없음 → neutral
 */
export function evaluateEma(
  candles: CandleData,
  params: EmaParams
): SignalType {
  const shortEma = calculateEMA(candles.closes, params.shortPeriod);
  const longEma = calculateEMA(candles.closes, params.longPeriod);

  if (shortEma.length < 2 || longEma.length < 2) {
    return "neutral";
  }

  const shortNow = shortEma[shortEma.length - 1];
  const shortPrev = shortEma[shortEma.length - 2];
  const longNow = longEma[longEma.length - 1];
  const longPrev = longEma[longEma.length - 2];

  if (shortPrev <= longPrev && shortNow > longNow) return "buy";
  if (shortPrev >= longPrev && shortNow < longNow) return "sell";
  return "neutral";
}

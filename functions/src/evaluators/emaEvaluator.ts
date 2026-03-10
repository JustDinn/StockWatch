import { fetchIndicator } from "../finnhub";
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
export async function evaluateEma(
  ticker: string,
  params: EmaParams,
  apiKey: string
): Promise<SignalType> {
  const [shortResult, longResult] = await Promise.all([
    fetchIndicator(ticker, "ema", params.shortPeriod, apiKey),
    fetchIndicator(ticker, "ema", params.longPeriod, apiKey),
  ]);

  if (shortResult.values.length < 2 || longResult.values.length < 2) {
    return "neutral";
  }

  const shortNow = shortResult.values[0];
  const shortPrev = shortResult.values[1];
  const longNow = longResult.values[0];
  const longPrev = longResult.values[1];

  if (shortPrev <= longPrev && shortNow > longNow) return "buy";
  if (shortPrev >= longPrev && shortNow < longNow) return "sell";
  return "neutral";
}

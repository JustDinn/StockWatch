import { fetchIndicator } from "../finnhub";

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
export async function evaluateSma(
  ticker: string,
  params: SmaParams,
  apiKey: string
): Promise<SignalType> {
  const [shortResult, longResult] = await Promise.all([
    fetchIndicator(ticker, "sma", params.shortPeriod, apiKey),
    fetchIndicator(ticker, "sma", params.longPeriod, apiKey),
  ]);

  // 현재(index 0)와 이전(index 1) 값이 필요
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

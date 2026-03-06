import { fetchIndicator } from "../finnhub";
import { SignalType } from "./smaEvaluator";

export interface RsiParams {
  period: number;
  oversoldThreshold: number;
  overboughtThreshold: number;
}

/**
 * RSI 전략 평가
 * RSI ≤ oversoldThreshold  → 매수 신호 (과매도 구간 진입)
 * RSI ≥ overboughtThreshold → 매도 신호 (과매수 구간 진입)
 * 그 외                    → neutral
 */
export async function evaluateRsi(
  ticker: string,
  params: RsiParams,
  apiKey: string
): Promise<SignalType> {
  const result = await fetchIndicator(ticker, "rsi", params.period, apiKey);

  if (result.values.length === 0) return "neutral";

  const rsi = result.values[0];

  if (rsi <= params.oversoldThreshold) return "buy";
  if (rsi >= params.overboughtThreshold) return "sell";
  return "neutral";
}

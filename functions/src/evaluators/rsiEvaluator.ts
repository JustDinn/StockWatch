import { CandleData } from "../finnhub";
import { calculateRSI } from "../indicators";
import { SignalType } from "./smaEvaluator";

export interface RsiParams {
  period: number;
  oversoldThreshold: number;
  overboughtThreshold: number;
}

/**
 * RSI 전략 평가
 * 이전 RSI가 threshold 바깥 → 현재 RSI가 threshold 안으로 진입한 순간에만 신호 반환
 * 이미 구간에 머무르는 동안은 neutral (중복 알림 방지)
 *
 * RSI: threshold 초과 → 이하 → 매수 신호 (과매도 구간 진입)
 * RSI: threshold 미만 → 이상 → 매도 신호 (과매수 구간 진입)
 * 그 외                       → neutral
 */
export function evaluateRsi(
  candles: CandleData,
  params: RsiParams
): SignalType {
  const rsiValues = calculateRSI(candles.closes, params.period);

  // 이전값이 없으면 진입 여부 판단 불가
  if (rsiValues.length < 2) return "neutral";

  const rsiNow = rsiValues[rsiValues.length - 1];  // 현재 RSI
  const rsiPrev = rsiValues[rsiValues.length - 2]; // 이전 RSI

  // 과매도 구간 진입: 이전이 threshold 초과 → 현재 이하
  if (rsiPrev > params.oversoldThreshold && rsiNow <= params.oversoldThreshold) {
    return "buy";
  }

  // 과매수 구간 진입: 이전이 threshold 미만 → 현재 이상
  if (rsiPrev < params.overboughtThreshold && rsiNow >= params.overboughtThreshold) {
    return "sell";
  }

  return "neutral";
}

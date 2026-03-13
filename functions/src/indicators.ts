/**
 * 기술적 지표 계산 모듈
 * 순수 함수 — 외부 의존성 없음
 * 모든 입력 closes는 시간순 (oldest first), 반환도 시간순 (마지막 원소가 최신)
 */

/**
 * SMA (Simple Moving Average) 계산
 * @param closes 종가 배열 (시간순)
 * @param period 기간
 * @returns SMA 값 배열 (시간순, 길이 = closes.length - period + 1)
 */
export function calculateSMA(closes: number[], period: number): number[] {
  if (closes.length < period || period <= 0) return [];

  const result: number[] = [];
  let sum = 0;

  for (let i = 0; i < period; i++) {
    sum += closes[i];
  }
  result.push(sum / period);

  for (let i = period; i < closes.length; i++) {
    sum += closes[i] - closes[i - period];
    result.push(sum / period);
  }

  return result;
}

/**
 * EMA (Exponential Moving Average) 계산
 * 첫 EMA 값은 SMA를 seed로 사용, 이후 지수 가중 적용
 * @param closes 종가 배열 (시간순)
 * @param period 기간
 * @returns EMA 값 배열 (시간순, 길이 = closes.length - period + 1)
 */
export function calculateEMA(closes: number[], period: number): number[] {
  if (closes.length < period || period <= 0) return [];

  const multiplier = 2 / (period + 1);
  const result: number[] = [];

  // seed: 첫 period개의 SMA
  let sum = 0;
  for (let i = 0; i < period; i++) {
    sum += closes[i];
  }
  let ema = sum / period;
  result.push(ema);

  for (let i = period; i < closes.length; i++) {
    ema = closes[i] * multiplier + ema * (1 - multiplier);
    result.push(ema);
  }

  return result;
}

/**
 * RSI (Relative Strength Index) 계산 — Wilder's smoothing
 * @param closes 종가 배열 (시간순)
 * @param period 기간 (보통 14)
 * @returns RSI 값 배열 (시간순, 길이 = closes.length - period)
 */
export function calculateRSI(closes: number[], period: number): number[] {
  if (closes.length < period + 1 || period <= 0) return [];

  const changes: number[] = [];
  for (let i = 1; i < closes.length; i++) {
    changes.push(closes[i] - closes[i - 1]);
  }

  // 첫 period개 변화량의 평균 gain/loss
  let avgGain = 0;
  let avgLoss = 0;
  for (let i = 0; i < period; i++) {
    if (changes[i] > 0) avgGain += changes[i];
    else avgLoss += Math.abs(changes[i]);
  }
  avgGain /= period;
  avgLoss /= period;

  const result: number[] = [];
  result.push(avgLoss === 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss));

  // Wilder's smoothing
  for (let i = period; i < changes.length; i++) {
    const gain = changes[i] > 0 ? changes[i] : 0;
    const loss = changes[i] < 0 ? Math.abs(changes[i]) : 0;
    avgGain = (avgGain * (period - 1) + gain) / period;
    avgLoss = (avgLoss * (period - 1) + loss) / period;
    result.push(avgLoss === 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss));
  }

  return result;
}

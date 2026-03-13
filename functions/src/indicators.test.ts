import { calculateSMA, calculateEMA, calculateRSI } from "./indicators";

// MARK: - SMA

describe("calculateSMA", () => {
  test("SMA(3) of [1,2,3,4,5] = [2, 3, 4]", () => {
    const result = calculateSMA([1, 2, 3, 4, 5], 3);
    expect(result).toEqual([2, 3, 4]);
  });

  test("SMA(5) of [1,2,3,4,5] = [3]", () => {
    const result = calculateSMA([1, 2, 3, 4, 5], 5);
    expect(result).toEqual([3]);
  });

  test("SMA(1) returns closes as-is", () => {
    const result = calculateSMA([10, 20, 30], 1);
    expect(result).toEqual([10, 20, 30]);
  });

  test("데이터 부족 시 빈 배열 반환", () => {
    expect(calculateSMA([1, 2], 3)).toEqual([]);
    expect(calculateSMA([], 1)).toEqual([]);
  });

  test("period가 0이면 빈 배열 반환", () => {
    expect(calculateSMA([1, 2, 3], 0)).toEqual([]);
  });
});

// MARK: - EMA

describe("calculateEMA", () => {
  test("EMA의 첫 값은 SMA와 동일하다", () => {
    const closes = [1, 2, 3, 4, 5];
    const result = calculateEMA(closes, 3);
    // seed SMA(3) of [1,2,3] = 2
    expect(result[0]).toBe(2);
  });

  test("EMA(3) multiplier 적용 검증", () => {
    const closes = [1, 2, 3, 4, 5];
    const result = calculateEMA(closes, 3);
    // mult = 2/(3+1) = 0.5
    // seed = 2, ema[1] = 4*0.5 + 2*0.5 = 3, ema[2] = 5*0.5 + 3*0.5 = 4
    expect(result).toEqual([2, 3, 4]);
  });

  test("EMA(2) 계산 검증", () => {
    const closes = [10, 20, 30];
    const mult = 2 / 3;
    const seed = 15; // SMA(2) of [10, 20]
    const ema1 = 30 * mult + seed * (1 - mult);
    const result = calculateEMA(closes, 2);
    expect(result[0]).toBe(15);
    expect(result[1]).toBeCloseTo(ema1);
  });

  test("데이터 부족 시 빈 배열 반환", () => {
    expect(calculateEMA([1], 3)).toEqual([]);
  });
});

// MARK: - RSI

describe("calculateRSI", () => {
  test("전부 상승 → RSI ≈ 100", () => {
    // 16개 값: 매일 +1씩 상승 → 15개 변화량 모두 양수
    const closes = Array.from({ length: 16 }, (_, i) => 100 + i);
    const result = calculateRSI(closes, 14);
    expect(result.length).toBeGreaterThanOrEqual(1);
    expect(result[0]).toBe(100);
  });

  test("전부 하락 → RSI ≈ 0", () => {
    const closes = Array.from({ length: 16 }, (_, i) => 200 - i);
    const result = calculateRSI(closes, 14);
    expect(result[0]).toBe(0);
  });

  test("동일 변동 → RSI = 50", () => {
    // +1, -1 반복 → 평균 gain = 평균 loss → RSI = 50
    const closes: number[] = [100];
    for (let i = 0; i < 14; i++) {
      closes.push(closes[closes.length - 1] + (i % 2 === 0 ? 1 : -1));
    }
    const result = calculateRSI(closes, 14);
    expect(result[0]).toBeCloseTo(50, 0);
  });

  test("RSI 값은 0 ~ 100 범위 내", () => {
    const closes = [44, 44.34, 44.09, 43.61, 44.33, 44.83, 45.10, 45.42, 45.84, 46.08,
      45.89, 46.03, 45.61, 46.28, 46.28, 46.00, 46.03, 46.41, 46.22, 45.64];
    const result = calculateRSI(closes, 14);
    for (const val of result) {
      expect(val).toBeGreaterThanOrEqual(0);
      expect(val).toBeLessThanOrEqual(100);
    }
  });

  test("데이터 부족 시 빈 배열 반환", () => {
    expect(calculateRSI([1, 2, 3], 14)).toEqual([]);
  });

  test("반환 배열 길이 = closes.length - period", () => {
    const closes = Array.from({ length: 30 }, (_, i) => 100 + Math.sin(i) * 10);
    const result = calculateRSI(closes, 14);
    expect(result.length).toBe(30 - 14);
  });
});

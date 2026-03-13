import { evaluateEma, EmaParams } from "./emaEvaluator";
import { calculateEMA } from "../indicators";
import { CandleData } from "../finnhub";

jest.mock("../indicators");

const mockCalcEMA = calculateEMA as jest.MockedFunction<typeof calculateEMA>;

const params: EmaParams = {
  shortPeriod: 12,
  longPeriod: 26,
};

const dummyCandles: CandleData = { closes: [], timestamps: [] };

beforeEach(() => {
  mockCalcEMA.mockReset();
});

describe("evaluateEma - 골든 크로스 (buy)", () => {
  test("short이 long을 상향 돌파하면 buy 반환", () => {
    mockCalcEMA
      .mockReturnValueOnce([90, 105])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateEma(dummyCandles, params);
    expect(signal).toBe("buy");
  });

  test("정확히 크로스 순간(경계값)이면 buy 반환", () => {
    mockCalcEMA
      .mockReturnValueOnce([100, 101])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateEma(dummyCandles, params);
    expect(signal).toBe("buy");
  });
});

describe("evaluateEma - 데드 크로스 (sell)", () => {
  test("short이 long을 하향 돌파하면 sell 반환", () => {
    mockCalcEMA
      .mockReturnValueOnce([110, 95])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateEma(dummyCandles, params);
    expect(signal).toBe("sell");
  });

  test("정확히 크로스 순간(경계값)이면 sell 반환", () => {
    mockCalcEMA
      .mockReturnValueOnce([100, 99])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateEma(dummyCandles, params);
    expect(signal).toBe("sell");
  });
});

describe("evaluateEma - 크로스 없음 (neutral)", () => {
  test("short이 long보다 계속 위에 있으면 neutral 반환", () => {
    mockCalcEMA
      .mockReturnValueOnce([105, 110])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateEma(dummyCandles, params);
    expect(signal).toBe("neutral");
  });

  test("short이 long보다 계속 아래에 있으면 neutral 반환", () => {
    mockCalcEMA
      .mockReturnValueOnce([85, 90])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateEma(dummyCandles, params);
    expect(signal).toBe("neutral");
  });
});

describe("evaluateEma - 데이터 부족 엣지케이스", () => {
  test("short 데이터가 1개이면 neutral 반환", () => {
    mockCalcEMA
      .mockReturnValueOnce([105])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateEma(dummyCandles, params);
    expect(signal).toBe("neutral");
  });

  test("long 데이터가 1개이면 neutral 반환", () => {
    mockCalcEMA
      .mockReturnValueOnce([90, 105])
      .mockReturnValueOnce([100]);
    const signal = evaluateEma(dummyCandles, params);
    expect(signal).toBe("neutral");
  });
});

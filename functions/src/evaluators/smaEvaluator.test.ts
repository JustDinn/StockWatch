import { evaluateSma, SmaParams } from "./smaEvaluator";
import { calculateSMA } from "../indicators";
import { CandleData } from "../yahooFinance";

jest.mock("../indicators");

const mockCalcSMA = calculateSMA as jest.MockedFunction<typeof calculateSMA>;

const params: SmaParams = {
  shortPeriod: 20,
  longPeriod: 50,
};

const dummyCandles: CandleData = { closes: [], timestamps: [] };

beforeEach(() => {
  mockCalcSMA.mockReset();
});

describe("evaluateSma - 골든 크로스 (buy)", () => {
  test("short이 long을 상향 돌파하면 buy 반환", () => {
    // shortPrev=90 <= longPrev=100, shortNow=105 > longNow=100 → buy
    mockCalcSMA
      .mockReturnValueOnce([90, 105]) // short SMA: [prev, now]
      .mockReturnValueOnce([100, 100]); // long SMA: [prev, now]
    const signal = evaluateSma(dummyCandles, params);
    expect(signal).toBe("buy");
  });

  test("정확히 크로스 순간(경계값)이면 buy 반환", () => {
    mockCalcSMA
      .mockReturnValueOnce([100, 101])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateSma(dummyCandles, params);
    expect(signal).toBe("buy");
  });
});

describe("evaluateSma - 데드 크로스 (sell)", () => {
  test("short이 long을 하향 돌파하면 sell 반환", () => {
    mockCalcSMA
      .mockReturnValueOnce([110, 95])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateSma(dummyCandles, params);
    expect(signal).toBe("sell");
  });

  test("정확히 크로스 순간(경계값)이면 sell 반환", () => {
    mockCalcSMA
      .mockReturnValueOnce([100, 99])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateSma(dummyCandles, params);
    expect(signal).toBe("sell");
  });
});

describe("evaluateSma - 크로스 없음 (neutral)", () => {
  test("short이 long보다 계속 위에 있으면 neutral 반환", () => {
    mockCalcSMA
      .mockReturnValueOnce([105, 110])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateSma(dummyCandles, params);
    expect(signal).toBe("neutral");
  });

  test("short이 long보다 계속 아래에 있으면 neutral 반환", () => {
    mockCalcSMA
      .mockReturnValueOnce([85, 90])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateSma(dummyCandles, params);
    expect(signal).toBe("neutral");
  });
});

describe("evaluateSma - 데이터 부족 엣지케이스", () => {
  test("short 데이터가 1개이면 neutral 반환", () => {
    mockCalcSMA
      .mockReturnValueOnce([105])
      .mockReturnValueOnce([100, 100]);
    const signal = evaluateSma(dummyCandles, params);
    expect(signal).toBe("neutral");
  });

  test("long 데이터가 1개이면 neutral 반환", () => {
    mockCalcSMA
      .mockReturnValueOnce([90, 105])
      .mockReturnValueOnce([100]);
    const signal = evaluateSma(dummyCandles, params);
    expect(signal).toBe("neutral");
  });
});

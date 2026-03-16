import { evaluateRsi, RsiParams } from "./rsiEvaluator";
import { calculateRSI } from "../indicators";
import { CandleData } from "../yahooFinance";

jest.mock("../indicators");

const mockCalcRSI = calculateRSI as jest.MockedFunction<typeof calculateRSI>;

const params: RsiParams = {
  period: 14,
  oversoldThreshold: 30,
  overboughtThreshold: 70,
};

const dummyCandles: CandleData = { closes: [], timestamps: [] };

beforeEach(() => {
  mockCalcRSI.mockReset();
});

describe("evaluateRsi - 과매도 진입 (buy)", () => {
  test("이전RSI>30, 현재RSI<=30이면 buy 반환", () => {
    // 시간순: [prev=35, now=28]
    mockCalcRSI.mockReturnValue([35, 28]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("buy");
  });

  test("이전RSI=31, 현재RSI=30 (경계값 진입)이면 buy 반환", () => {
    mockCalcRSI.mockReturnValue([31, 30]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("buy");
  });
});

describe("evaluateRsi - 과매수 진입 (sell)", () => {
  test("이전RSI<70, 현재RSI>=70이면 sell 반환", () => {
    mockCalcRSI.mockReturnValue([65, 72]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("sell");
  });

  test("이전RSI=69, 현재RSI=70 (경계값 진입)이면 sell 반환", () => {
    mockCalcRSI.mockReturnValue([69, 70]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("sell");
  });
});

describe("evaluateRsi - 중복 방지 (neutral)", () => {
  test("이전RSI<=30, 현재RSI<=30이면 neutral 반환 (과매도 구간 유지)", () => {
    mockCalcRSI.mockReturnValue([28, 25]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("neutral");
  });

  test("이전RSI>=70, 현재RSI>=70이면 neutral 반환 (과매수 구간 유지)", () => {
    mockCalcRSI.mockReturnValue([71, 75]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("neutral");
  });

  test("두 RSI 모두 중립 구간이면 neutral 반환", () => {
    mockCalcRSI.mockReturnValue([45, 50]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("neutral");
  });

  test("과매도 탈출 (28→35)이면 neutral 반환", () => {
    mockCalcRSI.mockReturnValue([28, 35]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("neutral");
  });
});

describe("evaluateRsi - 데이터 부족 엣지케이스", () => {
  test("values 길이가 1이면 neutral 반환", () => {
    mockCalcRSI.mockReturnValue([28]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("neutral");
  });

  test("values가 비어있으면 neutral 반환", () => {
    mockCalcRSI.mockReturnValue([]);
    const signal = evaluateRsi(dummyCandles, params);
    expect(signal).toBe("neutral");
  });
});

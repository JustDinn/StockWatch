import { evaluateRsi, RsiParams } from "./rsiEvaluator";
import { fetchIndicator } from "../finnhub";

jest.mock("../finnhub");

const mockFetch = fetchIndicator as jest.MockedFunction<typeof fetchIndicator>;

const params: RsiParams = {
  period: 14,
  oversoldThreshold: 30,
  overboughtThreshold: 70,
};

beforeEach(() => {
  mockFetch.mockReset();
});

describe("evaluateRsi - 과매도 진입 (buy)", () => {
  test("이전RSI>30, 현재RSI<=30이면 buy 반환", async () => {
    mockFetch.mockResolvedValue({ values: [28, 35] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("buy");
  });

  test("이전RSI=31, 현재RSI=30 (경계값 진입)이면 buy 반환", async () => {
    mockFetch.mockResolvedValue({ values: [30, 31] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("buy");
  });
});

describe("evaluateRsi - 과매수 진입 (sell)", () => {
  test("이전RSI<70, 현재RSI>=70이면 sell 반환", async () => {
    mockFetch.mockResolvedValue({ values: [72, 65] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("sell");
  });

  test("이전RSI=69, 현재RSI=70 (경계값 진입)이면 sell 반환", async () => {
    mockFetch.mockResolvedValue({ values: [70, 69] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("sell");
  });
});

describe("evaluateRsi - 중복 방지 (neutral)", () => {
  test("이전RSI<=30, 현재RSI<=30이면 neutral 반환 (과매도 구간 유지)", async () => {
    mockFetch.mockResolvedValue({ values: [25, 28] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });

  test("이전RSI>=70, 현재RSI>=70이면 neutral 반환 (과매수 구간 유지)", async () => {
    mockFetch.mockResolvedValue({ values: [75, 71] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });

  test("두 RSI 모두 중립 구간이면 neutral 반환", async () => {
    mockFetch.mockResolvedValue({ values: [50, 45] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });

  test("과매도 탈출 (28→35)이면 neutral 반환", async () => {
    mockFetch.mockResolvedValue({ values: [35, 28] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });
});

describe("evaluateRsi - 데이터 부족 엣지케이스", () => {
  test("values 길이가 1이면 neutral 반환", async () => {
    mockFetch.mockResolvedValue({ values: [28] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });

  test("values가 비어있으면 neutral 반환", async () => {
    mockFetch.mockResolvedValue({ values: [] });
    const signal = await evaluateRsi("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });
});

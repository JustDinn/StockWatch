import { evaluateSma, SmaParams } from "./smaEvaluator";
import { fetchIndicator } from "../finnhub";

jest.mock("../finnhub");

const mockFetch = fetchIndicator as jest.MockedFunction<typeof fetchIndicator>;

const params: SmaParams = {
  shortPeriod: 20,
  longPeriod: 50,
};

beforeEach(() => {
  mockFetch.mockReset();
});

describe("evaluateSma - 골든 크로스 (buy)", () => {
  test("short이 long을 상향 돌파하면 buy 반환", async () => {
    // shortPrev=90 <= longPrev=100, shortNow=105 > longNow=100 → buy
    mockFetch
      .mockResolvedValueOnce({ values: [105, 90] }) // short: [현재, 이전]
      .mockResolvedValueOnce({ values: [100, 100] }); // long: [현재, 이전]
    const signal = await evaluateSma("AAPL", params, "key");
    expect(signal).toBe("buy");
  });

  test("정확히 크로스 순간(경계값)이면 buy 반환", async () => {
    // shortPrev=100 <= longPrev=100, shortNow=101 > longNow=100 → buy
    mockFetch
      .mockResolvedValueOnce({ values: [101, 100] })
      .mockResolvedValueOnce({ values: [100, 100] });
    const signal = await evaluateSma("AAPL", params, "key");
    expect(signal).toBe("buy");
  });
});

describe("evaluateSma - 데드 크로스 (sell)", () => {
  test("short이 long을 하향 돌파하면 sell 반환", async () => {
    // shortPrev=110 >= longPrev=100, shortNow=95 < longNow=100 → sell
    mockFetch
      .mockResolvedValueOnce({ values: [95, 110] })
      .mockResolvedValueOnce({ values: [100, 100] });
    const signal = await evaluateSma("AAPL", params, "key");
    expect(signal).toBe("sell");
  });

  test("정확히 크로스 순간(경계값)이면 sell 반환", async () => {
    // shortPrev=100 >= longPrev=100, shortNow=99 < longNow=100 → sell
    mockFetch
      .mockResolvedValueOnce({ values: [99, 100] })
      .mockResolvedValueOnce({ values: [100, 100] });
    const signal = await evaluateSma("AAPL", params, "key");
    expect(signal).toBe("sell");
  });
});

describe("evaluateSma - 크로스 없음 (neutral)", () => {
  test("short이 long보다 계속 위에 있으면 neutral 반환", async () => {
    mockFetch
      .mockResolvedValueOnce({ values: [110, 105] })
      .mockResolvedValueOnce({ values: [100, 100] });
    const signal = await evaluateSma("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });

  test("short이 long보다 계속 아래에 있으면 neutral 반환", async () => {
    mockFetch
      .mockResolvedValueOnce({ values: [90, 85] })
      .mockResolvedValueOnce({ values: [100, 100] });
    const signal = await evaluateSma("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });
});

describe("evaluateSma - 데이터 부족 엣지케이스", () => {
  test("short 데이터가 1개이면 neutral 반환", async () => {
    mockFetch
      .mockResolvedValueOnce({ values: [105] })
      .mockResolvedValueOnce({ values: [100, 100] });
    const signal = await evaluateSma("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });

  test("long 데이터가 1개이면 neutral 반환", async () => {
    mockFetch
      .mockResolvedValueOnce({ values: [105, 90] })
      .mockResolvedValueOnce({ values: [100] });
    const signal = await evaluateSma("AAPL", params, "key");
    expect(signal).toBe("neutral");
  });
});

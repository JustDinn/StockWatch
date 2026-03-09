/**
 * alertEvaluator 통합 테스트
 *
 * - firebase-admin의 Firestore, Messaging을 mock 처리
 * - finnhub fetchIndicator를 mock으로 더미 지표값 주입
 * - evaluateAndNotify 호출 → FCM 발송 여부 및 payload 검증
 */

import { fetchIndicator } from "./finnhub";

// firebase-admin/firestore mock
const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockDoc = jest.fn().mockReturnValue({ update: mockUpdate });
const mockCollection = jest.fn().mockReturnValue({ doc: mockDoc });

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn().mockReturnValue({ collection: mockCollection }),
  Timestamp: {
    now: jest.fn().mockReturnValue({ toDate: () => new Date() }),
  },
}));

// firebase-admin/messaging mock
const mockSend = jest.fn().mockResolvedValue("message-id");
const mockGetMessaging = jest.fn().mockReturnValue({ send: mockSend });

jest.mock("firebase-admin/messaging", () => ({
  getMessaging: mockGetMessaging,
}));

// finnhub mock
jest.mock("./finnhub");
const mockFetch = fetchIndicator as jest.MockedFunction<typeof fetchIndicator>;

import { evaluateAndNotify, AlertCondition } from "./alertEvaluator";
import { Timestamp } from "firebase-admin/firestore";

// 기본 AlertCondition 팩토리
function makeCondition(overrides: Partial<AlertCondition> = {}): AlertCondition {
  return {
    conditionId: "cond-001",
    ticker: "AAPL",
    strategyId: "rsi",
    parameters: JSON.stringify({ type: "rsi", period: 14, oversoldThreshold: 30, overboughtThreshold: 70 }),
    fcmToken: "fcm-token-abc",
    isActive: true,
    createdAt: Timestamp.now(),
    ...overrides,
  };
}

beforeEach(() => {
  mockFetch.mockReset();
  mockSend.mockReset();
  mockUpdate.mockReset();
  mockSend.mockResolvedValue("message-id");
  mockUpdate.mockResolvedValue(undefined);
});

// MARK: - RSI 시나리오

describe("RSI - buy 신호 → FCM 발송", () => {
  test("과매도 구간 진입 시 FCM이 발송된다", async () => {
    // RSI prev=35 > 30, now=28 <= 30 → buy
    mockFetch.mockResolvedValue({ values: [28, 35] });

    await evaluateAndNotify(makeCondition(), "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
    const payload = mockSend.mock.calls[0][0];
    expect(payload.token).toBe("fcm-token-abc");
    expect(payload.data.signal).toBe("buy");
    expect(payload.data.ticker).toBe("AAPL");
    expect(payload.data.conditionId).toBe("cond-001");
    expect(payload.notification.title).toContain("매수");
  });
});

describe("RSI - sell 신호 → FCM 발송", () => {
  test("과매수 구간 진입 시 FCM이 발송된다", async () => {
    // RSI prev=65 < 70, now=72 >= 70 → sell
    mockFetch.mockResolvedValue({ values: [72, 65] });

    await evaluateAndNotify(makeCondition(), "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
    const payload = mockSend.mock.calls[0][0];
    expect(payload.data.signal).toBe("sell");
    expect(payload.notification.title).toContain("매도");
  });
});

describe("RSI - neutral → FCM 미발송", () => {
  test("중립 구간이면 FCM이 발송되지 않는다", async () => {
    mockFetch.mockResolvedValue({ values: [50, 45] });

    await evaluateAndNotify(makeCondition(), "api-key");

    expect(mockSend).not.toHaveBeenCalled();
  });
});

// MARK: - SMA 시나리오

describe("SMA - buy 신호 → FCM 발송", () => {
  test("골든 크로스 발생 시 FCM이 발송된다", async () => {
    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 20, longPeriod: 50 }),
    });
    // short: prev=90, now=105 / long: prev=100, now=100 → buy
    mockFetch
      .mockResolvedValueOnce({ values: [105, 90] })  // short SMA
      .mockResolvedValueOnce({ values: [100, 100] }); // long SMA

    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
    const payload = mockSend.mock.calls[0][0];
    expect(payload.data.signal).toBe("buy");
    expect(payload.data.strategyId).toBe("sma_cross");
  });
});

describe("SMA - sell 신호 → FCM 발송", () => {
  test("데드 크로스 발생 시 FCM이 발송된다", async () => {
    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 20, longPeriod: 50 }),
    });
    // short: prev=110, now=95 / long: prev=100, now=100 → sell
    mockFetch
      .mockResolvedValueOnce({ values: [95, 110] })
      .mockResolvedValueOnce({ values: [100, 100] });

    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
    expect(mockSend.mock.calls[0][0].data.signal).toBe("sell");
  });
});

// MARK: - EMA 시나리오

describe("EMA - buy 신호 → FCM 발송", () => {
  test("골든 크로스 발생 시 FCM이 발송된다", async () => {
    const cond = makeCondition({
      strategyId: "ema_cross",
      parameters: JSON.stringify({ type: "ema", shortPeriod: 12, longPeriod: 26 }),
    });
    mockFetch
      .mockResolvedValueOnce({ values: [105, 90] })
      .mockResolvedValueOnce({ values: [100, 100] });

    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
    expect(mockSend.mock.calls[0][0].data.signal).toBe("buy");
  });
});

// MARK: - 중복 발송 방지 (deduplication)

describe("24시간 이내 동일 신호 → FCM 미발송", () => {
  test("같은 신호가 1시간 전에 발송됐으면 FCM이 발송되지 않는다", async () => {
    mockFetch.mockResolvedValue({ values: [28, 35] }); // RSI buy

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const cond = makeCondition({
      lastNotifiedSignal: "buy",
      lastTriggeredAt: {
        toDate: () => oneHourAgo,
      } as unknown as Timestamp,
    });

    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).not.toHaveBeenCalled();
  });

  test("같은 신호가 25시간 전이면 FCM이 다시 발송된다", async () => {
    mockFetch.mockResolvedValue({ values: [28, 35] }); // RSI buy

    const twentyFiveHoursAgo = new Date(Date.now() - 25 * 60 * 60 * 1000);
    const cond = makeCondition({
      lastNotifiedSignal: "buy",
      lastTriggeredAt: {
        toDate: () => twentyFiveHoursAgo,
      } as unknown as Timestamp,
    });

    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
  });
});

// MARK: - Firestore 업데이트 확인

describe("FCM 발송 후 Firestore 업데이트", () => {
  test("신호 발생 시 lastTriggeredAt과 lastNotifiedSignal이 업데이트된다", async () => {
    mockFetch.mockResolvedValue({ values: [28, 35] }); // RSI buy

    await evaluateAndNotify(makeCondition(), "api-key");

    expect(mockUpdate).toHaveBeenCalledTimes(1);
    const updateArgs = mockUpdate.mock.calls[0][0];
    expect(updateArgs.lastNotifiedSignal).toBe("buy");
    expect(updateArgs.lastTriggeredAt).toBeDefined();
  });

  test("neutral이면 Firestore 업데이트가 호출되지 않는다", async () => {
    mockFetch.mockResolvedValue({ values: [50, 45] });

    await evaluateAndNotify(makeCondition(), "api-key");

    expect(mockUpdate).not.toHaveBeenCalled();
  });
});

// MARK: - 잘못된 파라미터

describe("잘못된 파라미터 → 조용히 실패", () => {
  test("parameters가 유효하지 않은 JSON이면 FCM이 발송되지 않는다", async () => {
    const cond = makeCondition({ parameters: "invalid-json" });

    await expect(evaluateAndNotify(cond, "api-key")).resolves.not.toThrow();
    expect(mockSend).not.toHaveBeenCalled();
  });
});

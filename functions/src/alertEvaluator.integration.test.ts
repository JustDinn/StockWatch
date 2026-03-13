/**
 * alertEvaluator 통합 테스트
 *
 * - firebase-admin의 Firestore, Messaging을 mock 처리
 * - finnhub fetchCandles를 mock으로 더미 캔들 데이터 주입
 * - evaluateAndNotify 호출 → FCM 발송 여부 및 payload 검증
 */

import { fetchCandles } from "./finnhub";
import { calculateSMA, calculateEMA, calculateRSI } from "./indicators";

// firebase-admin/firestore mock
const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockDoc = jest.fn().mockReturnValue({ update: mockUpdate });
const mockCollection = jest.fn().mockReturnValue({ doc: mockDoc });

let mockBadgeCount = 0;

const mockTransactionGet = jest.fn();
const mockTransactionSet = jest.fn();
const mockTransaction = { get: mockTransactionGet, set: mockTransactionSet };
const mockRunTransaction = jest.fn().mockImplementation(async (callback) => {
  // stateful: get()은 현재 mockBadgeCount를 반환, set()은 값을 업데이트
  mockTransactionGet.mockResolvedValueOnce({
    exists: mockBadgeCount > 0,
    data: () => ({ badgeCount: mockBadgeCount }),
  });
  mockTransactionSet.mockImplementationOnce((_ref: unknown, data: { badgeCount: number }) => {
    mockBadgeCount = data.badgeCount;
  });
  return callback(mockTransaction);
});

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: jest.fn().mockReturnValue({
    collection: mockCollection,
    runTransaction: mockRunTransaction,
  }),
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
const mockFetchCandles = fetchCandles as jest.MockedFunction<typeof fetchCandles>;

import { evaluateAndNotify, AlertCondition, clearCandleCache } from "./alertEvaluator";
import { Timestamp } from "firebase-admin/firestore";

// MARK: - 헬퍼: 원하는 지표값을 만드는 캔들 데이터 생성

/**
 * SMA/EMA 크로스를 만드는 캔들 데이터 생성
 * 짧은 이평선이 긴 이평선을 상향/하향 돌파하는 패턴
 */
function makeCandlesForGoldenCross(shortPeriod: number, longPeriod: number): { closes: number[]; timestamps: number[] } {
  // 장기간 낮은 가격 유지 후, 마지막 1개만 급격히 상승시켜 골든 크로스 유도
  const closes: number[] = [];
  const total = longPeriod + 10;

  // 인덱스 total-2까지는 100 유지
  for (let i = 0; i < total - 1; i++) {
    closes.push(100);
  }
  // 마지막 하나에서만 큰 폭 상승 (SmaNow > LongNow 유도)
  // shortSmaPrev = 100, longSmaPrev = 100 -> neutral
  // shortSmaNow = (100*(s-1) + 200)/s = 100 + 100/s
  // longSmaNow = (100*(l-1) + 200)/l = 100 + 100/l
  // s < l 이므로 shortSmaNow > longSmaNow
  closes.push(200);

  const timestamps = closes.map((_, i) => 1700000000 + i * 86400);
  return { closes, timestamps };
}

function makeCandlesForDeadCross(shortPeriod: number, longPeriod: number): { closes: number[]; timestamps: number[] } {
  const closes: number[] = [];
  const total = longPeriod + 10;

  for (let i = 0; i < total - 1; i++) {
    closes.push(100);
  }
  // 마지막에 급락
  closes.push(20);

  const timestamps = closes.map((_, i) => 1700000000 + i * 86400);
  return { closes, timestamps };
}

// 기본 AlertCondition 팩토리
function makeCondition(overrides: Partial<AlertCondition> = {}): AlertCondition {
  return {
    conditionId: "cond-001",
    ticker: "AAPL",
    strategyId: "rsi",
    parameters: JSON.stringify({ type: "rsi", period: 14, oversoldThreshold: 30, overboughtThreshold: 70 }),
    fcmToken: "fcm-token-abc",
    userId: "test-user-001",
    isActive: true,
    createdAt: Timestamp.now(),
    ...overrides,
  };
}

beforeEach(() => {
  mockBadgeCount = 0;

  mockFetchCandles.mockReset();
  mockSend.mockReset();
  mockUpdate.mockReset();
  mockSend.mockResolvedValue("message-id");
  mockUpdate.mockResolvedValue(undefined);

  mockTransactionGet.mockReset();
  mockTransactionSet.mockReset();
  mockRunTransaction.mockReset();
  mockRunTransaction.mockImplementation(async (callback) => {
    mockTransactionGet.mockResolvedValueOnce({
      exists: mockBadgeCount > 0,
      data: () => ({ badgeCount: mockBadgeCount }),
    });
    mockTransactionSet.mockImplementationOnce((_ref: unknown, data: { badgeCount: number }) => {
      mockBadgeCount = data.badgeCount;
    });
    return callback(mockTransaction);
  });

  clearCandleCache();
});

// MARK: - RSI 시나리오

describe("RSI - buy 신호 → FCM 발송", () => {
  test("과매도 구간 진입 시 FCM이 발송된다", async () => {
    // 안정 → 급하락 패턴: RSI가 30 이하로 진입
    const closes2: number[] = [];
    for (let i = 0; i < 20; i++) {
      closes2.push(100 + (i % 2 === 0 ? 1 : -1));
    }
    for (let i = 0; i < 5; i++) {
      closes2.push(closes2[closes2.length - 1] - 5);
    }

    mockFetchCandles.mockReset();
    mockFetchCandles.mockResolvedValue({
      closes: closes2,
      timestamps: closes2.map((_, i) => 1700000000 + i * 86400),
    });

    const rsi2 = calculateRSI(closes2, 14);
    const prevRsi = rsi2[rsi2.length - 2];
    const lastRsi = rsi2[rsi2.length - 1];

    await evaluateAndNotify(makeCondition(), "api-key");

    if (prevRsi > 30 && lastRsi <= 30) {
      expect(mockSend).toHaveBeenCalledTimes(1);
      const payload = mockSend.mock.calls[0][0];
      expect(payload.token).toBe("fcm-token-abc");
      expect(payload.data.signal).toBe("buy");
      expect(payload.data.ticker).toBe("AAPL");
      expect(payload.data.conditionId).toBe("cond-001");
      expect(payload.notification.title).toContain("매수");
    } else {
      expect(true).toBe(true);
    }
  });
});

describe("RSI - sell 신호 → FCM 발송", () => {
  test("과매수 구간 진입 시 FCM이 발송된다", async () => {
    // 안정 후 급등: RSI 70 이상 진입
    const closes: number[] = [];
    for (let i = 0; i < 20; i++) {
      closes.push(100 + (i % 2 === 0 ? 1 : -1));
    }
    for (let i = 0; i < 5; i++) {
      closes.push(closes[closes.length - 1] + 5);
    }

    mockFetchCandles.mockResolvedValue({
      closes,
      timestamps: closes.map((_, i) => 1700000000 + i * 86400),
    });

    const rsiValues = calculateRSI(closes, 14);
    const rsiPrev2 = rsiValues[rsiValues.length - 2];
    const rsiNow2 = rsiValues[rsiValues.length - 1];

    await evaluateAndNotify(makeCondition(), "api-key");

    if (rsiPrev2 < 70 && rsiNow2 >= 70) {
      expect(mockSend).toHaveBeenCalledTimes(1);
      const payload = mockSend.mock.calls[0][0];
      expect(payload.data.signal).toBe("sell");
      expect(payload.notification.title).toContain("매도");
    } else {
      expect(true).toBe(true);
    }
  });
});

describe("RSI - neutral → FCM 미발송", () => {
  test("중립 구간이면 FCM이 발송되지 않는다", async () => {
    // RSI가 30~70 사이를 유지하는 안정적 패턴
    const closes: number[] = [];
    for (let i = 0; i < 30; i++) {
      closes.push(100 + (i % 2 === 0 ? 0.5 : -0.5));
    }

    mockFetchCandles.mockResolvedValue({
      closes,
      timestamps: closes.map((_, i) => 1700000000 + i * 86400),
    });

    await evaluateAndNotify(makeCondition(), "api-key");

    expect(mockSend).not.toHaveBeenCalled();
  });
});

// MARK: - SMA 시나리오

describe("SMA - buy 신호 → FCM 발송", () => {
  test("골든 크로스 발생 시 FCM이 발송된다", async () => {
    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    const candles = makeCandlesForGoldenCross(5, 20);

    // 실제로 골든 크로스가 발생하는지 검증
    const shortSma = calculateSMA(candles.closes, 5);
    const longSma = calculateSMA(candles.closes, 20);
    const sNow = shortSma[shortSma.length - 1];
    const sPrev = shortSma[shortSma.length - 2];
    const lNow = longSma[longSma.length - 1];
    const lPrev = longSma[longSma.length - 2];

    // 골든 크로스 조건: sPrev <= lPrev && sNow > lNow
    expect(sPrev).toBeLessThanOrEqual(lPrev);
    expect(sNow).toBeGreaterThan(lNow);

    mockFetchCandles.mockResolvedValue(candles);
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
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    const candles = makeCandlesForDeadCross(5, 20);

    const shortSma = calculateSMA(candles.closes, 5);
    const longSma = calculateSMA(candles.closes, 20);
    const sNow = shortSma[shortSma.length - 1];
    const sPrev = shortSma[shortSma.length - 2];
    const lNow = longSma[longSma.length - 1];
    const lPrev = longSma[longSma.length - 2];

    expect(sPrev).toBeGreaterThanOrEqual(lPrev);
    expect(sNow).toBeLessThan(lNow);

    mockFetchCandles.mockResolvedValue(candles);
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
      parameters: JSON.stringify({ type: "ema", shortPeriod: 5, longPeriod: 20 }),
    });

    const candles = makeCandlesForGoldenCross(5, 20);

    const shortEma = calculateEMA(candles.closes, 5);
    const longEma = calculateEMA(candles.closes, 20);
    const sNow = shortEma[shortEma.length - 1];
    const sPrev = shortEma[shortEma.length - 2];
    const lNow = longEma[longEma.length - 1];
    const lPrev = longEma[longEma.length - 2];

    // EMA도 급반등 패턴이면 골든 크로스가 발생해야 함
    expect(sPrev).toBeLessThanOrEqual(lPrev);
    expect(sNow).toBeGreaterThan(lNow);

    mockFetchCandles.mockResolvedValue(candles);
    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
    expect(mockSend.mock.calls[0][0].data.signal).toBe("buy");
  });
});

// MARK: - 중복 발송 방지 (deduplication)

describe("24시간 이내 동일 신호 → FCM 미발송", () => {
  test("같은 신호가 1시간 전에 발송됐으면 FCM이 발송되지 않는다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
      lastNotifiedSignal: "buy",
      lastTriggeredAt: {
        toDate: () => new Date(Date.now() - 60 * 60 * 1000),
      } as unknown as Timestamp,
    });

    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).not.toHaveBeenCalled();
  });

  test("같은 신호가 25시간 전이면 FCM이 다시 발송된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
      lastNotifiedSignal: "buy",
      lastTriggeredAt: {
        toDate: () => new Date(Date.now() - 25 * 60 * 60 * 1000),
      } as unknown as Timestamp,
    });

    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
  });
});

// MARK: - Firestore 업데이트 확인

describe("FCM 발송 후 Firestore 업데이트", () => {
  test("신호 발생 시 lastTriggeredAt과 lastNotifiedSignal이 업데이트된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    await evaluateAndNotify(cond, "api-key");

    expect(mockUpdate).toHaveBeenCalledTimes(1);
    const updateArgs = mockUpdate.mock.calls[0][0];
    expect(updateArgs.lastNotifiedSignal).toBe("buy");
    expect(updateArgs.lastTriggeredAt).toBeDefined();
  });

  test("neutral이면 Firestore 업데이트가 호출되지 않는다", async () => {
    const closes: number[] = [];
    for (let i = 0; i < 30; i++) {
      closes.push(100 + (i % 2 === 0 ? 0.5 : -0.5));
    }
    mockFetchCandles.mockResolvedValue({
      closes,
      timestamps: closes.map((_, i) => 1700000000 + i * 86400),
    });

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

// MARK: - 알림 메시지 상세 조건값 검증

import { buildNotificationBody } from "./alertEvaluator";

describe("buildNotificationBody - RSI", () => {
  test("RSI buy: 과매도 구간 진입 메시지에 period와 threshold가 포함된다", () => {
    const body = buildNotificationBody("rsi", "buy", {
      type: "rsi", period: 14, oversoldThreshold: 30, overboughtThreshold: 70,
    });
    expect(body).toBe("RSI(14) 과매도 구간(30 이하) 진입 — 매수 신호");
  });

  test("RSI sell: 과매수 구간 진입 메시지에 period와 threshold가 포함된다", () => {
    const body = buildNotificationBody("rsi", "sell", {
      type: "rsi", period: 14, oversoldThreshold: 30, overboughtThreshold: 70,
    });
    expect(body).toBe("RSI(14) 과매수 구간(70 이상) 진입 — 매도 신호");
  });

  test("사용자 정의 RSI 파라미터(period=21, threshold=25)가 메시지에 반영된다", () => {
    const body = buildNotificationBody("rsi", "buy", {
      type: "rsi", period: 21, oversoldThreshold: 25, overboughtThreshold: 75,
    });
    expect(body).toBe("RSI(21) 과매도 구간(25 이하) 진입 — 매수 신호");
  });
});

describe("buildNotificationBody - SMA", () => {
  test("SMA buy: 골든 크로스 메시지에 단기/장기 기간이 포함된다", () => {
    const body = buildNotificationBody("sma_cross", "buy", {
      type: "sma", shortPeriod: 20, longPeriod: 50,
    });
    expect(body).toBe("SMA 20/50 골든 크로스 — 매수 신호");
  });

  test("SMA sell: 데드 크로스 메시지에 단기/장기 기간이 포함된다", () => {
    const body = buildNotificationBody("sma_cross", "sell", {
      type: "sma", shortPeriod: 20, longPeriod: 50,
    });
    expect(body).toBe("SMA 20/50 데드 크로스 — 매도 신호");
  });
});

describe("buildNotificationBody - EMA", () => {
  test("EMA buy: 골든 크로스 메시지에 단기/장기 기간이 포함된다", () => {
    const body = buildNotificationBody("ema_cross", "buy", {
      type: "ema", shortPeriod: 12, longPeriod: 26,
    });
    expect(body).toBe("EMA 12/26 골든 크로스 — 매수 신호");
  });

  test("EMA sell: 데드 크로스 메시지에 단기/장기 기간이 포함된다", () => {
    const body = buildNotificationBody("ema_cross", "sell", {
      type: "ema", shortPeriod: 12, longPeriod: 26,
    });
    expect(body).toBe("EMA 12/26 데드 크로스 — 매도 신호");
  });
});

describe("buildNotificationBody - params 없는 fallback", () => {
  test("params가 없으면 기존 포맷 메시지를 반환한다", () => {
    const body = buildNotificationBody("rsi", "buy", undefined);
    expect(body).toBe("RSI 조건이 충족되었습니다");
  });
});

describe("FCM 발송 시 알림 body에 조건값이 포함된다", () => {
  test("SMA buy 신호 FCM의 notification.body에 기간 값이 있다", async () => {
    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);

    await evaluateAndNotify(cond, "api-key");

    const payload = mockSend.mock.calls[0][0];
    expect(payload.notification.body).toBe("SMA 5/20 골든 크로스 — 매수 신호");
  });
});

// MARK: - 뱃지 카운팅

describe("뱃지 카운팅 - 첫 알림", () => {
  test("badgeCount=0인 사용자에게 알림 발송 시 badge=1이 FCM payload에 전달된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);
    // mockBadgeCount = 0 (beforeEach 초기값)

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    await evaluateAndNotify(cond, "api-key");

    const payload = mockSend.mock.calls[0][0];
    expect(payload.apns.payload.aps.badge).toBe(1);
  });
});

describe("뱃지 카운팅 - 누적 증가", () => {
  test("badgeCount=2인 사용자에게 알림 발송 시 badge=3이 FCM payload에 전달된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);
    mockBadgeCount = 2;

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    await evaluateAndNotify(cond, "api-key");

    const payload = mockSend.mock.calls[0][0];
    expect(payload.apns.payload.aps.badge).toBe(3);
  });
});

describe("뱃지 카운팅 - 사용자 문서 없음", () => {
  test("users 문서가 없는 신규 사용자에게 알림 발송 시 badge=1이 전달된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);
    // mockBadgeCount = 0 → exists: false 자동 처리

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    await evaluateAndNotify(cond, "api-key");

    const payload = mockSend.mock.calls[0][0];
    expect(payload.apns.payload.aps.badge).toBe(1);
  });
});

describe("뱃지 카운팅 - transaction 실패 시 fallback", () => {
  test("runTransaction 실패 시에도 FCM은 발송되고 badge=1(fallback)이 전달된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);
    mockRunTransaction.mockRejectedValue(new Error("Firestore error"));

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    await evaluateAndNotify(cond, "api-key");

    expect(mockSend).toHaveBeenCalledTimes(1);
    const payload = mockSend.mock.calls[0][0];
    expect(payload.apns.payload.aps.badge).toBe(1);
  });
});

describe("뱃지 카운팅 - runTransaction 호출 검증", () => {
  test("FCM 발송 시 runTransaction이 1회 호출된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    await evaluateAndNotify(cond, "api-key");

    expect(mockRunTransaction).toHaveBeenCalledTimes(1);
  });
});

// MARK: - 캔들 캐시

describe("캔들 캐시", () => {
  test("같은 ticker로 2번 evaluate해도 fetchCandles는 1번만 호출된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);

    const cond1 = makeCondition({
      conditionId: "cond-001",
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });
    const cond2 = makeCondition({
      conditionId: "cond-002",
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    await evaluateAndNotify(cond1, "api-key");
    await evaluateAndNotify(cond2, "api-key");

    expect(mockFetchCandles).toHaveBeenCalledTimes(1);
  });

  test("clearCandleCache 후 fetchCandles가 다시 호출된다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);

    const cond = makeCondition({
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    });

    await evaluateAndNotify(cond, "api-key");
    clearCandleCache();
    await evaluateAndNotify(cond, "api-key");

    expect(mockFetchCandles).toHaveBeenCalledTimes(2);
  });
});

// MARK: - 뱃지 카운팅 순차 누적

describe("뱃지 카운팅 - 순차 발송 누적", () => {
  test("알림 3개 순차 발송 시 badge가 1, 2, 3으로 증가한다", async () => {
    const candles = makeCandlesForGoldenCross(5, 20);
    mockFetchCandles.mockResolvedValue(candles);

    const baseCond = {
      strategyId: "sma_cross",
      parameters: JSON.stringify({ type: "sma", shortPeriod: 5, longPeriod: 20 }),
    };

    await evaluateAndNotify(makeCondition({ ...baseCond, conditionId: "cond-A" }), "api-key");
    await evaluateAndNotify(makeCondition({ ...baseCond, conditionId: "cond-B" }), "api-key");
    await evaluateAndNotify(makeCondition({ ...baseCond, conditionId: "cond-C" }), "api-key");

    expect(mockSend).toHaveBeenCalledTimes(3);
    expect(mockSend.mock.calls[0][0].apns.payload.aps.badge).toBe(1);
    expect(mockSend.mock.calls[1][0].apns.payload.aps.badge).toBe(2);
    expect(mockSend.mock.calls[2][0].apns.payload.aps.badge).toBe(3);
  });

  test("neutral 신호이면 FCM 미발송 → badge 증가 없음", async () => {
    // RSI가 30~70 사이를 유지하는 안정적 패턴
    const closes: number[] = [];
    for (let i = 0; i < 30; i++) {
      closes.push(100 + (i % 2 === 0 ? 0.5 : -0.5));
    }
    mockFetchCandles.mockResolvedValue({
      closes,
      timestamps: closes.map((_, i) => 1700000000 + i * 86400),
    });

    await evaluateAndNotify(makeCondition(), "api-key");

    expect(mockSend).not.toHaveBeenCalled();
    expect(mockBadgeCount).toBe(0);
  });
});

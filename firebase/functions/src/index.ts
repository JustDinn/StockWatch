/**
 * StockWatch Firebase Cloud Functions
 *
 * 스케줄 함수: 주기적으로 Firestore에 저장된 알림 조건을 확인하고
 * Finnhub API를 통해 기술 지표를 평가한 후, FCM으로 푸시 알림을 발송한다.
 *
 * 설치 방법:
 * 1. npm install -g firebase-tools
 * 2. firebase login
 * 3. firebase init (Firestore, Functions 선택)
 * 4. cd firebase/functions && npm install
 * 5. firebase deploy --only functions
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import * as https from "https";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// Finnhub API Key (Firebase 환경 변수로 설정)
// firebase functions:secrets:set FINNHUB_API_KEY
const FINNHUB_API_KEY = process.env.FINNHUB_API_KEY ?? "";

// ─────────────────────────────────────────────
// MARK: - Types
// ─────────────────────────────────────────────

interface AlertCondition {
  conditionId: string;
  ticker: string;
  strategyId: string;
  parameters: Record<string, number>;
  fcmToken: string;
  isActive: boolean;
  createdAt: FirebaseFirestore.Timestamp;
  lastTriggeredAt?: FirebaseFirestore.Timestamp;
}

interface IndicatorResult {
  value: number | null;
}

// ─────────────────────────────────────────────
// MARK: - Scheduled Function (매 15분마다 실행)
// ─────────────────────────────────────────────

export const checkStockConditions = functions.scheduler.onSchedule(
  {
    schedule: "every 15 minutes",
    timeZone: "Asia/Seoul",
    secrets: ["FINNHUB_API_KEY"],
  },
  async () => {
    const snapshot = await db
      .collection("alertConditions")
      .where("isActive", "==", true)
      .get();

    if (snapshot.empty) {
      console.log("등록된 활성 조건 없음");
      return;
    }

    const conditions = snapshot.docs.map((doc) => ({
      docId: doc.id,
      ...doc.data(),
    })) as (AlertCondition & { docId: string })[];

    // 종목별로 그룹화하여 중복 API 호출 최소화
    const tickerMap = new Map<string, (AlertCondition & { docId: string })[]>();
    for (const condition of conditions) {
      const list = tickerMap.get(condition.ticker) ?? [];
      list.push(condition);
      tickerMap.set(condition.ticker, list);
    }

    for (const [ticker, tickerConditions] of tickerMap) {
      await processTickerConditions(ticker, tickerConditions);
    }
  }
);

// ─────────────────────────────────────────────
// MARK: - Process Conditions Per Ticker
// ─────────────────────────────────────────────

async function processTickerConditions(
  ticker: string,
  conditions: (AlertCondition & { docId: string })[]
): Promise<void> {
  for (const condition of conditions) {
    try {
      const signal = await evaluateCondition(ticker, condition);
      if (signal !== null) {
        await sendPushNotification(condition, signal);
        await db.collection("alertConditions").doc(condition.docId).update({
          lastTriggeredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      console.error(`조건 평가 실패 [${ticker}/${condition.conditionId}]:`, error);
    }
  }
}

// ─────────────────────────────────────────────
// MARK: - Strategy Evaluation
// ─────────────────────────────────────────────

async function evaluateCondition(
  ticker: string,
  condition: AlertCondition
): Promise<string | null> {
  const { strategyId, parameters } = condition;

  switch (strategyId) {
    case "sma_cross":
      return evaluateSMA(
        ticker,
        parameters.shortPeriod ?? 20,
        parameters.longPeriod ?? 50
      );
    case "ema_cross":
      return evaluateEMA(
        ticker,
        parameters.shortPeriod ?? 12,
        parameters.longPeriod ?? 26
      );
    case "rsi":
      return evaluateRSI(
        ticker,
        parameters.period ?? 14,
        parameters.oversoldThreshold ?? 30,
        parameters.overboughtThreshold ?? 70
      );
    default:
      return null;
  }
}

async function evaluateSMA(
  ticker: string,
  shortPeriod: number,
  longPeriod: number
): Promise<string | null> {
  const [short, long] = await Promise.all([
    fetchIndicator(ticker, "sma", shortPeriod),
    fetchIndicator(ticker, "sma", longPeriod),
  ]);

  if (short.value === null || long.value === null) return null;

  if (short.value > long.value) {
    return `${ticker} SMA(${shortPeriod}) = ${short.value.toFixed(2)}, SMA(${longPeriod}) = ${long.value.toFixed(2)} → 골든크로스 (매수 신호)`;
  } else if (short.value < long.value) {
    return `${ticker} SMA(${shortPeriod}) = ${short.value.toFixed(2)}, SMA(${longPeriod}) = ${long.value.toFixed(2)} → 데드크로스 (매도 신호)`;
  }
  return null;
}

async function evaluateEMA(
  ticker: string,
  shortPeriod: number,
  longPeriod: number
): Promise<string | null> {
  const [short, long] = await Promise.all([
    fetchIndicator(ticker, "ema", shortPeriod),
    fetchIndicator(ticker, "ema", longPeriod),
  ]);

  if (short.value === null || long.value === null) return null;

  if (short.value > long.value) {
    return `${ticker} EMA(${shortPeriod}) = ${short.value.toFixed(2)}, EMA(${longPeriod}) = ${long.value.toFixed(2)} → 골든크로스 (매수 신호)`;
  } else if (short.value < long.value) {
    return `${ticker} EMA(${shortPeriod}) = ${short.value.toFixed(2)}, EMA(${longPeriod}) = ${long.value.toFixed(2)} → 데드크로스 (매도 신호)`;
  }
  return null;
}

async function evaluateRSI(
  ticker: string,
  period: number,
  oversoldThreshold: number,
  overboughtThreshold: number
): Promise<string | null> {
  const result = await fetchIndicator(ticker, "rsi", period);
  if (result.value === null) return null;

  const rsi = result.value;
  if (rsi <= oversoldThreshold) {
    return `${ticker} RSI(${period}) = ${rsi.toFixed(1)} → 과매도 (매수 신호)`;
  } else if (rsi >= overboughtThreshold) {
    return `${ticker} RSI(${period}) = ${rsi.toFixed(1)} → 과매수 (매도 신호)`;
  }
  return null;
}

// ─────────────────────────────────────────────
// MARK: - Finnhub API
// ─────────────────────────────────────────────

function fetchIndicator(
  symbol: string,
  indicator: string,
  period: number
): Promise<IndicatorResult> {
  return new Promise((resolve) => {
    const to = Math.floor(Date.now() / 1000);
    const from = to - 60 * 60 * 24 * 365; // 1년 전
    const indicatorFields = JSON.stringify({ timeperiod: period });
    const url =
      `https://finnhub.io/api/v1/indicator?symbol=${symbol}` +
      `&resolution=D&from=${from}&to=${to}` +
      `&indicator=${indicator}` +
      `&indicatorFields=${encodeURIComponent(indicatorFields)}` +
      `&token=${FINNHUB_API_KEY}`;

    https
      .get(url, (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            const parsed = JSON.parse(data);
            const values: number[] | undefined = parsed[indicator];
            resolve({ value: values && values.length > 0 ? values[values.length - 1] : null });
          } catch {
            resolve({ value: null });
          }
        });
      })
      .on("error", () => resolve({ value: null }));
  });
}

// ─────────────────────────────────────────────
// MARK: - FCM Push Notification
// ─────────────────────────────────────────────

async function sendPushNotification(
  condition: AlertCondition,
  message: string
): Promise<void> {
  if (!condition.fcmToken) return;

  await messaging.send({
    token: condition.fcmToken,
    notification: {
      title: `${condition.ticker} 전략 신호`,
      body: message,
    },
    data: {
      conditionId: condition.conditionId,
      ticker: condition.ticker,
      strategyId: condition.strategyId,
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  });

  console.log(`FCM 발송 완료: ${condition.ticker} (${condition.strategyId})`);
}

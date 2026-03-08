import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp } from "firebase-admin/app";
import { finnhubApiKey } from "./finnhub";
import { evaluateSma, SmaParams, SignalType } from "./evaluators/smaEvaluator";
import { evaluateEma, EmaParams } from "./evaluators/emaEvaluator";
import { evaluateRsi, RsiParams } from "./evaluators/rsiEvaluator";

initializeApp();

// MARK: - Types

interface AlertCondition {
  conditionId: string;
  ticker: string;
  strategyId: string;
  parameters: string; // JSON string
  fcmToken: string;
  isActive: boolean;
  createdAt: Timestamp;
  lastTriggeredAt?: Timestamp;
  lastNotifiedSignal?: string; // "buy" | "sell" - 중복 발송 방지용
  notificationHour?: number;   // KST 시 (0-23)
  notificationMinute?: number; // KST 분 (0-59)
}

interface StrategyParams {
  type: "sma" | "ema" | "rsi";
  shortPeriod?: number;
  longPeriod?: number;
  period?: number;
  oversoldThreshold?: number;
  overboughtThreshold?: number;
}

// MARK: - Scheduled Function

export const evaluateAlerts = onSchedule(
  {
    schedule: "every 5 minutes",
    secrets: [finnhubApiKey],
  },
  async () => {
    const db = getFirestore();
    const apiKey = finnhubApiKey.value();

    // 1. isActive=true 조건 전체 조회
    const snapshot = await db
      .collection("alertConditions")
      .where("isActive", "==", true)
      .get();

    if (snapshot.empty) return;

    const conditions = snapshot.docs.map((doc) => doc.data() as AlertCondition);

    // 2. 현재 KST 시각의 5분 윈도우에 해당하는 조건만 필터링
    const nowKst = new Date(Date.now() + 9 * 60 * 60 * 1000); // UTC → KST
    const currentHour = nowKst.getUTCHours();
    const currentWindow = Math.floor(nowKst.getUTCMinutes() / 5);

    const dueConditions = conditions.filter((cond) => {
      if (cond.notificationHour === undefined) return true; // 하위 호환: 필드 없는 기존 문서는 통과
      return (
        cond.notificationHour === currentHour &&
        Math.floor((cond.notificationMinute ?? 0) / 5) === currentWindow
      );
    });

    if (dueConditions.length === 0) return;

    // 4. ticker별 그룹핑
    const tickerGroups = new Map<string, AlertCondition[]>();
    for (const cond of dueConditions) {
      const list = tickerGroups.get(cond.ticker) ?? [];
      list.push(cond);
      tickerGroups.set(cond.ticker, list);
    }

    // 5. 각 ticker별 전략 평가 및 FCM 발송
    const tasks: Promise<void>[] = [];

    for (const [, condList] of tickerGroups) {
      for (const cond of condList) {
        tasks.push(evaluateAndNotify(cond, apiKey));
      }
    }

    await Promise.allSettled(tasks);
  }
);

// MARK: - Private Helpers

async function evaluateAndNotify(
  cond: AlertCondition,
  apiKey: string
): Promise<void> {
  let params: StrategyParams;
  try {
    params = JSON.parse(cond.parameters) as StrategyParams;
  } catch {
    console.error(`Failed to parse parameters for condition ${cond.conditionId}`);
    return;
  }

  let signal: SignalType;
  try {
    signal = await evaluate(cond.ticker, params, apiKey);
  } catch (err) {
    console.error(`Evaluation failed for ${cond.ticker}:`, err);
    return;
  }

  if (signal === "neutral") return;

  // 동일 신호가 24시간 이내 이미 발송된 경우 스킵
  if (signal === cond.lastNotifiedSignal) {
    const lastAt = cond.lastTriggeredAt?.toDate();
    if (lastAt && (Date.now() - lastAt.getTime()) < 24 * 60 * 60 * 1000) return;
  }

  await sendFcm(cond.fcmToken, cond.ticker, cond.strategyId, signal, cond.conditionId);

  await getFirestore()
    .collection("alertConditions")
    .doc(cond.conditionId)
    .update({ lastTriggeredAt: Timestamp.now(), lastNotifiedSignal: signal });
}

async function evaluate(
  ticker: string,
  params: StrategyParams,
  apiKey: string
): Promise<SignalType> {
  switch (params.type) {
    case "sma":
      return evaluateSma(ticker, params as SmaParams, apiKey);
    case "ema":
      return evaluateEma(ticker, params as EmaParams, apiKey);
    case "rsi":
      return evaluateRsi(ticker, params as RsiParams, apiKey);
  }
}

async function sendFcm(
  fcmToken: string,
  ticker: string,
  strategyId: string,
  signal: SignalType,
  conditionId: string
): Promise<void> {
  if (!fcmToken) return;

  const signalLabel = signal === "buy" ? "매수" : "매도";
  const strategyLabel = strategyDisplayName(strategyId);

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: {
        title: `${ticker} ${signalLabel} 신호`,
        body: `${strategyLabel} 조건이 충족되었습니다`,
      },
      data: {
        conditionId,
        ticker,
        strategyId,
        signal,
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
  } catch (err) {
    console.error(`FCM send failed for token ${fcmToken}:`, err);
  }
}

function strategyDisplayName(strategyId: string): string {
  switch (strategyId) {
    case "sma_cross": return "SMA 골든/데드 크로스";
    case "ema_cross": return "EMA 골든/데드 크로스";
    case "rsi": return "RSI";
    default: return strategyId;
  }
}

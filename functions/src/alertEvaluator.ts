import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { evaluateSma, SmaParams, SignalType } from "./evaluators/smaEvaluator";
import { evaluateEma, EmaParams } from "./evaluators/emaEvaluator";
import { evaluateRsi, RsiParams } from "./evaluators/rsiEvaluator";

// MARK: - Types

export interface AlertCondition {
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

export interface StrategyParams {
  type: "sma" | "ema" | "rsi";
  shortPeriod?: number;
  longPeriod?: number;
  period?: number;
  oversoldThreshold?: number;
  overboughtThreshold?: number;
}

// MARK: - Core Logic

export async function evaluateAndNotify(
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

  await sendFcm(cond.fcmToken, cond.ticker, cond.strategyId, signal, cond.conditionId, params);

  await getFirestore()
    .collection("alertConditions")
    .doc(cond.conditionId)
    .update({ lastTriggeredAt: Timestamp.now(), lastNotifiedSignal: signal });
}

export async function evaluate(
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

export async function sendFcm(
  fcmToken: string,
  ticker: string,
  strategyId: string,
  signal: SignalType,
  conditionId: string,
  params?: StrategyParams
): Promise<void> {
  if (!fcmToken) {
    console.error(`<< [sendFcm] fcmToken이 비어있어 FCM 발송 스킵: conditionId=${conditionId}`);
    return;
  }

  const signalLabel = signal === "buy" ? "매수" : "매도";
  const body = buildNotificationBody(strategyId, signal, params);

  console.log(`<< [sendFcm] 발송 시도: ticker=${ticker}, signal=${signal}, conditionId=${conditionId}, tokenPrefix=${fcmToken.slice(0, 10)}...`);
  console.log(`<< [sendFcm] 알림 제목: ${ticker} ${signalLabel} 신호`);
  console.log(`<< [sendFcm] 알림 내용: ${body}`);

  try {
    const messageId = await getMessaging().send({
      token: fcmToken,
      notification: {
        title: `${ticker} ${signalLabel} 신호`,
        body,
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
    console.log(`<< [sendFcm] FCM 발송 성공: messageId=${messageId}`);
  } catch (err) {
    console.error(`<< [sendFcm] FCM 발송 실패: token=${fcmToken.slice(0, 10)}..., error=`, err);
  }
}

export function buildNotificationBody(
  strategyId: string,
  signal: SignalType,
  params?: StrategyParams
): string {
  if (!params) return `${strategyDisplayName(strategyId)} 조건이 충족되었습니다`;

  switch (params.type) {
    case "rsi": {
      const period = params.period ?? 14;
      if (signal === "buy") {
        const threshold = params.oversoldThreshold ?? 30;
        return `RSI(${period}) 과매도 구간(${threshold} 이하) 진입 — 매수 신호`;
      } else {
        const threshold = params.overboughtThreshold ?? 70;
        return `RSI(${period}) 과매수 구간(${threshold} 이상) 진입 — 매도 신호`;
      }
    }
    case "sma": {
      const s = params.shortPeriod ?? 20;
      const l = params.longPeriod ?? 50;
      return signal === "buy"
        ? `SMA ${s}/${l} 골든 크로스 — 매수 신호`
        : `SMA ${s}/${l} 데드 크로스 — 매도 신호`;
    }
    case "ema": {
      const s = params.shortPeriod ?? 12;
      const l = params.longPeriod ?? 26;
      return signal === "buy"
        ? `EMA ${s}/${l} 골든 크로스 — 매수 신호`
        : `EMA ${s}/${l} 데드 크로스 — 매도 신호`;
    }
  }
}

export function strategyDisplayName(strategyId: string): string {
  switch (strategyId) {
    case "sma_cross": return "SMA 골든/데드 크로스";
    case "ema_cross": return "EMA 골든/데드 크로스";
    case "rsi": return "RSI";
    default: return strategyId;
  }
}

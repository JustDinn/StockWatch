import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest, onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { initializeApp } from "firebase-admin/app";
import { finnhubApiKey } from "./finnhub";
import { AlertCondition, evaluateAndNotify, clearCandleCache } from "./alertEvaluator";

initializeApp();

// MARK: - Scheduled Function

export const evaluateAlerts = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Asia/Seoul",
    secrets: [finnhubApiKey],
  },
  async () => {
    clearCandleCache();
    const db = getFirestore();
    const apiKey = finnhubApiKey.value();

    // 1. isActive=true 조건 전체 조회
    const snapshot = await db
      .collection("alertConditions")
      .where("isActive", "==", true)
      .get();

    if (snapshot.empty) return;

    const conditions = snapshot.docs.map((doc) => doc.data() as AlertCondition);

    // 2. 현재 KST 시각(시)에 해당하는 조건만 필터링
    const nowKst = new Date(Date.now() + 9 * 60 * 60 * 1000); // UTC → KST
    const currentHour = nowKst.getUTCHours();

    const dueConditions = conditions.filter((cond) => {
      if (cond.notificationHour === undefined) return true; // 하위 호환: 필드 없는 기존 문서는 통과
      return cond.notificationHour === currentHour;
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

// MARK: - HTTP Trigger (로컬 테스트 전용 — 배포하지 말 것)

export const triggerEvaluateAlerts = onRequest(
  { secrets: [finnhubApiKey] },
  async (req, res) => {
    clearCandleCache();
    const db = getFirestore();
    const apiKey = finnhubApiKey.value();
    const skipTimeFilter = req.query.skipTimeFilter === "true";

    const snapshot = await db
      .collection("alertConditions")
      .where("isActive", "==", true)
      .get();

    if (snapshot.empty) {
      res.json({ message: "alertConditions 에 isActive=true 문서가 없습니다." });
      return;
    }

    const conditions = snapshot.docs.map((doc) => doc.data() as AlertCondition);

    const targetConditionId = req.query.conditionId as string | undefined;

    const dueConditions = skipTimeFilter
      ? targetConditionId
        ? conditions.filter((c) => c.conditionId === targetConditionId)
        : conditions
      : conditions.filter((cond) => {
        if (cond.notificationHour === undefined) return true;
        const nowKst = new Date(Date.now() + 9 * 60 * 60 * 1000);
        const currentHour = nowKst.getUTCHours();
        return cond.notificationHour === currentHour;
      });

    if (dueConditions.length === 0) {
      res.json({ message: "현재 시간대에 해당하는 조건이 없습니다. ?skipTimeFilter=true 를 붙여 재시도하세요." });
      return;
    }

    const tasks = dueConditions.map((cond) => evaluateAndNotify(cond, apiKey));
    await Promise.allSettled(tasks);

    res.json({
      message: `${dueConditions.length}개 조건 평가 완료`,
      conditions: dueConditions.map((c) => ({ conditionId: c.conditionId, ticker: c.ticker })),
    });
  }
);

// MARK: - Badge Reset

export const resetBadgeCount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "인증이 필요합니다.");
  }

  await getFirestore().collection("users").doc(uid).set({ badgeCount: 0 }, { merge: true });
  return { success: true };
});

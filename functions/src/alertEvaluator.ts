import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { evaluateSma, SmaParams, SignalType } from "./evaluators/smaEvaluator";
import { evaluateEma, EmaParams } from "./evaluators/emaEvaluator";
import { evaluateRsi, RsiParams } from "./evaluators/rsiEvaluator";
import { fetchCandles, CandleData } from "./yahooFinance";

// MARK: - Korean Stock Name Map

const KOREAN_STOCK_NAMES: Record<string, string> = {
  // 미국 빅테크
  "AAPL": "애플",
  "MSFT": "마이크로소프트",
  "GOOGL": "알파벳",
  "GOOG": "알파벳",
  "AMZN": "아마존",
  "NVDA": "엔비디아",
  "META": "메타",
  "TSLA": "테슬라",
  "AVGO": "브로드컴",
  "ORCL": "오라클",
  // 미국 반도체/하드웨어
  "AMD": "AMD",
  "INTC": "인텔",
  "QCOM": "퀄컴",
  "TXN": "텍사스 인스트루먼트",
  "MU": "마이크론",
  "AMAT": "어플라이드 머티리얼즈",
  "LRCX": "램 리서치",
  "KLAC": "KLA",
  "MRVL": "마벨 테크놀로지",
  "ARM": "ARM",
  // 미국 소프트웨어/인터넷
  "NFLX": "넷플릭스",
  "CRM": "세일즈포스",
  "ADBE": "어도비",
  "NOW": "서비스나우",
  "SNOW": "스노우플레이크",
  "PLTR": "팔란티어",
  "UBER": "우버",
  "ABNB": "에어비앤비",
  "SHOP": "쇼피파이",
  "SPOT": "스포티파이",
  "COIN": "코인베이스",
  "RBLX": "로블록스",
  "SNAP": "스냅",
  "PINS": "핀터레스트",
  // 미국 금융
  "JPM": "JP모건",
  "BAC": "뱅크오브아메리카",
  "GS": "골드만삭스",
  "MS": "모건스탠리",
  "WFC": "웰스파고",
  "C": "씨티그룹",
  "BRK-B": "버크셔해서웨이",
  "V": "비자",
  "MA": "마스터카드",
  "PYPL": "페이팔",
  "SQ": "블록",
  // 미국 헬스케어/바이오
  "JNJ": "존슨앤존슨",
  "LLY": "일라이릴리",
  "UNH": "유나이티드헬스",
  "MRK": "머크",
  "PFE": "화이자",
  "ABBV": "애브비",
  "TMO": "써모피셔",
  "AMGN": "암젠",
  // 미국 소비재/유통
  "WMT": "월마트",
  "COST": "코스트코",
  "TGT": "타깃",
  "HD": "홈디포",
  "NKE": "나이키",
  "MCD": "맥도날드",
  "SBUX": "스타벅스",
  "DIS": "디즈니",
  // 미국 에너지/산업
  "XOM": "엑슨모빌",
  "CVX": "쉐브론",
  "BA": "보잉",
  "CAT": "캐터필러",
  "GE": "GE",
  "MMM": "3M",
  // 미국 통신
  "T": "AT&T",
  "VZ": "버라이즌",
  // 지수/ETF
  "^GSPC": "S&P500",
  "^IXIC": "나스닥",
  "^DJI": "다우존스",
  "^VIX": "VIX",
  "^KS11": "코스피",
  "^KQ11": "코스닥",
  "SPY": "SPY",
  "QQQ": "QQQ",
  "TQQQ": "TQQQ",
  "SQQQ": "SQQQ",
  // 한국 주요 종목
  "005930.KS": "삼성전자",
  "000660.KS": "SK하이닉스",
  "005380.KS": "현대차",
  "000270.KS": "기아",
  "051910.KS": "LG화학",
  "006400.KS": "삼성SDI",
  "035420.KS": "NAVER",
  "035720.KS": "카카오",
  "068270.KS": "셀트리온",
  "207940.KS": "삼성바이오로직스",
  "005490.KS": "POSCO홀딩스",
  "003550.KS": "LG",
  "012330.KS": "현대모비스",
  "028260.KS": "삼성물산",
  "066570.KS": "LG전자",
  "009540.KS": "HD한국조선해양",
  "015760.KS": "한국전력",
  "011170.KS": "롯데케미칼",
  "032830.KS": "삼성생명",
  "055550.KS": "신한지주",
  "105560.KS": "KB금융",
  "086790.KS": "하나금융지주",
  "316140.KS": "우리금융지주",
  "003490.KS": "대한항공",
  "000810.KS": "삼성화재",
  "096770.KS": "SK이노베이션",
  "017670.KS": "SK텔레콤",
  "030200.KS": "KT",
  "018260.KS": "삼성에스디에스",
  "011200.KS": "HMM",
  // 코스닥 주요 종목
  "247540.KQ": "에코프로비엠",
  "086520.KQ": "에코프로",
  "373220.KQ": "LG에너지솔루션",
  "196170.KQ": "알테오젠",
  "263750.KQ": "펄어비스",
  "293490.KQ": "카카오게임즈",
  "112040.KQ": "위메이드",
  "035900.KQ": "JYP엔터",
  "041510.KQ": "에스엠",
  "352820.KQ": "하이브",
};

export function getKoreanName(ticker: string): string {
  return KOREAN_STOCK_NAMES[ticker] ?? ticker;
}

// MARK: - Types

export interface AlertCondition {
  conditionId: string;
  ticker: string;
  strategyId: string;
  parameters: string; // JSON string
  fcmToken: string;
  userId: string;
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
  cond: AlertCondition
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
    signal = await evaluate(cond.ticker, params);
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

  await sendFcm(cond.fcmToken, cond.userId, cond.ticker, cond.strategyId, signal, cond.conditionId, params);

  await getFirestore()
    .collection("alertConditions")
    .doc(cond.conditionId)
    .update({ lastTriggeredAt: Timestamp.now(), lastNotifiedSignal: signal });
}

// MARK: - Candle Cache (종목별 캔들 데이터 캐시)

const candleCache = new Map<string, CandleData>();

export function clearCandleCache(): void {
  candleCache.clear();
}

export async function evaluate(
  ticker: string,
  params: StrategyParams
): Promise<SignalType> {
  let candles = candleCache.get(ticker);
  if (!candles) {
    candles = await fetchCandles(ticker);
    candleCache.set(ticker, candles);
  }

  switch (params.type) {
    case "sma":
      return evaluateSma(candles, params as SmaParams);
    case "ema":
      return evaluateEma(candles, params as EmaParams);
    case "rsi":
      return evaluateRsi(candles, params as RsiParams);
  }
}

export async function sendFcm(
  fcmToken: string,
  userId: string,
  ticker: string,
  strategyId: string,
  signal: SignalType,
  conditionId: string,
  params?: StrategyParams,
  logoURL?: string
): Promise<void> {
  if (!fcmToken) {
    console.error(`<< [sendFcm] fcmToken이 비어있어 FCM 발송 스킵: conditionId=${conditionId}`);
    return;
  }

  const signalLabel = signal === "buy" ? "매수" : "매도";
  const body = buildNotificationBody(strategyId, signal, params);

  // 뱃지 카운트 증가 (Transaction으로 race condition 방지)
  const db = getFirestore();
  const userRef = db.collection("users").doc(userId);
  let badgeCount = 1;
  try {
    badgeCount = await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(userRef);
      const current = doc.exists ? (doc.data()?.badgeCount ?? 0) : 0;
      const next = current + 1;
      transaction.set(userRef, { badgeCount: next }, { merge: true });
      return next;
    });
  } catch (err) {
    console.error(`<< [sendFcm] 뱃지 카운트 업데이트 실패: userId=${userId}`, err);
  }

  console.log(`<< [sendFcm] 발송 시도: ticker=${ticker}, signal=${signal}, conditionId=${conditionId}, badge=${badgeCount}, tokenPrefix=${fcmToken.slice(0, 10)}...`);
  console.log(`<< [sendFcm] 알림 제목: ${ticker} ${signalLabel} 신호`);
  console.log(`<< [sendFcm] 알림 내용: ${body}`);

  try {
    const messageId = await getMessaging().send({
      token: fcmToken,
      notification: {
        title: `${getKoreanName(ticker)} ${signalLabel} 신호 ${signal === "buy" ? "📈" : "📉"}`,
        body,
      },
      data: {
        conditionId,
        ticker,
        strategyId,
        signal,
        strategyName: `${getKoreanName(ticker)} ${signalLabel} 신호 ${signal === "buy" ? "📈" : "📉"}`,
        body,
        logoURL: logoURL ?? "",
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            sound: "default",
            badge: badgeCount,
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
        return `RSI(${period}) 과매도 구간(${threshold} 이하) 진입`;
      } else {
        const threshold = params.overboughtThreshold ?? 70;
        return `RSI(${period}) 과매수 구간(${threshold} 이상) 진입`;
      }
    }
    case "sma": {
      const s = params.shortPeriod ?? 20;
      const l = params.longPeriod ?? 50;
      return signal === "buy"
        ? `이동평균선 ${s}/${l} 골든 크로스`
        : `이동평균선 ${s}/${l} 데드 크로스`;
    }
    case "ema": {
      const s = params.shortPeriod ?? 12;
      const l = params.longPeriod ?? 26;
      return signal === "buy"
        ? `지수이동평균선 ${s}/${l} 골든 크로스`
        : `지수이동평균선 ${s}/${l} 데드 크로스`;
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

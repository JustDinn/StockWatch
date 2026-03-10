import { defineSecret } from "firebase-functions/params";

export const finnhubApiKey = defineSecret("FINNHUB_API_KEY");

const BASE_URL = "https://finnhub.io/api/v1";

export interface IndicatorResult {
  /** 지표 값 배열 (최신순, index 0이 가장 최근) */
  values: number[];
}

/**
 * Finnhub /indicator endpoint 호출
 * @param ticker  종목 심볼 (예: "AAPL")
 * @param indicator  지표 종류 ("sma" | "ema" | "rsi")
 * @param period  지표 기간
 * @param apiKey  Finnhub API 키
 */
export async function fetchIndicator(
  ticker: string,
  indicator: "sma" | "ema" | "rsi",
  period: number,
  apiKey: string
): Promise<IndicatorResult> {
  const url =
    `${BASE_URL}/indicator` +
    `?symbol=${encodeURIComponent(ticker)}` +
    `&resolution=D` +
    `&from=${unixDaysAgo(200)}` +
    `&to=${unixNow()}` +
    `&indicator=${indicator}` +
    `&timeperiod=${period}` +
    `&token=${apiKey}`;

  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Finnhub API error: ${response.status} ${response.statusText}`);
  }

  const json = (await response.json()) as Record<string, unknown>;

  // Finnhub 응답 구조: { "<indicator>": number[], "s": "ok" }
  const key = indicator.toLowerCase();
  const rawValues = json[key];

  if (!Array.isArray(rawValues) || rawValues.length === 0) {
    throw new Error(`No indicator data for ${ticker} (${indicator})`);
  }

  // 최신순으로 반환
  const values = (rawValues as number[]).slice().reverse();

  return { values };
}

function unixNow(): number {
  return Math.floor(Date.now() / 1000);
}

function unixDaysAgo(days: number): number {
  return Math.floor((Date.now() - days * 86400 * 1000) / 1000);
}

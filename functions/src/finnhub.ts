import { defineSecret } from "firebase-functions/params";

export const finnhubApiKey = defineSecret("FINNHUB_API_KEY");

const BASE_URL = "https://finnhub.io/api/v1";

export interface CandleData {
  /** 종가 배열 (시간순, oldest first) */
  closes: number[];
  /** Unix timestamp 배열 (시간순) */
  timestamps: number[];
}

/**
 * Finnhub /stock/candle endpoint 호출 (무료)
 * @param ticker  종목 심볼 (예: "AAPL")
 * @param apiKey  Finnhub API 키
 */
export async function fetchCandles(
  ticker: string,
  apiKey: string
): Promise<CandleData> {
  const url =
    `${BASE_URL}/stock/candle` +
    `?symbol=${encodeURIComponent(ticker)}` +
    `&resolution=D` +
    `&from=${unixDaysAgo(400)}` +
    `&to=${unixNow()}` +
    `&token=${apiKey}`;

  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Finnhub API error: ${response.status} ${response.statusText}`);
  }

  const json = (await response.json()) as Record<string, unknown>;

  if (json.s !== "ok" || !Array.isArray(json.c) || json.c.length === 0) {
    throw new Error(`No candle data for ${ticker}`);
  }

  return {
    closes: json.c as number[],
    timestamps: json.t as number[],
  };
}

function unixNow(): number {
  return Math.floor(Date.now() / 1000);
}

function unixDaysAgo(days: number): number {
  return Math.floor((Date.now() - days * 86400 * 1000) / 1000);
}

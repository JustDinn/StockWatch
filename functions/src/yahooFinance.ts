export interface CandleData {
  /** 종가 배열 (시간순, oldest first) */
  closes: number[];
  /** Unix timestamp 배열 (시간순) */
  timestamps: number[];
}

const BASE_HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
};

/**
 * Yahoo Finance v8 /chart endpoint 호출 (API 키 불필요)
 * @param ticker  종목 심볼 (예: "AAPL")
 * @param daysBack  조회할 과거 일수 (기본 400일)
 */
export async function fetchCandles(
  ticker: string,
  daysBack = 400
): Promise<CandleData> {
  const to = Math.floor(Date.now() / 1000);
  const from = to - daysBack * 86400;

  const url =
    `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(ticker)}` +
    `?period1=${from}` +
    `&period2=${to}` +
    `&interval=1d`;

  const response = await fetch(url, {
    headers: BASE_HEADERS,
  });

  if (!response.ok) {
    throw new Error(`Yahoo Finance API error: ${response.status} ${response.statusText}`);
  }

  const json = (await response.json()) as Record<string, unknown>;
  const chart = json.chart as Record<string, unknown> | undefined;
  const results = chart?.result as Array<Record<string, unknown>> | undefined;

  if (!results || results.length === 0) {
    throw new Error(`No chart data for ${ticker}`);
  }

  const result = results[0];
  const timestamps = result.timestamp as number[] | undefined;
  const indicators = result.indicators as Record<string, unknown> | undefined;
  const quotes = indicators?.quote as Array<Record<string, unknown>> | undefined;
  const closes = quotes?.[0]?.close as Array<number | null> | undefined;

  if (!timestamps || !closes || closes.length === 0) {
    throw new Error(`No candle data for ${ticker}`);
  }

  // null(휴장일 등) 제거
  const filtered = timestamps.reduce<{ closes: number[]; timestamps: number[] }>(
    (acc, ts, i) => {
      const c = closes[i];
      if (c !== null && c !== undefined) {
        acc.closes.push(c);
        acc.timestamps.push(ts);
      }
      return acc;
    },
    { closes: [], timestamps: [] }
  );

  if (filtered.closes.length === 0) {
    throw new Error(`No valid candle data for ${ticker}`);
  }

  return filtered;
}

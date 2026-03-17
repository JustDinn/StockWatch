import YahooFinance from "yahoo-finance2";

const yahooFinance = new YahooFinance();

export interface CandleData {
  /** 종가 배열 (시간순, oldest first) */
  closes: number[];
  /** Unix timestamp 배열 (시간순) */
  timestamps: number[];
}

/**
 * yahoo-finance2 chart() 래퍼
 * @param ticker  종목 심볼 (예: "AAPL")
 * @param daysBack  조회할 과거 일수 (기본 400일)
 */
export async function fetchCandles(
  ticker: string,
  daysBack = 400
): Promise<CandleData> {
  const to = new Date();
  const from = new Date(Date.now() - daysBack * 86400 * 1000);

  const result = await yahooFinance.chart(ticker, {
    period1: from,
    period2: to,
    interval: "1d",
  });

  const quotes = result.quotes;
  if (!quotes || quotes.length === 0) {
    throw new Error(`No candle data for ${ticker}`);
  }

  // null(휴장일 등) 제거 후 closes/timestamps 추출
  const filtered = quotes.reduce<CandleData>(
    (acc, q) => {
      if (q.close !== null && q.close !== undefined) {
        acc.closes.push(q.close);
        acc.timestamps.push(Math.floor(new Date(q.date).getTime() / 1000));
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

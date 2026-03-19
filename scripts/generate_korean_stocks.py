#!/usr/bin/env python3
"""
KIS 마스터 파일을 파싱하여 korean_stocks.json을 생성하는 스크립트.

사용법:
    python scripts/generate_korean_stocks.py

출력:
    StockWatch/StockWatch/Resources/korean_stocks.json
"""

import datetime
import io
import json
import os
import urllib.request
import zipfile

OUTPUT_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "StockWatch",
    "StockWatch",
    "Resources",
    "korean_stocks.json",
)

# 수동으로 추가할 글로벌 주요 지수 (KIS 형식과 Yahoo Finance 형식이 달라 하드코딩)
MANUAL_INDICES = [
    {"ticker": "^KS11",     "nameKo": "코스피",         "nameEn": "KOSPI",              "market": "KRX",    "type": "INDEX"},
    {"ticker": "^KQ11",     "nameKo": "코스닥",         "nameEn": "KOSDAQ",             "market": "KRX",    "type": "INDEX"},
    {"ticker": "^IXIC",     "nameKo": "나스닥종합",      "nameEn": "NASDAQ Composite",   "market": "NASDAQ", "type": "INDEX"},
    {"ticker": "^GSPC",     "nameKo": "S&P500",         "nameEn": "S&P 500",            "market": "NYSE",   "type": "INDEX"},
    {"ticker": "^DJI",      "nameKo": "다우존스",        "nameEn": "Dow Jones",          "market": "NYSE",   "type": "INDEX"},
    {"ticker": "^RUT",      "nameKo": "러셀2000",        "nameEn": "Russell 2000",       "market": "NYSE",   "type": "INDEX"},
    {"ticker": "^N225",     "nameKo": "닛케이225",       "nameEn": "Nikkei 225",         "market": "TSE",    "type": "INDEX"},
    {"ticker": "^HSI",      "nameKo": "항셍지수",        "nameEn": "Hang Seng Index",    "market": "HKEX",   "type": "INDEX"},
    {"ticker": "000001.SS", "nameKo": "상해종합지수",    "nameEn": "SSE Composite Index","market": "SSE",    "type": "INDEX"},
    {"ticker": "399001.SZ", "nameKo": "심천종합지수",    "nameEn": "SZSE Component",     "market": "SZSE",   "type": "INDEX"},
    {"ticker": "^VIX",      "nameKo": "VIX",            "nameEn": "CBOE Volatility",    "market": "CBOE",   "type": "INDEX"},
    {"ticker": "^SOX",      "nameKo": "필라델피아반도체", "nameEn": "Philadelphia SOX",  "market": "NASDAQ", "type": "INDEX"},
    {"ticker": "^STOXX50E", "nameKo": "유로스톡스50",    "nameEn": "Euro Stoxx 50",      "market": "EUREX",  "type": "INDEX"},
    {"ticker": "^FTSE",     "nameKo": "FTSE100",         "nameEn": "FTSE 100",          "market": "LSE",    "type": "INDEX"},
    {"ticker": "^GDAXI",    "nameKo": "DAX",             "nameEn": "DAX Performance",   "market": "XETRA",  "type": "INDEX"},
]

# 국내 시장 설정
DOMESTIC_MARKETS = [
    {
        "name": "KOSPI",
        "url": "https://new.real.download.dws.co.kr/common/master/kospi_code.mst.zip",
        "filename": "kospi_code.mst",
        "suffix": ".KS",
        "trailing_bytes": 228,
    },
    {
        "name": "KOSDAQ",
        "url": "https://new.real.download.dws.co.kr/common/master/kosdaq_code.mst.zip",
        "filename": "kosdaq_code.mst",
        "suffix": ".KQ",
        "trailing_bytes": 222,
    },
    {
        "name": "KONEX",
        "url": "https://new.real.download.dws.co.kr/common/master/konex_code.mst.zip",
        "filename": "konex_code.mst",
        "suffix": ".KX",
        "trailing_bytes": 184,
    },
]

# 해외 시장 설정 (TSV, 24컬럼)
# KIS 파일 코드 → Yahoo Finance suffix 매핑
FOREIGN_MARKETS = [
    {"name": "NASDAQ", "url": "https://new.real.download.dws.co.kr/common/master/nasmst.cod.zip", "filename": "NASMST.COD", "suffix": ""},
    {"name": "NYSE",   "url": "https://new.real.download.dws.co.kr/common/master/nysmst.cod.zip", "filename": "NYSMST.COD", "suffix": ""},
    {"name": "AMEX",   "url": "https://new.real.download.dws.co.kr/common/master/amsmst.cod.zip", "filename": "AMSMST.COD", "suffix": ""},
    {"name": "상해",    "url": "https://new.real.download.dws.co.kr/common/master/shsmst.cod.zip", "filename": "SHSMST.COD", "suffix": ".SS"},
    {"name": "상해지수","url": "https://new.real.download.dws.co.kr/common/master/shimst.cod.zip", "filename": "SHIMST.COD", "suffix": ".SS"},
    {"name": "심천",    "url": "https://new.real.download.dws.co.kr/common/master/szsmst.cod.zip", "filename": "SZSMST.COD", "suffix": ".SZ"},
    {"name": "심천지수","url": "https://new.real.download.dws.co.kr/common/master/szimst.cod.zip", "filename": "SZIMST.COD", "suffix": ".SZ"},
    {"name": "도쿄",    "url": "https://new.real.download.dws.co.kr/common/master/tsemst.cod.zip", "filename": "TSEMST.COD", "suffix": ".T"},
    {"name": "홍콩",    "url": "https://new.real.download.dws.co.kr/common/master/hksmst.cod.zip", "filename": "HKSMST.COD", "suffix": ".HK"},
    {"name": "하노이",  "url": "https://new.real.download.dws.co.kr/common/master/hnxmst.cod.zip", "filename": "HNXMST.COD", "suffix": ".HNX"},
    {"name": "호치민",  "url": "https://new.real.download.dws.co.kr/common/master/hsxmst.cod.zip", "filename": "HSXMST.COD", "suffix": ".HCM"},
]


def download_zip(url: str) -> bytes:
    print(f"  다운로드 중: {url}")
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read()


def parse_domestic(data: bytes, suffix: str, trailing_bytes: int, market: str) -> list[dict]:
    """국내(KOSPI/KOSDAQ/KONEX) 고정폭 파일 파싱."""
    results = []
    for line in data.splitlines():
        if len(line) < 21 + trailing_bytes:
            continue
        short_code = line[0:9].decode("cp949", errors="ignore").strip()
        # 한글명은 고정폭 trailing 영역 직전까지
        name_bytes = line[21 : len(line) - trailing_bytes]
        name_ko = name_bytes.decode("cp949", errors="ignore").strip()
        ticker = short_code[:6] + suffix
        if name_ko and short_code[:6].strip():
            results.append({
                "ticker": ticker,
                "nameKo": name_ko,
                "nameEn": "",
                "market": market,
                "type": "EQUITY",
            })
    return results


def parse_foreign(data: bytes, suffix: str, market: str) -> list[dict]:
    """해외(TSV, 24컬럼) 파일 파싱. 컬럼4=Symbol, 컬럼6=Korea name."""
    results = []
    text = data.decode("cp949", errors="ignore")
    for line in text.splitlines():
        cols = line.split("\t")
        if len(cols) < 7:
            continue
        symbol = cols[4].strip()
        name_ko = cols[6].strip()
        if not symbol or not name_ko:
            continue
        ticker = symbol + suffix
        results.append({
            "ticker": ticker,
            "nameKo": name_ko,
            "nameEn": "",
            "market": market,
            "type": "EQUITY",
        })
    return results


def main():
    entries: list[dict] = []
    seen_names: set[str] = set()

    # 수동 지수를 먼저 추가 (최우선순위)
    for idx in MANUAL_INDICES:
        if idx["nameKo"] not in seen_names:
            entries.append(idx)
            seen_names.add(idx["nameKo"])

    # 국내 시장 파싱
    for market in DOMESTIC_MARKETS:
        print(f"\n[{market['name']}] 처리 중...")
        try:
            raw = download_zip(market["url"])
            with zipfile.ZipFile(io.BytesIO(raw)) as zf:
                with zf.open(market["filename"]) as f:
                    data = f.read()
            parsed = parse_domestic(data, market["suffix"], market["trailing_bytes"], market["name"])
            added = 0
            for entry in parsed:
                if entry["nameKo"] not in seen_names:
                    entries.append(entry)
                    seen_names.add(entry["nameKo"])
                    added += 1
            print(f"  → {added}개 추가 (총 {len(entries)}개)")
        except Exception as e:
            print(f"  ❌ 오류: {e}")

    # 해외 시장 파싱
    for market in FOREIGN_MARKETS:
        print(f"\n[{market['name']}] 처리 중...")
        try:
            raw = download_zip(market["url"])
            with zipfile.ZipFile(io.BytesIO(raw)) as zf:
                with zf.open(market["filename"]) as f:
                    data = f.read()
            parsed = parse_foreign(data, market["suffix"], market["name"])
            added = 0
            for entry in parsed:
                if entry["nameKo"] not in seen_names:
                    entries.append(entry)
                    seen_names.add(entry["nameKo"])
                    added += 1
            print(f"  → {added}개 추가 (총 {len(entries)}개)")
        except Exception as e:
            print(f"  ❌ 오류: {e}")

    # JSON 저장
    output_path = os.path.normpath(OUTPUT_PATH)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    output = {
        "version": datetime.date.today().isoformat(),
        "stocks": entries,
    }
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 완료: {len(entries)}개 항목 → {output_path}")


if __name__ == "__main__":
    main()

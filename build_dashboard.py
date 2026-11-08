"""Build a self-contained offline HTML preview using the imported source data."""
import csv
import json
from pathlib import Path
import openpyxl

ROOT = Path(__file__).resolve().parent
wb = openpyxl.load_workbook(ROOT / 'Data-Rule.xlsx', data_only=True, read_only=True)
rules = list(wb['Rule'].iter_rows(values_only=True))
kcs = {str(r[0]): r[1:7] for r in rules[2:7] if r[0] is not None}
values = {str(r[0]): r[1:7] for r in rules[10:270] if r[0] is not None}
wb.close()
prices = ['price_po','price_po_10','price_rap','price_rap_10','price_avr_global','price_best_global']
def number(value):
    return float(value) if value not in (None, '', 'NULL') else None
data = []
missing = incomplete = 0
with (ROOT / 'data.csv').open(encoding='utf-8-sig', newline='') as handle:
    for r in csv.DictReader(handle):
        a = r['cert_type'] + '*' + r['clarity']
        b = r['range_carat'] + '*' + r['clarity'] + '*' + r['color']
        ka, vb = kcs.get(a), values.get(b)
        note = None
        if ka is None or vb is None:
            note = 'Chưa có khóa: ' + '; '.join(([f'Key_KCS={a}'] if ka is None else []) + ([f'Key_Value={b}'] if vb is None else []))
            missing += 1
            rates = [None] * 6
        else:
            rates = [x*(1-y) if x is not None and y is not None else None for x,y in zip(ka,vb)]
            if any(v is None for v in rates):
                note = 'Thiếu tỷ lệ trong Rule'
                incomplete += 1
        data.append([r['region_hs'],r['cert_type'],r['clarity'],number(r['size']),r['color'],r['range_carat'],
                     number(r['stock']),number(r['carat']),*[number(r[p]) for p in prices],*rates,note,
                     r['plant'],number(r['price_wh'])])
assert len(data) == 18729 and missing == 1140 and incomplete == 1918
assert all(len(r) == 23 for r in data)
payload = json.dumps(data, ensure_ascii=False, separators=(',',':'), allow_nan=False).replace('<','\\u003c')
template = (ROOT / 'dashboard.template.html').read_text(encoding='utf-8')
assert template.count('__DASHBOARD_DATA__') == 1
(ROOT / 'index.html').write_text(template.replace('__DASHBOARD_DATA__',payload),encoding='utf-8')
print(f'index.html generated: {len(data)} records, {(ROOT / "index.html").stat().st_size:,} bytes.')

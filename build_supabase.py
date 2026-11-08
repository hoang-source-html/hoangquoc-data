"""Prepare Supabase schema and CSV from the original workbook (never modify it)."""
from pathlib import Path
import csv
import datetime
from decimal import Decimal
import openpyxl

ROOT = Path(__file__).resolve().parent
wb = openpyxl.load_workbook(ROOT / 'Data-Rule.xlsx', data_only=True, read_only=True)
names = ['region_hs','plant','type','material','batch','range_carat','stock','carat',
         'dinh_luong_pnj','sloc','clarity','color','size','cert_type','group_name',
         'key_kcs','key_value','unchanged','drop_1','drop_2','drop_3','drop_4','drop_5',
         'filter_x','filter_y','price_wh','price_po','price_po_10','price_rap',
         'price_rap_10','price_avr_global','price_best_global','rapaport_per_ct',
         'global_trade_avg_per_ct','global_trade_best_per_ct','po_number','po_amt',
         'batch_goc','po_date','stock_type','tong_von']
derived = set(range(15,23))
numeric = set([6,7,8,12] + list(range(25,35)) + [36,40])
kept = [i for i in range(41) if i not in derived]
columns = []
for i in kept:
    typ = 'date' if i == 38 else 'numeric' if i in numeric else 'text'
    columns.append(f'    {names[i]} {typ}')

sql = '''-- KCR / Supabase / PostgreSQL 15+
-- Run this entire file in Supabase SQL Editor, then import data.csv into public.data.
-- Rules are seeded below from Data-Rule.xlsx. The source workbook is unchanged.
-- First-time setup: deliberately fails if these table names already exist.
-- No DROP/TRUNCATE. The transaction rolls back on failure.
-- CSV uses snake_case headers; do not import the original Excel headers directly.
-- All monetary values retain the workbook units (price_*: USD; po_amt/tong_von: VND).
-- Ratios remain fractions: 0.2536 => 25.36%; format at display time, not in storage.
-- Blank rule cells remain NULL, distinct from explicit zero.
-- Missing keys are permitted: no foreign keys from Data to incomplete rule tables.
-- No report aggregation/Final is defined until its aggregation rule is confirmed.
-- Security: browser roles get no data access by default; SQL Editor can import/read.
-- Add a deliberate SELECT RLS policy for approved users before wiring the HTML app.
-- Docs: https://supabase.com/docs/guides/database/postgres/row-level-security
-- Docs: https://supabase.com/docs/guides/database/import-data

begin;

'''
ratecols = ['unchanged','drop_1','drop_2','drop_3','drop_4','drop_5']
for table, key in [('rule_kcs','key_kcs'),('rule_value','key_value')]:
    sql += f'create table public.{table} (\n    {key} text primary key,\n'
    sql += ',\n'.join(f'    {c} numeric check ({c} between 0 and 1)' for c in ratecols)
    sql += '\n);\n\n'
sql += 'create table public.data (\n    id bigint generated always as identity primary key,\n'
sql += ',\n'.join(columns)
sql += ''',
    key_kcs text generated always as
        (coalesce(cert_type, '') || '*' || coalesce(clarity, '')) stored,
    key_value text generated always as
        (coalesce(range_carat, '') || '*' || coalesce(clarity, '') || '*' || coalesce(color, '')) stored
);

create index data_key_kcs_idx on public.data (key_kcs);
create index data_key_value_idx on public.data (key_value);
create index data_report_group_idx on public.data (cert_type, clarity, size);

'''
def literal(v):
    if v is None:
        return 'NULL'
    if isinstance(v, (int,float,Decimal)):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"

rules = list(wb['Rule'].iter_rows(values_only=True))
for table, key, start, end in [('rule_kcs','key_kcs',3,7),('rule_value','key_value',11,270)]:
    entries = [row[:7] for row in rules[start-1:end] if row[0] is not None]
    assert len({row[0] for row in entries}) == len(entries), 'Duplicate rule key'
    for row in entries:
        assert all(v is None or 0 <= v <= 1 for v in row[1:])
    sql += f'insert into public.{table} ({key}, ' + ', '.join(ratecols) + ') values\n'
    sql += ',\n'.join('    (' + ', '.join(literal(v) for v in row) + ')' for row in entries) + ';\n\n'

sql += '''-- LEFT JOIN retains inventory rows with missing rule keys.
create view public.data_calculated with (security_invoker = true) as
select d.*,
'''
sql += ',\n'.join(f'    k.{c} * v.{c} as {c}' for c in ratecols)
sql += ''',
    (k.key_kcs is null or v.key_value is null) as missing_key,
    case
        when k.key_kcs is null and v.key_value is null then
            'Chưa có khóa: Key_KCS=' || d.key_kcs || '; Key_Value=' || d.key_value
        when k.key_kcs is null then 'Chưa có khóa: Key_KCS=' || d.key_kcs
        when v.key_value is null then 'Chưa có khóa: Key_Value=' || d.key_value
        when '''
sql += ' or '.join(f'k.{c} is null or v.{c} is null' for c in ratecols)
sql += ''' then 'Thiếu tỷ lệ trong Rule'
        else null
    end as note
from public.data d
left join public.rule_kcs k on k.key_kcs = d.key_kcs
left join public.rule_value v on v.key_value = d.key_value;

-- Supabase may otherwise grant default table privileges to browser roles.
'''
for table in ['data','rule_kcs','rule_value']:
    sql += f'alter table public.{table} enable row level security;\n'
    sql += f'revoke all on table public.{table} from anon, authenticated;\n'
    sql += f'grant all on table public.{table} to service_role;\n'
sql += '''revoke all on table public.data_calculated from anon, authenticated;
grant select on table public.data_calculated to service_role;
revoke all on sequence public.data_id_seq from anon, authenticated;
grant usage, select on sequence public.data_id_seq to service_role;

commit;

-- After importing data.csv:
-- select count(*) from public.data; -- expected: 18729 for this workbook
-- select key_kcs, count(*) from public.data_calculated
-- where missing_key group by key_kcs order by count(*) desc;
-- select * from public.data_calculated where note is not null;
-- Example formatting ONLY: to_char(unchanged * 100, 'FM990.00') || '%'
-- Never place a service_role key in HTML or a GitHub repository.
'''
(ROOT / 'schema.sql').write_text(sql, encoding='utf-8')
count = 0
with (ROOT / 'data.csv').open('w', newline='', encoding='utf-8-sig') as handle:
    writer = csv.writer(handle)
    writer.writerow([names[i] for i in kept])
    for row in wb['Data'].iter_rows(min_row=2, values_only=True):
        if not any(v is not None for v in row):
            continue
        values = []
        for i in kept:
            v = row[i]
            if (i in numeric or i == 38) and isinstance(v, str) and v.strip().upper() == 'NULL':
                v = None
            if i in numeric and v is not None:
                Decimal(str(v))  # Validate before exporting numeric CSV fields.
            if isinstance(v, (datetime.date, datetime.datetime)):
                v = v.strftime('%Y-%m-%d')
            elif i not in numeric and v is not None:
                v = str(v)
            if isinstance(v, str) and v.startswith(('=','#REF!','#VALUE!','#NAME?','#N/A')):
                raise ValueError(f'Unresolved Excel value at row {count+2}, {names[i]}')
            values.append(v)
        writer.writerow(values)
        count += 1
assert count == 18729, count
print(f'Created schema.sql and data.csv: {count} records; {len(kept)} import columns.')

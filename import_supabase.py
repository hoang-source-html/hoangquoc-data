"""First-time atomic import. Password is read from KCR_DB_PASSWORD only."""
import csv
import os
from pathlib import Path
import ssl
import sys
import tempfile
import urllib.request

sys.path.insert(0, str(Path(tempfile.gettempdir()) / 'kcr-db-runtime'))
from pg8000.native import Connection

ROOT = Path(__file__).resolve().parent

def main():
    # Trust the provider's CA downloaded over verified HTTPS, retaining hostname checks.
    with urllib.request.urlopen('https://supabase-downloads.s3-ap-southeast-1.amazonaws.com/prod/ssl/prod-ca-2021.crt', timeout=20) as response:
        ca = response.read().decode('ascii')
    tls = ssl.create_default_context(cadata=ca)
    # Supabase's intermediate predates the Key Usage requirement in Python 3.13.
    # Match Python 3.12 verification rules; certificate/hostname verification stays on.
    tls.verify_flags &= ~ssl.VERIFY_X509_STRICT
    connection = Connection(
        user='postgres.sfqwhoihvfhqceelqooi',
        password=os.environ['KCR_DB_PASSWORD'],
        host='aws-0-ap-northeast-1.pooler.supabase.com',
        port=5432, database='postgres',
        ssl_context=tls, timeout=30,
    )
    try:
        print('Connected with verified TLS.', flush=True)
        existing = connection.run("""select c.relname from pg_class c
            join pg_namespace n on n.oid=c.relnamespace
            where n.nspname='public' and c.relname in
            ('data','rule_kcs','rule_value','data_calculated')""")
        if existing:
            print('Stopped: existing objects:', existing, flush=True)
            return
        with (ROOT / 'data.csv').open(encoding='utf-8-sig', newline='') as handle:
            reader = csv.reader(handle)
            columns = next(reader)
            expected = sum(1 for _ in reader)
        assert expected == 18729
        schema = (ROOT / 'schema.sql').read_text(encoding='utf-8')
        schema = schema.replace('\nbegin;\n', '\n').replace('\ncommit;\n', '\n')
        connection.run('begin')
        try:
            connection.run(schema)
            print('Schema and rules created within transaction.', flush=True)
            # Column names come from the local generated CSV, never user SQL.
            assert all(c.replace('_','').isalnum() for c in columns)
            with (ROOT / 'data.csv').open(encoding='utf-8-sig', newline='') as handle:
                connection.run('copy public.data (' + ','.join(columns) +
                               ') from stdin with (format csv, header true)', stream=handle)
            count = connection.run('select count(*) from public.data')[0][0]
            assert count == expected, (count, expected)
            assert connection.run('select count(*) from public.rule_kcs')[0][0] == 5
            assert connection.run('select count(*) from public.rule_value')[0][0] == 260
            assert connection.run('select count(*) from public.data_calculated')[0][0] == count
            invalid = connection.run('''select count(*) from public.data_calculated
                where missing_key and (unchanged is not null or drop_1 is not null
                or drop_2 is not null or drop_3 is not null
                or drop_4 is not null or drop_5 is not null)''')[0][0]
            assert invalid == 0
            stats = connection.run('''select
                count(*) filter (where missing_key),
                count(*) filter (where note = 'Thiếu tỷ lệ trong Rule')
                from public.data_calculated''')
            sample = connection.run('''select d.id from public.data_calculated d
                join public.rule_kcs k using (key_kcs)
                join public.rule_value v using (key_value)
                where d.drop_1 is distinct from k.drop_1 * v.drop_1 limit 1''')
            assert not sample
            connection.run('commit')
            print(f'COMMITTED: data={count}, rule_kcs=5, rule_value=260.', flush=True)
            print('Missing-key rows / incomplete-rate rows:', stats, flush=True)
            print('Verified: view counts, rate multiplication, missing-key NULLs.', flush=True)
        except BaseException:
            connection.run('rollback')
            print('Import rolled back.', flush=True)
            raise
    finally:
        connection.close()

if __name__ == '__main__':
    main()

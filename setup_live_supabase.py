"""Provision the explicitly requested editor and deploy authenticated dashboard APIs.
Secrets must be supplied through the process environment, never this file.
"""
import os
import json
import ssl
import urllib.request
import urllib.error
import uuid
from pathlib import Path
import import_supabase as db

ROOT=Path(__file__).resolve().parent
URL='https://sfqwhoihvfhqceelqooi.supabase.co'
EMAIL='quoc.vh@pnj.com.vn'

def admin(path, body=None):
    secret=os.environ['KCR_SUPABASE_SECRET']
    req=urllib.request.Request(URL+'/auth/v1/admin/'+path,
        data=json.dumps(body).encode() if body is not None else None,
        headers={'apikey':secret,'Authorization':'Bearer '+secret,'Content-Type':'application/json'},
        method='POST' if body is not None else 'GET')
    try:
        with urllib.request.urlopen(req,timeout=25) as response:return json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f'Auth admin API returned HTTP {error.code}') from None

def connection():
    with urllib.request.urlopen('https://supabase-downloads.s3-ap-southeast-1.amazonaws.com/prod/ssl/prod-ca-2021.crt',timeout=20) as r:ca=r.read().decode('ascii')
    tls=ssl.create_default_context(cadata=ca);tls.verify_flags &= ~ssl.VERIFY_X509_STRICT
    return db.Connection(user='postgres.sfqwhoihvfhqceelqooi',password=os.environ['KCR_DB_PASSWORD'],
        host='aws-0-ap-northeast-1.pooler.supabase.com',port=5432,database='postgres',ssl_context=tls,timeout=60)

def main():
    match=None
    for page in range(1,101):
        users=admin(f'users?page={page}&per_page=1000').get('users',[])
        match=next((u for u in users if u.get('email','').lower()==EMAIL),None)
        if match or len(users)<1000:break
    if match:
        print('Existing Auth account found; password preserved.',flush=True)
    else:
        match=admin('users',{'email':EMAIL,'password':os.environ['KCR_EDITOR_PASSWORD'],'email_confirm':True})
        print('Created requested confirmed Auth account (no invitation email sent).',flush=True)
    uid=match['id']
    c=connection()
    try:
        c.run((ROOT/'supabase_updates.sql').read_text(encoding='utf-8'))
        c.run('insert into public.kcr_members(user_id,can_write) values(:uid,true) on conflict(user_id) do update set can_write=true',uid=uid)
        print('Migration deployed; requested editor allowlisted.',flush=True)
        print('Inventory count:',c.run('select count(*) from public.data')[0][0],flush=True)
        c.run('begin')
        try:
            c.run('set local role authenticated')
            c.run("select set_config('request.jwt.claim.sub',:uid,true)",uid=uid)
            snapshot=c.run('select public.kcr_dashboard_snapshot()')[0][0]
            assert len(snapshot['rows'])==18729
            assert len(snapshot['rows'][0])==23
            testkey='__KCR_TRANSACTION_TEST__'
            payload=[{'key_kcs':testkey,'unchanged':0.25,'drop_1':0.2,'drop_2':0.1,'drop_3':None,'drop_4':0,'drop_5':0}]
            result=c.run("select public.kcr_import('rule_kcs',:payload)",payload=json.dumps(payload))[0][0]
            assert result['inserted']==1
            result2=c.run("select public.kcr_import('rule_kcs',:payload)",payload=json.dumps(payload))[0][0]
            assert result2['updated']==1
            # Existing row exported as numbers with normalized scale must be skipped.
            original=c.run("select to_jsonb(d)-array['id','key_kcs','key_value','import_hash'] from public.data d order by id limit 1")[0][0]
            result3=c.run("select public.kcr_import('data',:payload)",payload=json.dumps([original]))[0][0]
            assert result3['inserted']==0 and result3['skipped']==1,result3
            print('PASS: editor snapshot, transactional Rule insert/update, exact Data duplicate skip.',flush=True)
        finally:c.run('rollback')
        assert c.run("select count(*) from public.rule_kcs where key_kcs='__KCR_TRANSACTION_TEST__'")[0][0]==0
        c.run('begin')
        try:
            c.run('set local role authenticated')
            c.run("select set_config('request.jwt.claim.sub',:uid,true)",uid=str(uuid.uuid4()))
            assert c.run('select count(*) from public.data')[0][0]==0
        finally:c.run('rollback')
        print('PASS: non-member sees no inventory; test rows rolled back; original data retained.',flush=True)
        print('Anonymous snapshot access:',c.run("select has_function_privilege('anon','public.kcr_dashboard_snapshot()','execute')")[0][0],flush=True)
    finally:c.close()

if __name__=='__main__':main()

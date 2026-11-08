-- Dashboard read/import APIs. Browser uses a publishable key + Supabase Auth.
-- Only members provisioned by an administrator may read; can_write controls imports.
begin;
create table if not exists public.kcr_members (
    user_id uuid primary key references auth.users(id) on delete cascade,
    can_write boolean not null default false
);
alter table public.kcr_members enable row level security;
revoke all on public.kcr_members from anon, authenticated;
grant select on public.kcr_members to authenticated;
drop policy if exists kcr_members_self on public.kcr_members;
create policy kcr_members_self on public.kcr_members for select to authenticated
using (user_id = (select auth.uid()));

-- Canonical numeric scale makes 100, 100.0 and 100.00 the same imported row.
create or replace function public.kcr_fingerprint(j jsonb) returns text
language sql immutable set search_path = '' as $$
  select encode(sha256(convert_to(coalesce(jsonb_object_agg(key,
    case when jsonb_typeof(value)='number' then to_jsonb(trim_scale((value #>> '{}')::numeric)) else value end), '{}'::jsonb)::text,'UTF8')),'hex')
  from jsonb_each(j - array['id','key_kcs','key_value','import_hash']);
$$;
revoke all on function public.kcr_fingerprint(jsonb) from public, anon;
grant execute on function public.kcr_fingerprint(jsonb) to authenticated;

alter table public.data add column if not exists import_hash text;
create or replace function public.kcr_data_hash() returns trigger
language plpgsql set search_path = '' as $$
begin
    new.import_hash := public.kcr_fingerprint(to_jsonb(new));
    return new;
end;
$$;
revoke all on function public.kcr_data_hash() from public, anon, authenticated;
drop trigger if exists kcr_data_hash_trigger on public.data;
create trigger kcr_data_hash_trigger before insert or update on public.data
for each row execute function public.kcr_data_hash();
update public.data set import_hash = public.kcr_fingerprint(to_jsonb(data))
where import_hash is null;
create index if not exists data_import_hash_idx on public.data(import_hash);

do $$ declare t text; begin
  foreach t in array array['data','rule_kcs','rule_value'] loop
    execute format('grant select, insert, update on public.%I to authenticated',t);
    execute format('drop policy if exists kcr_read on public.%I',t);
    execute format('create policy kcr_read on public.%I for select to authenticated using
        ((select auth.uid()) in (select user_id from public.kcr_members))',t);
    execute format('drop policy if exists kcr_insert on public.%I',t);
    execute format('create policy kcr_insert on public.%I for insert to authenticated with check
        ((select auth.uid()) in (select user_id from public.kcr_members where can_write))',t);
    execute format('drop policy if exists kcr_update on public.%I',t);
    execute format('create policy kcr_update on public.%I for update to authenticated using
        ((select auth.uid()) in (select user_id from public.kcr_members where can_write)) with check
        ((select auth.uid()) in (select user_id from public.kcr_members where can_write))',t);
  end loop;
end $$;
grant usage, select on sequence public.data_id_seq to authenticated;

-- One snapshot per refresh; no REST page limit or interleaved pages.
create or replace function public.kcr_dashboard_snapshot() returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare result jsonb;
begin
  if not exists(select 1 from public.kcr_members where user_id=(select auth.uid())) then
    raise exception 'Tài khoản chưa được cấp quyền xem KCR' using errcode='42501';
  end if;
  select jsonb_build_object('rows', coalesce(jsonb_agg(jsonb_build_array(
    d.region_hs,d.cert_type,d.clarity,d.size,d.color,d.range_carat,d.stock,d.carat,
    d.price_po,d.price_po_10,d.price_rap,d.price_rap_10,d.price_avr_global,d.price_best_global,
    k.unchanged*(1-v.unchanged),k.drop_1*(1-v.drop_1),k.drop_2*(1-v.drop_2),
    k.drop_3*(1-v.drop_3),k.drop_4*(1-v.drop_4),k.drop_5*(1-v.drop_5),
    case when k.key_kcs is null or v.key_value is null then 'Chưa có khóa'
      when k.unchanged is null or v.unchanged is null or k.drop_1 is null or v.drop_1 is null
      or k.drop_2 is null or v.drop_2 is null or k.drop_3 is null or v.drop_3 is null
      or k.drop_4 is null or v.drop_4 is null or k.drop_5 is null or v.drop_5 is null
      then 'Thiếu tỷ lệ trong Rule' else null end,
    d.plant,d.price_wh
  ) order by d.id), '[]'::jsonb), 'loaded_at', statement_timestamp()) into result
  from public.data d left join public.rule_kcs k on k.key_kcs=d.key_kcs
  left join public.rule_value v on v.key_value=d.key_value;
  return result;
end;
$$;

-- All rows in one request commit together. Exact Data duplicates are skipped.
create or replace function public.kcr_import(p_table text,p_rows jsonb) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare allowed text[]; cols text; keycol text; n integer; changed integer; existing integer := 0;
begin
  if not exists(select 1 from public.kcr_members where user_id=(select auth.uid()) and can_write) then
    raise exception 'Tài khoản chưa được cấp quyền cập nhật' using errcode='42501';
  end if;
  if p_table not in ('data','rule_kcs','rule_value') then raise exception 'Bảng không hợp lệ'; end if;
  if jsonb_typeof(p_rows) is distinct from 'array' then raise exception 'Dữ liệu phải là mảng'; end if;
  n:=jsonb_array_length(p_rows);
  if n<1 or n>50000 then raise exception 'Cho phép từ 1 đến 50000 dòng mỗi lần'; end if;
  if exists(select 1 from jsonb_array_elements(p_rows) e where jsonb_typeof(e)<>'object') then
    raise exception 'Mỗi dòng phải là một đối tượng';
  end if;
  if p_table='data' then
    allowed:=array['region_hs','plant','type','material','batch','range_carat','stock','carat',
      'dinh_luong_pnj','sloc','clarity','color','size','cert_type','group_name','filter_x','filter_y',
      'price_wh','price_po','price_po_10','price_rap','price_rap_10','price_avr_global','price_best_global',
      'rapaport_per_ct','global_trade_avg_per_ct','global_trade_best_per_ct','po_number','po_amt',
      'batch_goc','po_date','stock_type','tong_von'];
  else
    keycol:=case when p_table='rule_kcs' then 'key_kcs' else 'key_value' end;
    allowed:=array[keycol,'unchanged','drop_1','drop_2','drop_3','drop_4','drop_5'];
  end if;
  if exists(select 1 from jsonb_array_elements(p_rows) e cross join lateral jsonb_object_keys(e) k
      where not (k=any(allowed))) then raise exception 'Có cột không được phép nhập'; end if;
  select string_agg(format('%I',c),',') into cols from unnest(allowed) c;
  if p_table='data' then
    if exists(select 1 from jsonb_array_elements(p_rows) e where
      nullif(btrim(e->>'material'),'') is null or nullif(btrim(e->>'batch'),'') is null
      or e->>'stock' is null or e->>'carat' is null) then
      raise exception 'Data cần Material, Batch, Stock và Carat';
    end if;
    lock table public.data in share row exclusive mode;
    execute format($q$with normalized as (
      select t.*, public.kcr_fingerprint(to_jsonb(t)) as fingerprint
      from jsonb_populate_recordset(null::public.data,$1) t
    ), candidates as (select distinct on (fingerprint) * from normalized)
    insert into public.data(%s) select %s from candidates c
    where not exists(select 1 from public.data d where d.import_hash=c.fingerprint)$q$,cols,cols) using p_rows;
    get diagnostics changed=row_count;
    return jsonb_build_object('received',n,'inserted',changed,'updated',0,'skipped',n-changed);
  else
    if exists(select 1 from jsonb_array_elements(p_rows) e where nullif(btrim(e->>keycol),'') is null) then
      raise exception 'Khóa Rule không được trống';
    end if;
    if (select count(distinct e->>keycol) from jsonb_array_elements(p_rows)e)<>n then
      raise exception 'File chứa khóa Rule trùng nhau';
    end if;
    execute format('lock table public.%I in share row exclusive mode',p_table);
    execute format('select count(*) from jsonb_array_elements($1)e join public.%I t on t.%I=e->>$2',p_table,keycol)
      into existing using p_rows,keycol;
    execute format('insert into public.%I(%s) select %s from jsonb_populate_recordset(null::public.%I,$1)
      on conflict(%I) do update set unchanged=excluded.unchanged,drop_1=excluded.drop_1,
      drop_2=excluded.drop_2,drop_3=excluded.drop_3,drop_4=excluded.drop_4,drop_5=excluded.drop_5',
      p_table,cols,cols,p_table,keycol) using p_rows;
    return jsonb_build_object('received',n,'inserted',n-existing,'updated',existing,'skipped',0);
  end if;
end;
$$;
revoke all on function public.kcr_dashboard_snapshot() from public, anon;
revoke all on function public.kcr_import(text,jsonb) from public, anon;
grant execute on function public.kcr_dashboard_snapshot() to authenticated;
grant execute on function public.kcr_import(text,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;

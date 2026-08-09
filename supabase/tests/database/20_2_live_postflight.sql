-- Phase 20.2 live-schema postflight.
-- Fail-closed catalog and data assertions after controlled application of
-- migrations 0025, 0026 and 0027. This script is strictly read-only.

begin transaction read only;

set local statement_timeout = '30s';
set local lock_timeout = '5s';

do $postflight$
declare
  v_versions text[];
begin
  select array_agg(m.version::text order by m.version::text)
  into v_versions
  from supabase_migrations.schema_migrations m
  where m.version::text in ('0025', '0026', '0027');

  if v_versions is distinct from array['0025', '0026', '0027']::text[] then
    raise exception using
      errcode = 'P0001',
      message = format('Phase 20.2 migration history mismatch: %s', coalesce(v_versions::text, '<none>'));
  end if;
end
$postflight$;

do $postflight$
declare
  v_missing text[];
begin
  select array_agg(required_column order by required_column)
  into v_missing
  from (
    values
      ('public', 'rats', 'ultimo_alterador_user_id'),
      ('public', 'rats', 'ultima_alteracao_em'),
      ('public', 'rat_audit_log', 'event_type'),
      ('public', 'rat_audit_log', 'actor_name')
  ) expected(table_schema, table_name, required_column)
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = expected.table_schema
      and c.table_name = expected.table_name
      and c.column_name = expected.required_column
  );

  if v_missing is not null then
    raise exception using errcode = 'P0001', message = format('Missing Phase 20.2 columns: %s', v_missing::text);
  end if;

  if not exists (
    select 1
    from pg_constraint c
    where c.conrelid = 'public.rat_audit_log'::regclass
      and pg_get_constraintdef(c.oid, true) ilike '%event_type%'
      and pg_get_constraintdef(c.oid, true) ilike all (array['%created%', '%updated%', '%trashed%', '%restored%'])
  ) then
    raise exception using errcode = 'P0001', message = 'Missing enforced rat_audit_log event_type constraint';
  end if;
end
$postflight$;

do $postflight$
begin
  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'rats' and c.relrowsecurity
  ) or not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'rat_audit_log' and c.relrowsecurity
  ) then
    raise exception using errcode = 'P0001', message = 'RLS is not enabled on rats and rat_audit_log';
  end if;

  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'rats' and cmd = 'SELECT' and 'authenticated' = any(roles))
     or not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'rats' and cmd = 'INSERT' and 'authenticated' = any(roles))
     or not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'rats' and cmd = 'UPDATE' and 'authenticated' = any(roles))
     or not exists (
       select 1 from pg_policies
       where schemaname = 'public' and tablename = 'rats' and cmd = 'DELETE'
         and regexp_replace(coalesce(qual, ''), '[()[:space:]]', '', 'g') in ('false', 'false::boolean')
     ) then
    raise exception using errcode = 'P0001', message = 'RAT policy matrix is incomplete or physical DELETE is not fail-closed';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'rat_audit_log'
      and cmd = 'SELECT'
      and 'authenticated' = any(roles)
  ) then
    raise exception using errcode = 'P0001', message = 'Authenticated audit SELECT policy is missing';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'rat_audit_log'
      and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
      and (roles && array['authenticated', 'anon', 'public']::name[])
  ) then
    raise exception using errcode = 'P0001', message = 'Client audit write policy still exists';
  end if;
end
$postflight$;

do $postflight$
begin
  if to_regprocedure('public.rats_guard_update()') is null
     or to_regprocedure('public.audit_rat_change()') is null then
    raise exception using errcode = 'P0001', message = 'Required RAT guard/audit function is missing';
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and (
        p.proname in ('rats_guard_update', 'audit_rat_change')
        or p.prosrc ilike '%app_admins%'
        or p.prosrc ilike '%rat_audit_log%'
      )
      and not coalesce(p.proconfig, array[]::text[]) &&
        array['search_path=public', 'search_path=pg_catalog, public', 'search_path=public, pg_temp']
  ) then
    raise exception using errcode = 'P0001', message = 'SECURITY DEFINER function without fixed search_path';
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('rats_guard_update', 'audit_rat_change')
      and (
        has_function_privilege('public', p.oid, 'EXECUTE')
        or has_function_privilege('authenticated', p.oid, 'EXECUTE')
        or has_function_privilege('anon', p.oid, 'EXECUTE')
      )
  ) then
    raise exception using errcode = 'P0001', message = 'Trigger-only function is executable by a client role';
  end if;
end
$postflight$;

do $postflight$
begin
  if not exists (
    select 1
    from pg_trigger t
    where t.tgrelid = 'public.rats'::regclass
      and not t.tgisinternal
      and pg_get_triggerdef(t.oid, true) ilike '%before update%'
      and pg_get_triggerdef(t.oid, true) ilike '%rats_guard_update%'
  ) then
    raise exception using errcode = 'P0001', message = 'BEFORE UPDATE RAT guard trigger is missing';
  end if;

  if not exists (
    select 1
    from pg_trigger t
    where t.tgrelid = 'public.rats'::regclass
      and not t.tgisinternal
      and pg_get_triggerdef(t.oid, true) ilike '%after insert or update%'
      and pg_get_triggerdef(t.oid, true) ilike '%audit_rat_change%'
  ) then
    raise exception using errcode = 'P0001', message = 'AFTER INSERT OR UPDATE RAT audit trigger is missing';
  end if;

  if not exists (
    select 1 from pg_trigger t
    where t.tgrelid = 'public.tecnicos'::regclass
      and not t.tgisinternal
      and pg_get_triggerdef(t.oid, true) ilike '%before insert or update%'
  ) or not exists (
    select 1 from pg_trigger t
    where t.tgrelid = 'public.app_admins'::regclass
      and not t.tgisinternal
      and pg_get_triggerdef(t.oid, true) ilike '%before insert or update%'
  ) then
    raise exception using errcode = 'P0001', message = 'Bidirectional active-identity guard triggers are missing';
  end if;
end
$postflight$;

do $postflight$
begin
  if exists (
    select 1
    from public.tecnicos t
    join public.app_admins a on a.user_id = t.user_id
    where t.ativo and a.ativo
  ) then
    raise exception using errcode = 'P0001', message = 'Active app_admin/company dual identity remains';
  end if;

  if not has_table_privilege('authenticated', 'public.rat_audit_log', 'SELECT')
     or has_table_privilege('authenticated', 'public.rat_audit_log', 'INSERT')
     or has_table_privilege('authenticated', 'public.rat_audit_log', 'UPDATE')
     or has_table_privilege('authenticated', 'public.rat_audit_log', 'DELETE')
     or has_table_privilege('anon', 'public.rat_audit_log', 'INSERT')
     or has_table_privilege('anon', 'public.rat_audit_log', 'UPDATE')
     or has_table_privilege('anon', 'public.rat_audit_log', 'DELETE') then
    raise exception using errcode = 'P0001', message = 'Audit table grants are not client-read-only';
  end if;
end
$postflight$;

-- Human-readable catalog evidence accompanying the fail-closed assertions.
select
  p.policyname,
  p.tablename,
  p.cmd,
  p.roles,
  p.qual,
  p.with_check
from pg_policies p
where p.schemaname = 'public'
  and p.tablename in ('rats', 'rat_audit_log')
order by p.tablename, p.cmd, p.policyname;

select
  c.relname as table_name,
  t.tgname,
  pg_get_triggerdef(t.oid, true) as trigger_definition
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
where not t.tgisinternal
  and t.tgrelid in ('public.tecnicos'::regclass, 'public.app_admins'::regclass, 'public.rats'::regclass)
order by c.relname, t.tgname;

select
  n.nspname,
  p.proname,
  p.proconfig,
  p.proacl,
  pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('rats_guard_update', 'audit_rat_change')
order by p.proname;

select
  grantee,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('rats', 'rat_audit_log')
order by table_name, grantee, privilege_type;

rollback;

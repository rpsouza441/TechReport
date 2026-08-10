-- Phase 20.2 live-schema postflight.
-- Fail-closed catalog and data assertions after controlled application of
-- migrations 0025, 0026 and 0027. This script is strictly read-only.

\set ON_ERROR_STOP on
\pset pager off

\if :{?expected_system_identifier}
\else
  \echo 'BLOCK: expected_system_identifier is required'
  \quit 64
\endif

select
  current_database() = 'postgres'
  and current_user = 'supabase_admin'
  and session_user = 'supabase_admin'
  and (select rolsuper from pg_roles where rolname = current_user)
  and system_identifier::text = :'expected_system_identifier' as postflight_identity_ok
from pg_control_system()
\gset

\if :postflight_identity_ok
\else
  \echo 'BLOCK: postflight database, principal, or system identifier mismatch'
  \quit 65
\endif

begin transaction read only;

set local statement_timeout = '30s';
set local lock_timeout = '5s';

do $postflight$
declare
  v_versions text[];
begin
  select array_agg(m.version::text order by m.version::text)
  into v_versions
  from supabase_migrations.schema_migrations m;

  if v_versions is distinct from array[
    '0001', '0002', '0003', '0004', '0005', '0006', '0007', '0008',
    '0009', '0010', '0011', '0012', '0013', '0014', '0015', '0016',
    '0018', '0019', '0020', '0021', '0022', '0023', '0024', '0025',
    '0026', '0027'
  ]::text[] then
    raise exception using
      errcode = 'P0001',
      message = format('Authoritative migration history mismatch: %s', coalesce(v_versions::text, '<none>'));
  end if;

  if exists (
    select 1
    from supabase_migrations.schema_migrations m
    where cardinality(m.statements) is distinct from 1
       or m.statements[1] !~ '^sha256:[0-9a-f]{64}$'
       or nullif(btrim(m.name), '') is null
  ) then
    raise exception using errcode = 'P0001', message = 'Migration hash/name metadata is malformed';
  end if;

  if (
    select array_agg(column_name || ':' || udt_name order by ordinal_position)
    from information_schema.columns
    where table_schema='supabase_migrations' and table_name='schema_migrations'
  ) is distinct from array['version:text','statements:_text','name:text']::text[] then
    raise exception using errcode = 'P0001', message = 'Migration history table shape changed';
  end if;
end
$postflight$;

do $postflight_inventory$
declare
  v_relations text[];
  v_functions text[];
  v_public_policies text[];
  v_storage_policies text[];
  v_triggers text[];
  v_relation_owners text[];
  v_function_owners text[];
begin
  select coalesce(array_agg(c.relname order by c.relname), array[]::text[])
  into v_relations
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p', 'v', 'm', 'S', 'f');

  if v_relations <> array[
    'app_admins', 'empresas', 'rat_audit_log', 'rat_signature_attachments',
    'rats', 'tecnico_convites', 'tecnicos'
  ]::text[] then
    raise exception 'Unexpected public relation inventory: %', v_relations;
  end if;

  select coalesce(array_agg(
    p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
    order by p.proname, pg_get_function_identity_arguments(p.oid)
  ), array[]::text[])
  into v_functions
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public';

  if v_functions <> array[
    'accept_tecnico_convite(p_codigo text)',
    'audit_rat_change()',
    'cancel_tecnico_convite(p_convite_id uuid)',
    'create_empresa_convite(p_empresa_id uuid, p_email text, p_nome text, p_papel text)',
    'create_tecnico_convite(p_email text, p_nome text, p_papel text)',
    'current_tecnico_empresa_id()',
    'current_tecnico_papel()',
    'guard_app_admin_company_identity()',
    'guard_tecnico_app_admin_identity()',
    'is_admin_empresa_of(p_empresa_id uuid)',
    'is_app_admin()',
    'is_equipe_viewer_of(p_empresa_id uuid)',
    'rats_guard_update()',
    'set_server_updated_at()',
    'update_own_display_name(p_nome text)',
    'update_tecnico_equipe(p_tecnico_id uuid, p_ativo boolean, p_must_change_password boolean)',
    'validate_tecnico_convite(p_email text, p_codigo text)'
  ]::text[] then
    raise exception 'Unexpected public function inventory: %', v_functions;
  end if;

  select coalesce(array_agg(tablename || '.' || policyname order by tablename, policyname), array[]::text[])
  into v_public_policies
  from pg_policies
  where schemaname = 'public';

  if v_public_policies <> array[
    'app_admins.app_admins_select_self',
    'app_admins.app_admins_update_own_nome',
    'empresas.empresas_insert_app_admin',
    'empresas.empresas_select_own_or_app_admin',
    'empresas.empresas_update_authenticated',
    'rat_audit_log.rat_audit_log_select_scope',
    'rat_signature_attachments.rat_signature_attachments_insert_membros',
    'rat_signature_attachments.rat_signature_attachments_select_membros',
    'rat_signature_attachments.rat_signature_attachments_update_membros',
    'rats.rats_delete_none',
    'rats.rats_insert_company_member',
    'rats.rats_select_own_or_manager',
    'rats.rats_update_company_member',
    'tecnico_convites.tecnico_convites_select_admin',
    'tecnicos.tecnicos_insert_by_admin',
    'tecnicos.tecnicos_select_allowed',
    'tecnicos.tecnicos_update'
  ]::text[] then
    raise exception 'Unexpected public policy inventory: %', v_public_policies;
  end if;

  select coalesce(array_agg(policyname order by policyname), array[]::text[])
  into v_storage_policies
  from pg_policies
  where schemaname = 'storage'
    and tablename = 'objects'
    and policyname like 'rat_signatures_%';

  if v_storage_policies <> array[
    'rat_signatures_delete_membros',
    'rat_signatures_insert_membros',
    'rat_signatures_select_membros',
    'rat_signatures_update_membros'
  ]::text[] then
    raise exception 'Unexpected TechReport Storage policy inventory: %', v_storage_policies;
  end if;

  select coalesce(array_agg(c.relname || '.' || t.tgname order by c.relname, t.tgname), array[]::text[])
  into v_triggers
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  where not t.tgisinternal and n.nspname = 'public';

  if v_triggers <> array[
    'app_admins.app_admins_guard_company_identity',
    'rats.rats_00_guard_update',
    'rats.rats_audit_server_change',
    'rats.rats_set_server_updated_at',
    'tecnicos.tecnicos_guard_app_admin_identity'
  ]::text[] then
    raise exception 'Unexpected public trigger inventory: %', v_triggers;
  end if;

  select coalesce(array_agg(distinct pg_get_userbyid(c.relowner)::text order by pg_get_userbyid(c.relowner)::text), array[]::text[])
  into v_relation_owners
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind in ('r', 'p', 'v', 'm', 'S', 'f');

  select coalesce(array_agg(distinct pg_get_userbyid(p.proowner)::text order by pg_get_userbyid(p.proowner)::text), array[]::text[])
  into v_function_owners
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public';

  if v_relation_owners <> array['supabase_admin']::text[]
     or v_function_owners <> array['supabase_admin']::text[] then
    raise exception 'Unexpected public owners: relations=% functions=%',
      v_relation_owners, v_function_owners;
  end if;

  if (select pg_get_userbyid(c.relowner)::text from pg_class c where c.oid = 'supabase_migrations.schema_migrations'::regclass)
       <> 'supabase_admin'
     or (select array_agg(distinct pg_get_userbyid(c.relowner)::text) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='storage' and c.relname in ('buckets','objects'))
       <> array['supabase_storage_admin']::text[] then
    raise exception 'Unexpected migration-history or Storage relation owner';
  end if;

  if exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind='r' and not c.relrowsecurity
  ) then
    raise exception 'RLS is not enabled on every TechReport table';
  end if;

  if (select count(*) from public.empresas) <> 0
     or (select count(*) from public.tecnicos) <> 0
     or (select count(*) from public.app_admins) <> 0
     or (select count(*) from public.tecnico_convites) <> 0
     or (select count(*) from public.rats) <> 0
     or (select count(*) from public.rat_audit_log) <> 0
     or (select count(*) from public.rat_signature_attachments) <> 0
     or (select count(*) from auth.users) <> 0
     or (select count(*) from auth.identities) <> 0
     or (select count(*) from auth.sessions) <> 0
     or (select count(*) from auth.refresh_tokens) <> 0 then
    raise exception 'Fresh-environment application/Auth data is not empty';
  end if;

  if (select count(*) from storage.objects) <> 0
     or (select count(*) from storage.buckets) <> 1
     or not exists (
       select 1 from storage.buckets
       where id='rat-signatures' and name='rat-signatures' and public=false
         and file_size_limit=10485760
         and allowed_mime_types=array['image/png','image/jpeg']::text[]
     ) then
    raise exception 'Private rat-signatures bucket state is unexpected';
  end if;

  if exists (
    select 1 from pg_extension e join pg_namespace n on n.oid=e.extnamespace
    where n.nspname='public'
  ) or exists (
    select 1 from pg_publication_tables where schemaname in ('public','storage')
  ) then
    raise exception 'Extension/publication preservation contract changed';
  end if;
end
$postflight_inventory$;

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

\echo 'TECHREPORT_LIVE_POSTFLIGHT=PASS history=26 tables=7 functions=17 public_policies=17 storage_policies=4 triggers=5 app_auth_data=empty bucket=private transaction=rolled_back'

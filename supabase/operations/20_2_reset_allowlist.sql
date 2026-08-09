-- Controlled TechReport-only reset for the development Supabase database.
--
-- Required psql variable:
--   expected_system_identifier=<value captured by the verified backup gate>
--
-- This script deliberately does NOT:
--   * drop/recreate schema public;
--   * touch auth.* rows;
--   * delete storage buckets or storage.objects rows;
--   * change Docker volumes, extensions, publications, or platform schemas.

\set ON_ERROR_STOP on
\pset pager off

\if :{?expected_system_identifier}
\else
  \echo 'BLOCK: expected_system_identifier is required'
  \quit 64
\endif

select
  current_database() = 'postgres'
  and current_user = 'postgres'
  and system_identifier::text = :'expected_system_identifier' as identity_ok,
  current_database() as actual_database,
  current_user as actual_user,
  system_identifier::text as actual_system_identifier
from pg_control_system()
\gset

\if :identity_ok
  \echo 'PASS: database identity matches the backup gate'
\else
  \echo 'BLOCK: database name, role, or system identifier mismatch'
  \echo 'actual_database=' :actual_database
  \echo 'actual_user=' :actual_user
  \echo 'actual_system_identifier=' :actual_system_identifier
  \quit 65
\endif

begin;

set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $safety$
declare
  v_relations text[];
  v_unexpected_functions text[];
  v_unexpected_storage_policies text[];
  v_pgcrypto_schema text;
begin
  if to_regclass('auth.users') is null
     or to_regclass('storage.buckets') is null
     or to_regclass('storage.objects') is null then
    raise exception 'BLOCK: expected Supabase platform relations are missing';
  end if;

  select n.nspname
  into v_pgcrypto_schema
  from pg_extension e
  join pg_namespace n on n.oid = e.extnamespace
  where e.extname = 'pgcrypto';

  if v_pgcrypto_schema is distinct from 'extensions' then
    raise exception 'BLOCK: pgcrypto must already exist in extensions, actual=%',
      coalesce(v_pgcrypto_schema, '<absent>');
  end if;

  select coalesce(array_agg(c.relname order by c.relname), array[]::text[])
  into v_relations
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p', 'v', 'm', 'S', 'f');

  if v_relations <> array[
    'app_admins',
    'empresas',
    'rat_audit_log',
    'rat_signature_attachments',
    'rats',
    'tecnico_convites',
    'tecnicos'
  ]::text[]
  and v_relations <> array[]::text[] then
    raise exception 'BLOCK: public relation inventory is outside the TechReport allowlist: %',
      v_relations;
  end if;

  select array_agg(
    p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
    order by p.proname, pg_get_function_identity_arguments(p.oid)
  )
  into v_unexpected_functions
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and (p.proname, pg_get_function_identity_arguments(p.oid)) not in (
      ('accept_tecnico_convite', 'p_codigo text'),
      ('audit_rat_change', ''),
      ('cancel_tecnico_convite', 'p_convite_id uuid'),
      ('create_empresa_convite', 'p_empresa_id uuid, p_email text, p_nome text, p_papel text'),
      ('create_tecnico_convite', 'p_email text, p_nome text, p_papel text'),
      ('current_tecnico_empresa_id', ''),
      ('current_tecnico_papel', ''),
      ('guard_app_admin_company_identity', ''),
      ('guard_tecnico_app_admin_identity', ''),
      ('is_admin_empresa_of', 'p_empresa_id uuid'),
      ('is_app_admin', ''),
      ('is_equipe_viewer_of', 'p_empresa_id uuid'),
      ('rats_guard_update', ''),
      ('set_server_updated_at', ''),
      ('update_own_display_name', 'p_nome text'),
      ('update_tecnico_equipe', 'p_tecnico_id uuid, p_ativo boolean, p_must_change_password boolean'),
      ('validate_tecnico_convite', 'p_email text, p_codigo text')
    );

  if v_unexpected_functions is not null then
    raise exception 'BLOCK: public function inventory is outside the TechReport allowlist: %',
      v_unexpected_functions;
  end if;

  select array_agg(policyname order by policyname)
  into v_unexpected_storage_policies
  from pg_policies
  where schemaname = 'storage'
    and tablename = 'objects'
    and (
      policyname ilike '%rat_signature%'
      or policyname ilike '%rat-signature%'
      or coalesce(qual, '') ilike '%public.tecnicos%'
      or coalesce(qual, '') ilike '%from tecnicos%'
      or coalesce(with_check, '') ilike '%public.tecnicos%'
      or coalesce(with_check, '') ilike '%from tecnicos%'
    )
    and policyname not in (
      'admins_empresa acessam storage rat-signatures',
      'gerentes acessam storage rat-signatures',
      'tecnicos acessam storage rat-signatures',
      'admins_empresa fazem upload em rat-signatures',
      'gerentes fazem upload em rat-signatures',
      'tecnicos fazem upload em rat-signatures',
      'membros atualizam objeto em rat-signatures',
      'rat_signatures_select_membros',
      'rat_signatures_insert_membros',
      'rat_signatures_update_membros',
      'rat_signatures_delete_membros'
    );

  if v_unexpected_storage_policies is not null then
    raise exception 'BLOCK: storage policy inventory is outside the TechReport allowlist: %',
      v_unexpected_storage_policies;
  end if;
end
$safety$;

-- Storage object bytes and bucket metadata must already have been removed by
-- the supported Storage API. Refuse to create service/filesystem divergence.
do $storage_gate$
declare
  v_objects bigint;
  v_bucket boolean;
begin
  select count(*) into v_objects
  from storage.objects
  where bucket_id = 'rat-signatures';

  select exists (
    select 1 from storage.buckets where id = 'rat-signatures'
  ) into v_bucket;

  if v_objects <> 0 or v_bucket then
    raise exception
      'BLOCK: Storage API cleanup is incomplete (bucket_exists=%, object_count=%)',
      v_bucket, v_objects;
  end if;
end
$storage_gate$;

-- Remove only TechReport policies from the platform-owned storage.objects
-- table. Legacy names are included so a partially replayed development reset
-- remains recoverable without CASCADE.
drop policy if exists "admins_empresa acessam storage rat-signatures" on storage.objects;
drop policy if exists "gerentes acessam storage rat-signatures" on storage.objects;
drop policy if exists "tecnicos acessam storage rat-signatures" on storage.objects;
drop policy if exists "admins_empresa fazem upload em rat-signatures" on storage.objects;
drop policy if exists "gerentes fazem upload em rat-signatures" on storage.objects;
drop policy if exists "tecnicos fazem upload em rat-signatures" on storage.objects;
drop policy if exists "membros atualizam objeto em rat-signatures" on storage.objects;
drop policy if exists "rat_signatures_select_membros" on storage.objects;
drop policy if exists "rat_signatures_insert_membros" on storage.objects;
drop policy if exists "rat_signatures_update_membros" on storage.objects;
drop policy if exists "rat_signatures_delete_membros" on storage.objects;

-- All seven TechReport tables are one DROP target set so inter-table foreign
-- keys resolve without CASCADE. Any external dependency blocks the transaction.
drop table if exists
  public.rat_audit_log,
  public.rat_signature_attachments,
  public.tecnico_convites,
  public.rats,
  public.app_admins,
  public.tecnicos,
  public.empresas;

drop function if exists public.accept_tecnico_convite(text);
drop function if exists public.audit_rat_change();
drop function if exists public.cancel_tecnico_convite(uuid);
drop function if exists public.create_empresa_convite(uuid, text, text, text);
drop function if exists public.create_tecnico_convite(text, text, text);
drop function if exists public.current_tecnico_empresa_id();
drop function if exists public.current_tecnico_papel();
drop function if exists public.guard_app_admin_company_identity();
drop function if exists public.guard_tecnico_app_admin_identity();
drop function if exists public.is_admin_empresa_of(uuid);
drop function if exists public.is_app_admin();
drop function if exists public.is_equipe_viewer_of(uuid);
drop function if exists public.rats_guard_update();
drop function if exists public.set_server_updated_at();
drop function if exists public.update_own_display_name(text);
drop function if exists public.update_tecnico_equipe(uuid, boolean, boolean);
drop function if exists public.validate_tecnico_convite(text, text);

-- Bootstrap only the trace table required for authoritative replay. Never drop
-- this platform schema/table; remove only the explicitly replayed versions.
create schema if not exists supabase_migrations;
create table if not exists supabase_migrations.schema_migrations (
  version text primary key,
  statements text[],
  name text
);

do $history_shape$
declare
  v_columns text[];
begin
  select array_agg(
    column_name || ':' || udt_name
    order by ordinal_position
  )
  into v_columns
  from information_schema.columns
  where table_schema = 'supabase_migrations'
    and table_name = 'schema_migrations';

  if v_columns is distinct from array[
    'version:text',
    'statements:_text',
    'name:text'
  ]::text[] then
    raise exception 'BLOCK: unexpected schema_migrations shape: %', v_columns;
  end if;
end
$history_shape$;

delete from supabase_migrations.schema_migrations
where version in (
  '0001', '0002', '0003', '0004', '0005', '0006', '0007', '0008',
  '0009', '0010', '0011', '0012', '0013', '0014', '0015', '0016',
  '0018', '0019', '0020', '0021', '0022', '0023', '0024', '0025',
  '0026', '0027'
);

do $post_reset$
begin
  if exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p', 'v', 'm', 'S', 'f')
  ) then
    raise exception 'BLOCK: public TechReport relations remain after reset';
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
  ) then
    raise exception 'BLOCK: public TechReport functions remain after reset';
  end if;
end
$post_reset$;

commit;

\echo 'TECHREPORT_ALLOWLIST_RESET=PASS'

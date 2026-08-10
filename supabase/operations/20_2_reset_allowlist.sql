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

-- Freeze the destructive boundary before rechecking its exact contents. A
-- concurrent application/Auth/Storage write either finishes before these
-- locks and is detected by the pre-state gates, or blocks until commit.
lock table
  public.app_admins,
  public.empresas,
  public.rat_audit_log,
  public.rat_signature_attachments,
  public.rats,
  public.tecnico_convites,
  public.tecnicos
in access exclusive mode;
lock table auth.users in share mode;
lock table storage.buckets in share mode;
lock table storage.objects in access exclusive mode;

do $safety$
declare
  v_relations text[];
  v_functions text[];
  v_public_policies text[];
  v_storage_policies text[];
  v_triggers text[];
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
  ]::text[] then
    raise exception 'BLOCK: public relation inventory is outside the TechReport allowlist: %',
      v_relations;
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
    'cancel_tecnico_convite(p_convite_id uuid)',
    'create_empresa_convite(p_empresa_id uuid, p_email text, p_nome text, p_papel text)',
    'create_tecnico_convite(p_email text, p_nome text, p_papel text)',
    'current_tecnico_empresa_id()',
    'current_tecnico_papel()',
    'is_admin_empresa_of(p_empresa_id uuid)',
    'is_app_admin()',
    'is_equipe_viewer_of(p_empresa_id uuid)',
    'set_server_updated_at()',
    'update_own_display_name(p_nome text)',
    'update_tecnico_equipe(p_tecnico_id uuid, p_ativo boolean, p_must_change_password boolean)',
    'validate_tecnico_convite(p_email text, p_codigo text)'
  ]::text[] then
    raise exception 'BLOCK: public function inventory differs from the 13-function baseline: %',
      v_functions;
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
    'rat_audit_log.rat_audit_log_insert_authorized',
    'rat_audit_log.rat_audit_log_no_delete',
    'rat_audit_log.rat_audit_log_select_manager',
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
    raise exception 'BLOCK: public policy inventory differs from the 19-policy baseline: %',
      v_public_policies;
  end if;

  select coalesce(array_agg(policyname order by policyname), array[]::text[])
  into v_storage_policies
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
    );

  if v_storage_policies <> array[
    'rat_signatures_delete_membros',
    'rat_signatures_insert_membros',
    'rat_signatures_select_membros',
    'rat_signatures_update_membros'
  ]::text[] then
    raise exception 'BLOCK: Storage policy inventory differs from the four-policy baseline: %',
      v_storage_policies;
  end if;

  select coalesce(array_agg(c.relname || '.' || t.tgname order by c.relname, t.tgname), array[]::text[])
  into v_triggers
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  where not t.tgisinternal
    and n.nspname = 'public';

  if v_triggers <> array['rats.rats_set_server_updated_at']::text[] then
    raise exception 'BLOCK: public trigger inventory differs from the one-trigger baseline: %',
      v_triggers;
  end if;
end
$safety$;

-- The self-hosted Supabase public application surface is intentionally owned
-- by supabase_admin, while the SSH/operator connection enters as postgres.
-- Prove the exact ownership boundary and SET ROLE capability before mutation.
do $owner_gate$
declare
  v_relation_owners text[];
  v_function_owners text[];
begin
  if not exists (select 1 from pg_roles where rolname = 'supabase_admin') then
    raise exception 'BLOCK: required owner role supabase_admin is absent';
  end if;

  if not pg_has_role(current_user, 'supabase_admin', 'MEMBER') then
    raise exception 'BLOCK: role % cannot SET ROLE supabase_admin', current_user;
  end if;

  select coalesce(array_agg(distinct pg_get_userbyid(c.relowner)::text order by pg_get_userbyid(c.relowner)::text), array[]::text[])
  into v_relation_owners
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p', 'v', 'm', 'S', 'f');

  if v_relation_owners <> array['supabase_admin']::text[] then
    raise exception 'BLOCK: public relation owners differ from supabase_admin: %',
      v_relation_owners;
  end if;

  select coalesce(array_agg(distinct pg_get_userbyid(p.proowner)::text order by pg_get_userbyid(p.proowner)::text), array[]::text[])
  into v_function_owners
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public';

  if v_function_owners <> array['supabase_admin']::text[] then
    raise exception 'BLOCK: public function owners differ from supabase_admin: %',
      v_function_owners;
  end if;
end
$owner_gate$;

\echo 'TECHREPORT_RESET_OWNER_GATE=PASS relation_owner=supabase_admin function_owner=supabase_admin set_role=PASS'

-- Exact destructive pre-state from the definitive read-only inventory. This
-- catches any write or catalog drift that happened after the backup/Storage
-- gates and before the reset transaction acquired its locks.
do $prestate$
declare
  v_empresas bigint;
  v_tecnicos bigint;
  v_app_admins bigint;
  v_convites bigint;
  v_rats bigint;
  v_audit bigint;
  v_signature_metadata bigint;
  v_auth_users bigint;
  v_dual_identity bigint;
  v_storage_buckets bigint;
  v_storage_objects bigint;
  v_public_extensions bigint;
  v_relevant_publications bigint;
begin
  select count(*) into v_empresas from public.empresas;
  select count(*) into v_tecnicos from public.tecnicos;
  select count(*) into v_app_admins from public.app_admins;
  select count(*) into v_convites from public.tecnico_convites;
  select count(*) into v_rats from public.rats;
  select count(*) into v_audit from public.rat_audit_log;
  select count(*) into v_signature_metadata from public.rat_signature_attachments;
  select count(*) into v_auth_users from auth.users;
  select count(*) into v_dual_identity
  from public.tecnicos t
  join public.app_admins a on a.user_id = t.user_id
  where t.ativo = true and a.ativo = true;
  select count(*) into v_storage_buckets from storage.buckets;
  select count(*) into v_storage_objects from storage.objects;
  select count(*) into v_public_extensions
  from pg_extension e
  join pg_namespace n on n.oid = e.extnamespace
  where n.nspname = 'public';
  select count(*) into v_relevant_publications
  from pg_publication_tables
  where schemaname in ('public', 'storage');

  if (v_empresas, v_tecnicos, v_app_admins, v_convites, v_rats, v_audit,
      v_signature_metadata, v_auth_users, v_dual_identity,
      v_storage_buckets, v_storage_objects, v_public_extensions,
      v_relevant_publications)
     is distinct from
     (8::bigint, 13::bigint, 1::bigint, 15::bigint, 70::bigint, 0::bigint,
      42::bigint, 14::bigint, 1::bigint,
      0::bigint, 0::bigint, 0::bigint,
      0::bigint) then
    raise exception using
      message = format(
        'BLOCK: destructive pre-state drift empresas=%s tecnicos=%s app_admins=%s convites=%s rats=%s audit=%s signature_metadata=%s auth_users=%s dual_identity=%s storage_buckets=%s storage_objects=%s public_extensions=%s relevant_publications=%s',
        v_empresas, v_tecnicos, v_app_admins, v_convites, v_rats, v_audit,
        v_signature_metadata, v_auth_users, v_dual_identity,
        v_storage_buckets, v_storage_objects, v_public_extensions,
        v_relevant_publications
      );
  end if;

  if to_regclass('supabase_migrations.schema_migrations') is not null then
    raise exception 'BLOCK: migration history appeared after the definitive inventory';
  end if;
end
$prestate$;

\echo 'TECHREPORT_RESET_PRESTATE=PASS'

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

-- Narrow privilege transition: public relations/functions are owned by this
-- verified role. SET LOCAL keeps the change transaction-scoped even on error.
set local role supabase_admin;

do $active_owner_role$
begin
  if current_user <> 'supabase_admin' or session_user <> 'postgres' then
    raise exception 'BLOCK: unexpected role transition current_user=% session_user=%',
      current_user, session_user;
  end if;
end
$active_owner_role$;

\echo 'TECHREPORT_RESET_ACTIVE_ROLE=PASS current_user=supabase_admin session_user=postgres'

-- Remove every exact public policy from the approved inventory so function
-- dependencies can be dropped explicitly without CASCADE.
drop policy if exists app_admins_select_self on public.app_admins;
drop policy if exists app_admins_update_own_nome on public.app_admins;
drop policy if exists empresas_insert_app_admin on public.empresas;
drop policy if exists empresas_select_own_or_app_admin on public.empresas;
drop policy if exists empresas_update_authenticated on public.empresas;
drop policy if exists rat_audit_log_insert_authorized on public.rat_audit_log;
drop policy if exists rat_audit_log_no_delete on public.rat_audit_log;
drop policy if exists rat_audit_log_select_manager on public.rat_audit_log;
drop policy if exists rat_signature_attachments_insert_membros on public.rat_signature_attachments;
drop policy if exists rat_signature_attachments_select_membros on public.rat_signature_attachments;
drop policy if exists rat_signature_attachments_update_membros on public.rat_signature_attachments;
drop policy if exists rats_delete_none on public.rats;
drop policy if exists rats_insert_company_member on public.rats;
drop policy if exists rats_select_own_or_manager on public.rats;
drop policy if exists rats_update_company_member on public.rats;
drop policy if exists tecnico_convites_select_admin on public.tecnico_convites;
drop policy if exists tecnicos_insert_by_admin on public.tecnicos;
drop policy if exists tecnicos_select_allowed on public.tecnicos;
drop policy if exists tecnicos_update on public.tecnicos;

drop trigger if exists rats_set_server_updated_at on public.rats;

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

-- All seven TechReport tables are one DROP target set so inter-table foreign
-- keys resolve without CASCADE. Any unapproved external dependency blocks.
drop table if exists
  public.rat_audit_log,
  public.rat_signature_attachments,
  public.tecnico_convites,
  public.rats,
  public.app_admins,
  public.tecnicos,
  public.empresas;

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

-- Return to the connection role for platform-preservation checks. The public
-- destructive work above remains inside the same all-or-nothing transaction.
reset role;

do $restored_session_role$
begin
  if current_user <> 'postgres' or session_user <> 'postgres' then
    raise exception 'BLOCK: failed to restore postgres role after public reset';
  end if;
end
$restored_session_role$;

\echo 'TECHREPORT_RESET_SESSION_ROLE_RESTORED=PASS current_user=postgres'

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

  if (select count(*) from auth.users) <> 14 then
    raise exception 'BLOCK: Auth users changed during public reset';
  end if;

  if (select count(*) from storage.buckets) <> 0
     or (select count(*) from storage.objects) <> 0 then
    raise exception 'BLOCK: Storage metadata changed during public reset';
  end if;

  if not exists (
    select 1
    from pg_extension e
    join pg_namespace n on n.oid = e.extnamespace
    where e.extname = 'pgcrypto' and n.nspname = 'extensions'
  ) then
    raise exception 'BLOCK: pgcrypto platform extension changed during reset';
  end if;

  if not exists (select 1 from pg_namespace where nspname = 'auth')
     or not exists (select 1 from pg_namespace where nspname = 'storage')
     or not exists (select 1 from pg_namespace where nspname = 'extensions')
     or not exists (select 1 from pg_namespace where nspname = 'supabase_migrations') then
    raise exception 'BLOCK: required Supabase platform schema missing after reset';
  end if;
end
$post_reset$;

commit;

\echo 'TECHREPORT_ALLOWLIST_RESET=PASS'

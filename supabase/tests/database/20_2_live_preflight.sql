-- Phase 20.2 live-schema preflight.
-- Read-only by construction: this script inventories drift and existing data;
-- it never applies migrations, repairs identities, or emits secrets/emails.

begin transaction read only;

set local statement_timeout = '30s';
set local lock_timeout = '5s';

-- 1. Migration history shape and complete ordered rows.
select
  column_name,
  data_type,
  is_nullable,
  ordinal_position
from information_schema.columns
where table_schema = 'supabase_migrations'
  and table_name = 'schema_migrations'
order by ordinal_position;

select to_jsonb(m) as migration_history_row
from supabase_migrations.schema_migrations m
order by m.version::text;

-- Repository manifest captured at plan creation. The 0017 row is explicitly a
-- historical gap (expected_file=false), not a migration to create or apply.
with repository_manifest(version, file_name, sha256, expected_file) as (
  values
    ('0001', '0001_company_auth_base.sql', '5d2cd6ac7c36aaf430f34a7fea56564521b48615b5fd02f3928088d9e3f286f8', true),
    ('0002', '0002_company_rats_base.sql', '8d272221960184604e493c7b9dd8578c18d037b83360e40513855fd9ae4e6469', true),
    ('0003', '0003_rat_completo_fields.sql', 'ccbac8249c56352926c5a738ae0acc429977ff4934d94c27eda1391e808c7b29', true),
    ('0004', '0004_optimize_rls_auth_uid.sql', '704d6b1a22b8b2773fb477bb1c9bc03f1fd8b33fc511f932539db2f6d452b464', true),
    ('0005', '0005_fix_function_search_path.sql', 'eb277638b6c418a92f4fd4c9a88c941e98c1b76a71a94bda63e275557175bd00', true),
    ('0006', '0006_admin_roles_base.sql', '7d5b1787468ddedf0648bedef7dc72ef7d649598c4df0bfad221ca9372258f1d', true),
    ('0007', '0007_optimize_admin_rls_auth_uid.sql', 'c93a6aca9cd936ec316d4220a3929aa756a2a6d62c4cc7f73ed6b4c8b6df251c', true),
    ('0008', '0008_responsavel_documento.sql', '907e3e07c3c920894f25b470465c5d278d19c1b9d0dd15658ad1e841b60bba2c', true),
    ('0009', '0009_tecnico_convites_equipe.sql', '0987492d9f814a576fe5366859be77da28531638b15c1ce68a49655d12f5e6f3', true),
    ('0010', '0010_fix_tecnico_convites_digest.sql', 'd0f41aee0ce955b4474c3b57e02e944285dc7d4df26c005633ab787236ea97ed', true),
    ('0011', '0011_finalize_sprint_8_5_convites.sql', '5be9978da0364d7a1dc3c70e4197fd785c462545b1b66d1c92795307e182139d', true),
    ('0012', '0012_fix_invite_acceptance_password.sql', '5d09d7df2ec189375ec9f572f5c0fe9d1100aa0a1b1d2da40752bcedca12cccc', true),
    ('0013', '0013_gerente_convites_tecnicos.sql', 'ab9f7256302e98d49d33de53b7c4f0f178c7ceaeb0af35def77d30fa07fd8626', true),
    ('0014', '0014_gerente_gerencia_tecnicos.sql', '9b586e52c26c3b0c2c667ab9d0002aa798b1203ce9e7d1decdd6af2e1340f1a4', true),
    ('0015', '0015_rat_signature_attachments.sql', 'bbbd2043c137fd863f73f4d873e4e35d461fc3ad274efee98778351ef7e67e4b', true),
    ('0016', '0016_update_own_display_name.sql', 'c6813ef5708e232decbf5fa78e51084e376ab6f1b4625938ca2abd740fe5b9e2', true),
    ('0017', null, null, false),
    ('0018', '0018_add_rat_audit_fields.sql', '3dc2a379291e752ec586ab8805f70cb905ee292dca4c816cb3ac84d64a79e813', true),
    ('0019', '0019_create_rat_audit_log.sql', 'b33ef017813b17a873bdd06c77e258491d51855a6978317de3669c8e447908e0', true),
    ('0020', '0020_add_admin_empresa_to_rats_select_policy.sql', '71d4bc16eee0b28acee1e23b637f28ffc0db0cb006b2d9b248842766fd1d71cc', true),
    ('0021', '0021_fix_tecnicos_update_with_check_self_update.sql', 'e78fbe97ee0e6273b7c16fa4604a2aded90f6ea40880797037b30578a2bb7815', true),
    ('0022', '0022_update_own_display_name_rpc.sql', 'fbcf8b479ce0a0dcd0732b2435040a20dd44405244945fd37ece48f56af462a0', true),
    ('0023', '0023_update_display_name_all_profiles.sql', 'ad8af55f3887129a447e2fa94f97c9162416ee19ea46c7afb6029a19ea431ff1', true),
    ('0024', '0024_add_admin_empresa_update_empresas_policy.sql', 'b5e37c700a1408cc5084e8d1d0a89b2a6c231bbc67611fb2f203bd7344cae969', true)
), applied as (
  select m.version::text as version
  from supabase_migrations.schema_migrations m
)
select
  r.version,
  r.file_name,
  r.sha256 as repository_sha256,
  r.expected_file,
  (a.version is not null) as present_in_live_history,
  case
    when not r.expected_file then 'intentional_historical_gap'
    when a.version is null then 'missing_from_live_history'
    else 'present'
  end as history_status
from repository_manifest r
left join applied a using (version)
order by r.version;

-- 2. Trust-boundary table shape and constraints.
select
  table_name,
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default,
  ordinal_position
from information_schema.columns
where table_schema = 'public'
  and table_name in ('tecnicos', 'app_admins', 'rats', 'rat_audit_log')
order by table_name, ordinal_position;

select
  c.conrelid::regclass::text as table_name,
  c.conname,
  c.contype,
  pg_get_constraintdef(c.oid, true) as definition,
  c.convalidated
from pg_constraint c
where c.conrelid in (
  'public.tecnicos'::regclass,
  'public.app_admins'::regclass,
  'public.rats'::regclass,
  'public.rat_audit_log'::regclass
)
order by table_name, c.conname;

-- 3. Effective RLS, functions, triggers, ACLs and table grants.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('tecnicos', 'app_admins', 'rats', 'rat_audit_log')
order by tablename, cmd, policyname;

select
  n.nspname as function_schema,
  p.proname,
  pg_get_function_identity_arguments(p.oid) as identity_arguments,
  p.prosecdef as security_definer,
  p.proconfig,
  p.proacl,
  pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prokind = 'f'
  and (
    p.proname in (
      'is_app_admin', 'current_tecnico_empresa_id', 'current_tecnico_papel',
      'accept_tecnico_convite', 'create_tecnico_convite',
      'create_empresa_convite', 'update_tecnico_equipe',
      'rats_guard_update', 'audit_rat_change'
    )
    or p.prosrc ilike '%app_admins%'
    or p.prosrc ilike '%rat_audit_log%'
  )
order by p.proname, identity_arguments;

select
  c.relname as table_name,
  t.tgname as trigger_name,
  t.tgenabled,
  pg_get_triggerdef(t.oid, true) as trigger_definition
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where not t.tgisinternal
  and n.nspname = 'public'
  and c.relname in ('tecnicos', 'app_admins', 'rats', 'rat_audit_log')
order by c.relname, t.tgname;

select
  grantee,
  table_schema,
  table_name,
  privilege_type,
  is_grantable
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('tecnicos', 'app_admins', 'rats', 'rat_audit_log')
order by table_name, grantee, privilege_type;

-- 4. Existing data inventory. Only UUIDs and aggregate counts are emitted.
with dual_active_identities as (
  select distinct t.user_id
  from public.tecnicos t
  join public.app_admins a on a.user_id = t.user_id
  where t.ativo and a.ativo
)
select
  count(*) as active_dual_identity_count,
  coalesce(array_agg(user_id order by user_id), array[]::uuid[]) as affected_user_ids
from dual_active_identities;

select
  r.empresa_id,
  r.deletado,
  count(*) as rat_count
from public.rats r
group by r.empresa_id, r.deletado
order by r.empresa_id, r.deletado;

select
  r.empresa_id,
  r.deletado,
  count(l.id) as audit_row_count
from public.rats r
left join public.rat_audit_log l on l.rat_id = r.id
group by r.empresa_id, r.deletado
order by r.empresa_id, r.deletado;

rollback;

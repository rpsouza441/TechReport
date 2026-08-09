-- Phase 20.2 live-schema preflight for the self-hosted manual-deployment mode.
--
-- Historical TechReport migrations were applied manually in the Supabase SQL
-- editor. Therefore supabase_migrations.schema_migrations is intentionally
-- absent or empty and is not evidence of drift by itself. The gate validates
-- the live PostgreSQL catalog that migrations 0025-0027 actually depend on.
--
-- Read-only by construction: no migration, repair, temporary object or data
-- mutation is performed. ON_ERROR_STOP plus the final deliberate SQL error
-- makes every incompatible or unevaluated state exit nonzero.

\set ON_ERROR_STOP on
\pset pager off

begin transaction read only;

set local statement_timeout = '30s';
set local lock_timeout = '5s';

select
  current_database() as database_name,
  current_user as connected_role,
  current_setting('transaction_read_only') as transaction_read_only,
  current_setting('server_version') as server_version;

-- 1. Manual migration-history mode.
-- Absence (or an empty table left by tooling) is expected. Any recorded row is
-- unexpected for this installation and blocks until explicitly reconciled.
select
  (to_regclass('supabase_migrations.schema_migrations') is not null)
    as migration_history_table_exists
\gset

\if :migration_history_table_exists
  select count(*)::text as migration_history_row_count
  from supabase_migrations.schema_migrations
  \gset
\else
  \set migration_history_row_count 0
\endif

select
  'manual_sql_editor'::text as migration_deployment_mode,
  :'migration_history_table_exists'::boolean as history_table_exists,
  :'migration_history_row_count'::bigint as history_row_count,
  case
    when :'migration_history_row_count'::bigint = 0
      then 'PASS_MANUAL_HISTORY_ABSENT'
    else 'BLOCK_UNEXPECTED_TRACKED_HISTORY'
  end as history_status;

-- 2. Complete catalog inventories used for human review. These queries are
-- safe even when an expected object is absent.
select
  n.nspname as table_schema,
  c.relname as table_name,
  c.relkind,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls,
  pg_get_userbyid(c.relowner) as owner
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'empresas', 'tecnicos', 'app_admins', 'tecnico_convites',
    'rats', 'rat_audit_log'
  )
order by c.relname;

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
  and table_name in (
    'empresas', 'tecnicos', 'app_admins', 'tecnico_convites',
    'rats', 'rat_audit_log'
  )
order by table_name, ordinal_position;

select
  c.conrelid::regclass::text as table_name,
  c.conname,
  c.contype,
  pg_get_constraintdef(c.oid, true) as definition,
  c.convalidated
from pg_constraint c
join pg_class r on r.oid = c.conrelid
join pg_namespace n on n.oid = r.relnamespace
where n.nspname = 'public'
  and r.relname in ('tecnicos', 'app_admins', 'rats', 'rat_audit_log')
order by table_name, c.conname;

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
  and p.proname in (
    'is_app_admin',
    'current_tecnico_empresa_id',
    'current_tecnico_papel',
    'is_admin_empresa_of',
    'is_equipe_viewer_of',
    'accept_tecnico_convite',
    'create_tecnico_convite',
    'create_empresa_convite',
    'update_tecnico_equipe',
    'set_server_updated_at',
    'guard_app_admin_company_identity',
    'guard_tecnico_app_admin_identity',
    'rats_guard_update',
    'audit_rat_change'
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

-- 3. Existing data. Only UUIDs and aggregate counts are emitted.
select
  (
    to_regclass('public.tecnicos') is not null
    and to_regclass('public.app_admins') is not null
  ) as identity_tables_exist,
  (
    to_regclass('public.rats') is not null
    and to_regclass('public.rat_audit_log') is not null
  ) as rat_inventory_tables_exist
\gset

\if :identity_tables_exist
  with dual_active_identities as (
    select distinct t.user_id
    from public.tecnicos t
    join public.app_admins a on a.user_id = t.user_id
    where t.ativo = true
      and a.ativo = true
  )
  select
    count(*)::text as active_dual_identity_count,
    coalesce(array_agg(user_id order by user_id), array[]::uuid[])::text
      as affected_user_ids
  from dual_active_identities
  \gset
\else
  \set active_dual_identity_count -1
  \set affected_user_ids not_evaluated_missing_identity_table
\endif

select
  :'active_dual_identity_count'::bigint as active_dual_identity_count,
  :'affected_user_ids'::text as affected_user_ids,
  case
    when :'active_dual_identity_count'::bigint = 0
      then 'PASS_NO_ACTIVE_DUAL_IDENTITY'
    when :'active_dual_identity_count'::bigint < 0
      then 'BLOCK_DUAL_IDENTITY_NOT_EVALUATED'
    else 'BLOCK_ACTIVE_DUAL_IDENTITY_FOUND'
  end as dual_identity_status;

\if :rat_inventory_tables_exist
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
\else
  select 'BLOCK_RAT_INVENTORY_NOT_EVALUATED' as rat_inventory_status;
\endif

-- 4. Fail-closed compatibility matrix for the exact pre-0025 baseline.
-- Checks are semantic/catalog based because this installation has no CLI
-- history. Full definitions above remain available for line-by-line review.
with
expected_tables(table_name, must_have_rls) as (
  values
    ('empresas', true),
    ('tecnicos', true),
    ('app_admins', true),
    ('tecnico_convites', true),
    ('rats', true),
    ('rat_audit_log', true)
),
expected_columns(table_name, column_name, udt_name, is_nullable) as (
  values
    ('tecnicos', 'id', 'uuid', 'NO'),
    ('tecnicos', 'empresa_id', 'uuid', 'NO'),
    ('tecnicos', 'user_id', 'uuid', 'NO'),
    ('tecnicos', 'nome', 'text', 'NO'),
    ('tecnicos', 'email', 'text', 'NO'),
    ('tecnicos', 'papel', 'text', 'NO'),
    ('tecnicos', 'ativo', 'bool', 'NO'),
    ('tecnicos', 'must_change_password', 'bool', 'NO'),
    ('app_admins', 'id', 'uuid', 'NO'),
    ('app_admins', 'user_id', 'uuid', 'NO'),
    ('app_admins', 'nome', 'text', 'NO'),
    ('app_admins', 'email', 'text', 'NO'),
    ('app_admins', 'ativo', 'bool', 'NO'),
    ('rats', 'id', 'uuid', 'NO'),
    ('rats', 'empresa_id', 'uuid', 'NO'),
    ('rats', 'tecnico_id', 'uuid', 'NO'),
    ('rats', 'criado_por_user_id', 'uuid', 'NO'),
    ('rats', 'numero', 'text', 'NO'),
    ('rats', 'deletado', 'bool', 'NO'),
    ('rats', 'created_at', 'timestamptz', 'NO'),
    ('rats', 'updated_at', 'timestamptz', 'NO'),
    ('rats', 'server_updated_at', 'timestamptz', 'NO'),
    ('rats', 'ultimo_alterador_user_id', 'uuid', 'YES'),
    ('rats', 'ultima_alteracao_em', 'timestamptz', 'YES'),
    ('rat_audit_log', 'id', 'uuid', 'NO'),
    ('rat_audit_log', 'rat_id', 'uuid', 'NO'),
    ('rat_audit_log', 'user_id', 'uuid', 'NO'),
    ('rat_audit_log', 'edited_at', 'timestamptz', 'NO'),
    ('rat_audit_log', 'changes', 'jsonb', 'NO'),
    ('rat_audit_log', 'created_at', 'timestamptz', 'NO'),
    ('tecnico_convites', 'id', 'uuid', 'NO'),
    ('tecnico_convites', 'empresa_id', 'uuid', 'NO'),
    ('tecnico_convites', 'email', 'text', 'NO'),
    ('tecnico_convites', 'nome', 'text', 'NO'),
    ('tecnico_convites', 'papel', 'text', 'NO'),
    ('tecnico_convites', 'status', 'text', 'NO'),
    ('tecnico_convites', 'token_hash', 'text', 'NO'),
    ('tecnico_convites', 'expires_at', 'timestamptz', 'NO'),
    ('tecnico_convites', 'accepted_by_user_id', 'uuid', 'YES'),
    ('tecnico_convites', 'accepted_at', 'timestamptz', 'YES'),
    ('tecnico_convites', 'updated_at', 'timestamptz', 'NO'),
    ('tecnico_convites', 'created_by_user_id', 'uuid', 'NO')
),
expected_policies(table_name, policy_name, command) as (
  values
    ('app_admins', 'app_admins_select_self', 'SELECT'),
    ('app_admins', 'app_admins_update_own_nome', 'UPDATE'),
    ('tecnicos', 'tecnicos_select_allowed', 'SELECT'),
    ('tecnicos', 'tecnicos_insert_by_admin', 'INSERT'),
    ('tecnicos', 'tecnicos_update', 'UPDATE'),
    ('rats', 'rats_select_own_or_manager', 'SELECT'),
    ('rats', 'rats_insert_company_member', 'INSERT'),
    ('rats', 'rats_update_company_member', 'UPDATE'),
    ('rats', 'rats_delete_none', 'DELETE'),
    ('rat_audit_log', 'rat_audit_log_insert_authorized', 'INSERT'),
    ('rat_audit_log', 'rat_audit_log_select_manager', 'SELECT'),
    ('rat_audit_log', 'rat_audit_log_no_delete', 'DELETE')
),
actual_policies as (
  select tablename, policyname, cmd, roles, qual, with_check
  from pg_policies
  where schemaname = 'public'
    and tablename in ('tecnicos', 'app_admins', 'rats', 'rat_audit_log')
),
expected_functions(signature, security_definer, body_markers) as (
  values
    ('public.is_app_admin()', true, array['app_admins', 'auth.uid']),
    ('public.current_tecnico_empresa_id()', true, array['tecnicos', 'auth.uid', 'ativo']),
    ('public.current_tecnico_papel()', true, array['tecnicos', 'auth.uid', 'ativo']),
    ('public.is_admin_empresa_of(uuid)', true, array['tecnicos', 'auth.uid', 'admin_empresa']),
    ('public.is_equipe_viewer_of(uuid)', true, array['tecnicos', 'auth.uid', 'gerente']),
    ('public.accept_tecnico_convite(text)', true, array['auth.uid', 'tecnico_convites', 'insert into public.tecnicos']),
    ('public.create_tecnico_convite(text,text,text)', true, array['current_tecnico_empresa_id', 'tecnico_convites', 'gerente']),
    ('public.create_empresa_convite(uuid,text,text,text)', true, array['is_app_admin', 'tecnico_convites', 'admin_empresa']),
    ('public.update_tecnico_equipe(uuid,boolean,boolean)', true, array['is_app_admin', 'tecnicos', 'gerente']),
    ('public.set_server_updated_at()', false, array['server_updated_at', 'updated_at'])
),
expected_rpc_grants(signature) as (
  values
    ('public.accept_tecnico_convite(text)'),
    ('public.create_tecnico_convite(text,text,text)'),
    ('public.create_empresa_convite(uuid,text,text,text)'),
    ('public.update_tecnico_equipe(uuid,boolean,boolean)')
),
target_functions(signature) as (
  values
    ('public.guard_app_admin_company_identity()'),
    ('public.guard_tecnico_app_admin_identity()'),
    ('public.rats_guard_update()'),
    ('public.audit_rat_change()')
),
target_triggers(table_name, trigger_name) as (
  values
    ('app_admins', 'app_admins_guard_company_identity'),
    ('tecnicos', 'tecnicos_guard_app_admin_identity'),
    ('rats', 'rats_00_guard_update'),
    ('rats', 'rats_audit_server_change')
),
target_policies(table_name, policy_name) as (
  values
    ('rats', 'rats_insert_company_member'),
    ('rats', 'rats_update_company_member'),
    ('rat_audit_log', 'rat_audit_log_select_scope')
),
checks(area, check_name, passed, details) as (
  select
    'session',
    'transaction_read_only',
    current_setting('transaction_read_only') = 'on',
    'transaction_read_only=' || current_setting('transaction_read_only')

  union all

  select
    'history',
    'manual_history_absent',
    :'migration_history_row_count'::bigint = 0,
    format(
      'mode=manual_sql_editor table_exists=%s rows=%s',
      :'migration_history_table_exists',
      :'migration_history_row_count'
    )

  union all

  select
    'schema',
    'table:' || e.table_name,
    c.oid is not null
      and c.relkind in ('r', 'p')
      and (not e.must_have_rls or c.relrowsecurity),
    format(
      'exists=%s relkind=%s rls=%s',
      c.oid is not null,
      coalesce(c.relkind::text, '<missing>'),
      coalesce(c.relrowsecurity::text, '<missing>')
    )
  from expected_tables e
  left join pg_namespace n on n.nspname = 'public'
  left join pg_class c on c.relnamespace = n.oid and c.relname = e.table_name

  union all

  select
    'schema',
    'column:' || e.table_name || '.' || e.column_name,
    a.column_name is not null
      and a.udt_name = e.udt_name
      and a.is_nullable = e.is_nullable,
    format(
      'expected=%s nullable=%s actual=%s nullable=%s',
      e.udt_name,
      e.is_nullable,
      coalesce(a.udt_name, '<missing>'),
      coalesce(a.is_nullable, '<missing>')
    )
  from expected_columns e
  left join information_schema.columns a
    on a.table_schema = 'public'
   and a.table_name = e.table_name
   and a.column_name = e.column_name

  union all

  select
    'constraints',
    'tecnicos_and_app_admins_user_id_unique',
    (
      select count(*) = 2
      from (
        select c.relname
        from pg_index i
        join pg_class c on c.oid = i.indrelid
        join pg_namespace n on n.oid = c.relnamespace
        join pg_attribute a
          on a.attrelid = c.oid
         and a.attnum = any(i.indkey)
        where n.nspname = 'public'
          and c.relname in ('tecnicos', 'app_admins')
          and i.indisunique
          and i.indisvalid
          and i.indnatts = 1
          and a.attname = 'user_id'
        group by c.relname
      ) unique_user_tables
    ),
    'both profile tables require one valid single-column unique index on user_id'

  union all

  select
    'constraints',
    'tecnicos_papel_check',
    exists (
      select 1
      from pg_constraint c
      join pg_class r on r.oid = c.conrelid
      join pg_namespace n on n.oid = r.relnamespace
      where n.nspname = 'public'
        and r.relname = 'tecnicos'
        and c.conname = 'tecnicos_papel_check'
        and c.contype = 'c'
        and c.convalidated
        and pg_get_constraintdef(c.oid, true) ilike '%admin_empresa%'
        and pg_get_constraintdef(c.oid, true) ilike '%gerente%'
        and pg_get_constraintdef(c.oid, true) ilike '%tecnico%'
    ),
    'validated role check must contain admin_empresa, gerente and tecnico'

  union all

  select
    'rls',
    'policy:' || e.table_name || '.' || e.policy_name,
    a.policyname is not null
      and a.cmd = e.command
      and (
        'authenticated' = any(a.roles)
        or 'public' = any(a.roles)
      ),
    format(
      'expected_cmd=%s actual_cmd=%s roles=%s',
      e.command,
      coalesce(a.cmd, '<missing>'),
      coalesce(a.roles::text, '<missing>')
    )
  from expected_policies e
  left join actual_policies a
    on a.tablename = e.table_name
   and a.policyname = e.policy_name

  union all

  select
    'rls',
    'no_unexpected_policy_names',
    not exists (
      select 1
      from actual_policies a
      where not exists (
        select 1
        from expected_policies e
        where e.table_name = a.tablename
          and e.policy_name = a.policyname
          and e.command = a.cmd
      )
    ),
    coalesce(
      (
        select string_agg(a.tablename || '.' || a.policyname || ':' || a.cmd, ', ')
        from actual_policies a
        where not exists (
          select 1
          from expected_policies e
          where e.table_name = a.tablename
            and e.policy_name = a.policyname
            and e.command = a.cmd
        )
      ),
      'none'
    )

  union all

  select
    'rls',
    'rats_select_semantics',
    exists (
      select 1
      from actual_policies a
      where a.tablename = 'rats'
        and a.policyname = 'rats_select_own_or_manager'
        and lower(coalesce(a.qual, '')) like '%is_app_admin%'
        and lower(coalesce(a.qual, '')) like '%admin_empresa%'
        and lower(coalesce(a.qual, '')) like '%gerente%'
        and lower(coalesce(a.qual, '')) like '%tecnico_id%'
        and lower(coalesce(a.qual, '')) like '%auth.uid%'
    ),
    'owner or same-company manager/admin; app_admin denied'

  union all

  select
    'rls',
    'rats_write_semantics',
    exists (
      select 1
      from actual_policies a
      where a.tablename = 'rats'
        and a.policyname = 'rats_insert_company_member'
        and lower(coalesce(a.with_check, '')) like '%criado_por_user_id%'
        and lower(coalesce(a.with_check, '')) like '%auth.uid%'
    )
    and exists (
      select 1
      from actual_policies a
      where a.tablename = 'rats'
        and a.policyname = 'rats_update_company_member'
        and lower(coalesce(a.qual, '')) like '%tecnico_id%'
        and lower(coalesce(a.with_check, '')) like '%criado_por_user_id%'
        and lower(coalesce(a.with_check, '')) like '%auth.uid%'
    )
    and exists (
      select 1
      from actual_policies a
      where a.tablename = 'rats'
        and a.policyname = 'rats_delete_none'
        and lower(coalesce(a.qual, '')) like '%false%'
    ),
    'baseline owner-only insert/update and physical-delete denial required'

  union all

  select
    'rls',
    'audit_baseline_semantics',
    exists (
      select 1
      from actual_policies a
      where a.tablename = 'rat_audit_log'
        and a.policyname = 'rat_audit_log_insert_authorized'
        and lower(coalesce(a.with_check, '')) like '%auth.uid%'
    )
    and exists (
      select 1
      from actual_policies a
      where a.tablename = 'rat_audit_log'
        and a.policyname = 'rat_audit_log_select_manager'
        and lower(coalesce(a.qual, '')) like '%gerente%'
        and lower(coalesce(a.qual, '')) like '%admin_empresa%'
    )
    and exists (
      select 1
      from actual_policies a
      where a.tablename = 'rat_audit_log'
        and a.policyname = 'rat_audit_log_no_delete'
        and lower(coalesce(a.qual, '')) like '%false%'
    ),
    'legacy client insert, manager select and delete denial must match 0019 before replacement'

  union all

  select
    'functions',
    'function:' || e.signature,
    p.oid is not null
      and p.prosecdef = e.security_definer
      and coalesce(array_to_string(p.proconfig, ','), '') like 'search_path=public%'
      and not exists (
        select 1
        from unnest(e.body_markers) marker
        where lower(pg_get_functiondef(p.oid)) not like '%' || marker || '%'
      ),
    format(
      'exists=%s security_definer=%s config=%s',
      p.oid is not null,
      coalesce(p.prosecdef::text, '<missing>'),
      coalesce(p.proconfig::text, '<missing>')
    )
  from expected_functions e
  left join pg_proc p on p.oid = to_regprocedure(e.signature)

  union all

  select
    'grants',
    'rpc:' || e.signature,
    p.oid is not null
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')
      and not has_function_privilege('anon', p.oid, 'EXECUTE'),
    case
      when p.oid is null then 'function missing'
      else format(
        'authenticated_execute=%s anon_execute=%s',
        has_function_privilege('authenticated', p.oid, 'EXECUTE'),
        has_function_privilege('anon', p.oid, 'EXECUTE')
      )
    end
  from expected_rpc_grants e
  left join pg_proc p on p.oid = to_regprocedure(e.signature)

  union all

  select
    'grants',
    'client_roles_do_not_bypass_rls',
    not exists (
      select 1
      from pg_roles
      where rolname in ('anon', 'authenticated')
        and rolbypassrls
    )
    and exists (select 1 from pg_roles where rolname = 'anon')
    and exists (select 1 from pg_roles where rolname = 'authenticated'),
    coalesce(
      (
        select string_agg(rolname || ':bypass=' || rolbypassrls, ', ' order by rolname)
        from pg_roles
        where rolname in ('anon', 'authenticated')
      ),
      'client roles missing'
    )

  union all

  select
    'triggers',
    'rats_set_server_updated_at',
    exists (
      select 1
      from pg_trigger t
      join pg_class c on c.oid = t.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      where not t.tgisinternal
        and n.nspname = 'public'
        and c.relname = 'rats'
        and t.tgname = 'rats_set_server_updated_at'
        and t.tgenabled <> 'D'
        and lower(pg_get_triggerdef(t.oid, true)) like '%before update%'
        and lower(pg_get_triggerdef(t.oid, true)) like '%set_server_updated_at%'
    ),
    'enabled BEFORE UPDATE trigger must call public.set_server_updated_at'

  union all

  select
    'triggers',
    'no_unexpected_trigger_names',
    not exists (
      select 1
      from pg_trigger t
      join pg_class c on c.oid = t.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      where not t.tgisinternal
        and n.nspname = 'public'
        and c.relname in ('tecnicos', 'app_admins', 'rats', 'rat_audit_log')
        and not (
          c.relname = 'rats'
          and t.tgname = 'rats_set_server_updated_at'
        )
    ),
    coalesce(
      (
        select string_agg(c.relname || '.' || t.tgname, ', ' order by c.relname, t.tgname)
        from pg_trigger t
        join pg_class c on c.oid = t.tgrelid
        join pg_namespace n on n.oid = c.relnamespace
        where not t.tgisinternal
          and n.nspname = 'public'
          and c.relname in ('tecnicos', 'app_admins', 'rats', 'rat_audit_log')
          and not (
            c.relname = 'rats'
            and t.tgname = 'rats_set_server_updated_at'
          )
      ),
      'none'
    )

  union all

  select
    'pending_migrations',
    'target_function_absent:' || t.signature,
    to_regprocedure(t.signature) is null,
    coalesce(to_regprocedure(t.signature)::text, '<absent>')
  from target_functions t

  union all

  select
    'pending_migrations',
    'target_trigger_absent:' || t.table_name || '.' || t.trigger_name,
    not exists (
      select 1
      from pg_trigger g
      join pg_class c on c.oid = g.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      where not g.tgisinternal
        and n.nspname = 'public'
        and c.relname = t.table_name
        and g.tgname = t.trigger_name
    ),
    'must be absent before 0025-0027'
  from target_triggers t

  union all

  select
    'pending_migrations',
    'target_policy_absent:' || t.table_name || '.' || t.policy_name,
    case
      when t.policy_name in ('rats_insert_company_member', 'rats_update_company_member')
        then exists (
          select 1
          from actual_policies a
          where a.tablename = t.table_name
            and a.policyname = t.policy_name
        )
      else not exists (
        select 1
        from actual_policies a
        where a.tablename = t.table_name
          and a.policyname = t.policy_name
      )
    end,
    case
      when t.policy_name in ('rats_insert_company_member', 'rats_update_company_member')
        then 'legacy policy must exist and is replaced by 0026'
      else 'new policy must be absent before 0027'
    end
  from target_policies t

  union all

  select
    'pending_migrations',
    'target_audit_columns_absent',
    not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'rat_audit_log'
        and column_name in ('event_type', 'actor_name')
    ),
    'event_type and actor_name must both be absent before 0027'

  union all

  select
    'pending_migrations',
    'target_audit_constraint_and_index_absent',
    not exists (
      select 1
      from pg_constraint c
      join pg_class r on r.oid = c.conrelid
      join pg_namespace n on n.oid = r.relnamespace
      where n.nspname = 'public'
        and r.relname = 'rat_audit_log'
        and c.conname = 'rat_audit_log_event_type_check'
    )
    and to_regclass('public.rat_audit_log_rat_page_idx') is null,
    '0027 constraint and pagination index must be absent'

  union all

  select
    'data',
    'active_dual_identity_count_zero',
    :'active_dual_identity_count'::bigint = 0,
    'count=' || :'active_dual_identity_count'
)
select
  jsonb_pretty(
    jsonb_agg(
      jsonb_build_object(
        'area', area,
        'check', check_name,
        'status', case when passed then 'PASS' else 'BLOCK' end,
        'details', details
      )
      order by area, check_name
    )
  ) as compatibility_report,
  coalesce(bool_and(passed), false)::text as compatibility_ok
from checks
\gset

\echo === PHASE_20_2_PREFLIGHT_COMPATIBILITY_REPORT ===
\echo :compatibility_report

\if :compatibility_ok
  rollback;
  \echo PHASE_20_2_PREFLIGHT_RESULT=PASS_MANUAL_BASELINE_COMPATIBLE
  \echo APPROVED_SEQUENCE=0025,0026,0027
\else
  \echo PHASE_20_2_PREFLIGHT_RESULT=BLOCK_INCOMPATIBLE_OR_UNCERTAIN_BASELINE
  \echo NO_MIGRATION_WAS_APPLIED
  -- ON_ERROR_STOP turns this intentional assertion failure into a nonzero
  -- process exit code while PostgreSQL rolls back the read-only transaction.
  select 1 / 0 as fail_closed_preflight_gate;
\endif

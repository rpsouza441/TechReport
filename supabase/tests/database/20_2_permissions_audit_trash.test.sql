-- Phase 20.2 Wave 0 security contract.
--
-- This suite is intentionally RED before migrations 0025-0027. Run it only
-- against an isolated database containing the repository migrations. Every
-- fixture and test-local object is enclosed by this transaction and rolled back.

begin;

create extension if not exists pgtap with schema extensions;

select plan(67);

-- Stable UUIDs make failures reproducible and make tenant boundaries obvious.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'tech.a1@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'tech.a2@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'manager.a@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'admin.a@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'tech.b@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated', 'app.admin@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000007', 'authenticated', 'authenticated', 'inactive@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000008', 'authenticated', 'authenticated', 'unaffiliated@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000009', 'authenticated', 'authenticated', 'dual.from.tech@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000010', 'authenticated', 'authenticated', 'dual.from.admin@example.test', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now());

insert into public.empresas (id, nome, ativo)
values
  ('21000000-0000-0000-0000-000000000001', 'Wave 0 Company A', true),
  ('21000000-0000-0000-0000-000000000002', 'Wave 0 Company B', true);

insert into public.tecnicos (id, empresa_id, user_id, nome, email, papel, ativo)
values
  ('22000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Tech A1', 'tech.a1@example.test', 'tecnico', true),
  ('22000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 'Tech A2', 'tech.a2@example.test', 'tecnico', true),
  ('22000000-0000-0000-0000-000000000003', '21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 'Manager A', 'manager.a@example.test', 'gerente', true),
  ('22000000-0000-0000-0000-000000000004', '21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004', 'Admin A', 'admin.a@example.test', 'admin_empresa', true),
  ('22000000-0000-0000-0000-000000000005', '21000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000005', 'Tech B', 'tech.b@example.test', 'tecnico', true),
  ('22000000-0000-0000-0000-000000000007', '21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000007', 'Inactive A', 'inactive@example.test', 'tecnico', false),
  ('22000000-0000-0000-0000-000000000009', '21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000009', 'Dual From Tech', 'dual.from.tech@example.test', 'tecnico', true);

insert into public.app_admins (id, user_id, nome, email, ativo)
values
  ('23000000-0000-0000-0000-000000000006', '20000000-0000-0000-0000-000000000006', 'App Admin', 'app.admin@example.test', true),
  ('23000000-0000-0000-0000-000000000010', '20000000-0000-0000-0000-000000000010', 'Dual From Admin', 'dual.from.admin@example.test', true);

create temporary table rat_restore_snapshot (
  rat_id uuid primary key,
  protected_row jsonb not null
) on commit drop;

grant select, insert on rat_restore_snapshot to authenticated;

set local role authenticated;

-- D-01: every active company role creates only a self-owned RAT.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select lives_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'W0-A1', 'Client A1', 'Owner baseline', 'completed', false, now())$$,
  'active technician creates a self-owned RAT'
);

select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
select lives_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'W0-A2', 'Client A2', 'Peer baseline', 'completed', false, now())$$,
  'second active technician creates a self-owned RAT'
);

select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000003","role":"authenticated"}', true);
select lives_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000003', '21000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', 'W0-AM', 'Client AM', 'Manager baseline', 'completed', false, now())$$,
  'active gerente creates a self-owned RAT'
);

select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000004","role":"authenticated"}', true);
select lives_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000004', '21000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000004', 'W0-AA', 'Client AA', 'Admin baseline', 'completed', false, now())$$,
  'active admin_empresa creates a self-owned RAT'
);

select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000005","role":"authenticated"}', true);
select lives_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000005', '21000000-0000-0000-0000-000000000002', '22000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000005', 'W0-B1', 'Client B1', 'Cross-company baseline', 'completed', false, now())$$,
  'second-company technician creates a self-owned RAT'
);

-- Ownership spoofing and non-member creation are denied.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select throws_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000101', '21000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'W0-SPOOF', 'Client', 'Spoof owner', 'draft', false, now())$$,
  null, null, 'technician cannot create a RAT owned by another member'
);
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000007","role":"authenticated"}', true);
select throws_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000102', '21000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-000000000007', '20000000-0000-0000-0000-000000000007', 'W0-INACTIVE', 'Client', 'Inactive create', 'draft', false, now())$$,
  null, null, 'inactive member cannot create a RAT'
);
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000008","role":"authenticated"}', true);
select throws_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000103', '21000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000008', 'W0-NONE', 'Client', 'Unaffiliated create', 'draft', false, now())$$,
  null, null, 'unaffiliated Auth user cannot create a RAT'
);

-- D-02/D-07 matrix: technician is owner-only.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select is((select count(*) from public.rats where id = '24000000-0000-0000-0000-000000000001'), 1::bigint, 'technician reads own RAT');
select is((select count(*) from public.rats where id = '24000000-0000-0000-0000-000000000002'), 0::bigint, 'technician cannot read same-company peer RAT');
select is((select count(*) from public.rats where id = '24000000-0000-0000-0000-000000000005'), 0::bigint, 'technician cannot read other-company RAT');
select lives_ok($$update public.rats set descricao = 'owner update' where id = '24000000-0000-0000-0000-000000000001'$$, 'technician updates own RAT');
select is((select descricao from public.rats where id = '24000000-0000-0000-0000-000000000001'), 'owner update', 'own update persists');
select lives_ok($$update public.rats set descricao = 'forbidden peer update' where id = '24000000-0000-0000-0000-000000000002'$$, 'peer update is safely filtered');

-- D-02/D-07 matrix: gerente can operate same-company RATs, not cross-company RATs.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000003","role":"authenticated"}', true);
select is((select count(*) from public.rats where id = '24000000-0000-0000-0000-000000000001'), 1::bigint, 'gerente reads same-company other RAT');
select is((select count(*) from public.rats where id = '24000000-0000-0000-0000-000000000005'), 0::bigint, 'gerente cannot read other-company RAT');
select lives_ok($$update public.rats set descricao = 'manager correction' where id = '24000000-0000-0000-0000-000000000001'$$, 'gerente updates same-company RAT');
select is((select descricao from public.rats where id = '24000000-0000-0000-0000-000000000001'), 'manager correction', 'gerente correction persists');
select lives_ok($$update public.rats set descricao = 'forbidden cross update' where id = '24000000-0000-0000-0000-000000000005'$$, 'cross-company update is safely filtered');

-- D-02/D-07 matrix: admin_empresa has the same company scope.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000004","role":"authenticated"}', true);
select is((select count(*) from public.rats where id = '24000000-0000-0000-0000-000000000002'), 1::bigint, 'admin_empresa reads same-company other RAT');
select is((select count(*) from public.rats where id = '24000000-0000-0000-0000-000000000005'), 0::bigint, 'admin_empresa cannot read other-company RAT');
select lives_ok($$update public.rats set descricao = 'admin correction' where id = '24000000-0000-0000-0000-000000000002'$$, 'admin_empresa updates same-company RAT');
select is((select descricao from public.rats where id = '24000000-0000-0000-0000-000000000002'), 'admin correction', 'admin_empresa correction persists');

-- D-03: app_admin and non-members have no RAT access in any direction.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000006","role":"authenticated"}', true);
select is((select count(*) from public.rats), 0::bigint, 'app_admin cannot read RATs');
select throws_ok(
  $$insert into public.rats (id, empresa_id, tecnico_id, criado_por_user_id, numero, cliente_nome, descricao, status, deletado, criado_em_dispositivo)
    values ('24000000-0000-0000-0000-000000000104', '21000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000006', 'W0-APPADMIN', 'Client', 'App admin create', 'draft', false, now())$$,
  null, null, 'app_admin cannot create a RAT'
);
select lives_ok($$update public.rats set descricao = 'app admin write' where id = '24000000-0000-0000-0000-000000000001'$$, 'app_admin update is safely filtered');
select results_eq($$delete from public.rats where id = '24000000-0000-0000-0000-000000000001' returning id$$, array[]::uuid[], 'app_admin cannot physically delete RAT');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000007","role":"authenticated"}', true);
select is((select count(*) from public.rats), 0::bigint, 'inactive member cannot read RATs');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000008","role":"authenticated"}', true);
select is((select count(*) from public.rats), 0::bigint, 'unaffiliated user cannot read RATs');

-- D-08: physical DELETE is denied even to an owner and a same-company superior.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select results_eq($$delete from public.rats where id = '24000000-0000-0000-0000-000000000001' returning id$$, array[]::uuid[], 'owner physical DELETE is denied');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000003","role":"authenticated"}', true);
select results_eq($$delete from public.rats where id = '24000000-0000-0000-0000-000000000002' returning id$$, array[]::uuid[], 'superior physical DELETE is denied');

-- D-07/D-09: soft-delete/restore scope and narrow transition preservation.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select lives_ok($$update public.rats set deletado = true where id = '24000000-0000-0000-0000-000000000001'$$, 'technician soft-deletes own RAT');
select is((select deletado from public.rats where id = '24000000-0000-0000-0000-000000000001'), true, 'own RAT is in trash');
insert into rat_restore_snapshot (rat_id, protected_row)
select id,
       to_jsonb(r) - array['deletado', 'updated_at', 'server_updated_at', 'ultimo_alterador_user_id', 'ultima_alteracao_em']
from public.rats r
where id = '24000000-0000-0000-0000-000000000001';
select lives_ok($$update public.rats set deletado = false where id = '24000000-0000-0000-0000-000000000001'$$, 'technician restores own RAT');
select is(
  (select to_jsonb(r) - array['deletado', 'updated_at', 'server_updated_at', 'ultimo_alterador_user_id', 'ultima_alteracao_em'] from public.rats r where id = '24000000-0000-0000-0000-000000000001'),
  (select protected_row from rat_restore_snapshot where rat_id = '24000000-0000-0000-0000-000000000001'),
  'restore preserves owner, creator, company, status, signature, reopen and every business field'
);
select throws_ok(
  $$update public.rats set deletado = true, status = 'draft' where id = '24000000-0000-0000-0000-000000000001'$$,
  null, null, 'soft delete rejects collateral business-field changes'
);
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000003","role":"authenticated"}', true);
select lives_ok($$update public.rats set deletado = true where id = '24000000-0000-0000-0000-000000000002'$$, 'gerente soft-deletes same-company RAT');
select lives_ok($$update public.rats set deletado = false where id = '24000000-0000-0000-0000-000000000002'$$, 'gerente restores same-company RAT');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000004","role":"authenticated"}', true);
select lives_ok($$update public.rats set deletado = true where id = '24000000-0000-0000-0000-000000000003'$$, 'admin_empresa soft-deletes same-company RAT');
select lives_ok($$update public.rats set deletado = false where id = '24000000-0000-0000-0000-000000000003'$$, 'admin_empresa restores same-company RAT');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select lives_ok($$update public.rats set deletado = true where id = '24000000-0000-0000-0000-000000000002'$$, 'peer soft delete is safely filtered');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000003","role":"authenticated"}', true);
select lives_ok($$update public.rats set deletado = true where id = '24000000-0000-0000-0000-000000000005'$$, 'cross-company soft delete is safely filtered');

-- D-04/D-05/D-10: server-owned audit for create, update, trash and restore.
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select ok((select count(*) > 0 from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' and event_type = 'created'), 'RAT creation emits a created audit event');
select ok((select count(*) > 0 from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' and event_type = 'updated'), 'every business update emits an updated audit event');
select ok((select count(*) > 0 from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' and event_type = 'trashed'), 'soft delete emits a trashed audit event');
select ok((select count(*) > 0 from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' and event_type = 'restored'), 'restore emits a restored audit event');
select is((select user_id from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' order by edited_at desc, id desc limit 1), '20000000-0000-0000-0000-000000000001'::uuid, 'audit actor comes from authenticated server context');
select is((select actor_name from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' order by edited_at desc, id desc limit 1), 'Tech A1', 'audit actor name is an immutable server snapshot');
select ok((select edited_at between transaction_timestamp() and clock_timestamp() + interval '1 second' from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' order by edited_at desc, id desc limit 1), 'audit time comes from the server clock');
select lives_ok($$update public.rats set origem_dispositivo = 'technical-only-change' where id = '24000000-0000-0000-0000-000000000001'$$, 'technical-only update is still audited');
select is((select event_type from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' order by edited_at desc, id desc limit 1), 'updated', 'technical-only UPDATE creates an audit event');
select ok(
  (select not (changes ?| array['updated_at', 'server_updated_at', 'sincronizado_em', 'origem_dispositivo', 'versao', 'ultimo_alterador_user_id', 'ultima_alteracao_em', 'created_at'])
   from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001' order by edited_at desc, id desc limit 1),
  'technical sync/time fields do not enter audit changes'
);

-- Forged client audit writes fail for INSERT, UPDATE and DELETE.
select throws_ok(
  $$insert into public.rat_audit_log (rat_id, user_id, edited_at, changes, event_type, actor_name)
    values ('24000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000006', '2000-01-01Z', '{"forged":true}', 'updated', 'Forged')$$,
  null, null, 'client cannot forge audit actor, time or diff'
);
select throws_ok($$update public.rat_audit_log set actor_name = 'Forged' where rat_id = '24000000-0000-0000-0000-000000000001'$$, null, null, 'client cannot mutate audit rows');
select throws_ok($$delete from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001'$$, null, null, 'client cannot delete audit rows');

-- D-06: audit visibility follows owner/company scope.
select is((select count(*) > 0 from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000001'), true, 'technician sees own RAT audit');
select is((select count(*) from public.rat_audit_log where rat_id = '24000000-0000-0000-0000-000000000002'), 0::bigint, 'technician cannot see peer audit');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000003","role":"authenticated"}', true);
select ok((select count(*) > 0 from public.rat_audit_log l join public.rats r on r.id = l.rat_id where r.empresa_id = '21000000-0000-0000-0000-000000000001'), 'gerente sees company audit');
select is((select count(*) from public.rat_audit_log l join public.rats r on r.id = l.rat_id where r.empresa_id = '21000000-0000-0000-0000-000000000002'), 0::bigint, 'gerente cannot see cross-company audit');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000004","role":"authenticated"}', true);
select ok((select count(*) > 0 from public.rat_audit_log), 'admin_empresa sees company audit');
select set_config('request.jwt.claims', '{"sub":"20000000-0000-0000-0000-000000000006","role":"authenticated"}', true);
select is((select count(*) from public.rat_audit_log), 0::bigint, 'app_admin sees no audit rows');

-- D-03: active identity exclusivity is enforced in both directions.
reset role;
select throws_ok(
  $$insert into public.app_admins (user_id, nome, email, ativo)
    values ('20000000-0000-0000-0000-000000000009', 'Forbidden dual admin', 'dual.from.tech@example.test', true)$$,
  null, null, 'active company member cannot become active app_admin'
);
select throws_ok(
  $$insert into public.tecnicos (empresa_id, user_id, nome, email, papel, ativo)
    values ('21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000010', 'Forbidden dual member', 'dual.from.admin@example.test', 'tecnico', true)$$,
  null, null, 'active app_admin cannot become active company member'
);

-- D-14: all phase SECURITY DEFINER functions touching protected tables are
-- hardened with a fixed search_path and trigger-only helpers have no PUBLIC EXECUTE.
select ok(
  not exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and (p.prosrc ilike '%rats%' or p.prosrc ilike '%rat_audit_log%' or p.prosrc ilike '%app_admins%' or p.prosrc ilike '%tecnicos%')
      and not coalesce(p.proconfig, array[]::text[]) && array['search_path=public', 'search_path=pg_catalog, public', 'search_path=public, pg_temp']
  ),
  'phase SECURITY DEFINER functions have a fixed search_path'
);
select ok(
  not exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('rats_guard_update', 'audit_rat_change')
      and has_function_privilege('public', p.oid, 'EXECUTE')
  ),
  'privileged trigger functions do not grant EXECUTE to PUBLIC'
);
select ok(to_regprocedure('public.rats_guard_update()') is not null, 'RAT transition guard function exists');
select ok(to_regprocedure('public.audit_rat_change()') is not null, 'server audit trigger function exists');

select * from finish();
rollback;

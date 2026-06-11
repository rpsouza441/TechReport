-- Cria tabela de trilha de auditoria para edições de RAT.
-- Registra: quem editou, o que mudou, quando.
--
-- Decisões aplicadas:
-- - Formato changes: { "campo": { "old": "...", "new": "..." } }
-- - Apenas campos que realmente mudaram são incluídos.
-- - Inserção: qualquer usuário autenticado com acesso à RAT (RLS filtra).
-- - Leitura: apenas admin empresa e gerente (RLS filtra).
-- - Técnico não dono que edita RAT gera registro.
-- - Dono editando própria RAT NÃO gera registro de auditoria.

begin;

create table if not exists public.rat_audit_log (
  id uuid primary key default gen_random_uuid(),
  rat_id uuid not null references public.rats(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete restrict,
  edited_at timestamptz not null default now(),
  changes jsonb not null,  -- { "campo": { "old": valor_antigo, "new": valor_novo } }
  created_at timestamptz not null default now()
);

-- Índice para buscar logs de uma RAT ordenados por data
create index if not exists rat_audit_log_rat_id_idx
  on public.rat_audit_log (rat_id, edited_at desc);

-- Índice para buscar logs de um usuário
create index if not exists rat_audit_log_user_id_idx
  on public.rat_audit_log (user_id, edited_at desc);

-- RLS: qualquer usuário autenticado pode inserir.
-- A RLS da tabela rats já garante que ele tem acesso à RAT.
alter table public.rat_audit_log enable row level security;

drop policy if exists rat_audit_log_insert_authorized on public.rat_audit_log;
create policy rat_audit_log_insert_authorized
  on public.rat_audit_log
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.rats r
      join public.tecnicos t on t.id = r.tecnico_id and t.empresa_id = r.empresa_id
      where r.id = rat_audit_log.rat_id
        and t.user_id = auth.uid()
        and t.ativo = true
    )
    or exists (
      select 1
      from public.tecnicos t
      where t.empresa_id = (
        select empresa_id from public.rats where id = rat_audit_log.rat_id
      )
      and t.user_id = auth.uid()
      and t.ativo = true
      and t.papel in ('gerente', 'admin_empresa')
    )
  );

-- RLS: apenas gerente e admin empresa podem ler o log.
drop policy if exists rat_audit_log_select_manager on public.rat_audit_log;
create policy rat_audit_log_select_manager
  on public.rat_audit_log
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.rats r
      join public.tecnicos t on t.empresa_id = r.empresa_id
      where r.id = rat_audit_log.rat_id
        and t.user_id = auth.uid()
        and t.ativo = true
        and t.papel in ('gerente', 'admin_empresa')
    )
  );

-- RLS: delete não é permitido para ninguém (log é imutável).
drop policy if exists rat_audit_log_no_delete on public.rat_audit_log;
create policy rat_audit_log_no_delete
  on public.rat_audit_log
  for delete
  to authenticated
  using (false);

commit;
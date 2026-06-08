-- ============================================================
-- Migration: 0016_update_own_display_name
-- Objetivo: permitir que o usuário atualize apenas seu próprio nome
-- em tecnicos e app_admins, via RLS.
--
-- Problema corrigido: tecnicos_update_by_admin (0006) e
-- tecnicos_update_own_nomeoriginalmente previstaeram duas policies
-- permissivas de UPDATE para o role authenticated, causando o warning
-- "multiple permissive policies" do Supabase Advisory.
--
-- Solução: unificar em uma única policy tecnicos_update que cobre
-- self-update + admin_empresa + app_admin.
-- ============================================================

-- ── tecnicos: policy unificada de UPDATE ────────────────────
-- Une as condições que antes estavam em duas policies separadas:
--   - tecnicos_update_by_admin (0006): admin_empresa/app_admin
--   - self-update: próprio registro ativo
-- Em uma única policy para evitar "multiple permissive policies".
-- ─────────────────────────────────────────────────────────────
drop policy if exists "tecnicos_update_by_admin" on tecnicos;
drop policy if exists "tecnicos_update_own_nome" on tecnicos;

create policy "tecnicos_update"
  on tecnicos
  for update
  to authenticated
  using (
    -- self-update: próprio registro, ativo
    (user_id = (select auth.uid()) and ativo = true)
    -- app_admin global
    or (select public.is_app_admin())
    -- admin_empresa: gerentes/admins da mesma empresa
    or (
      empresa_id = (select public.current_tecnico_empresa_id())
      and (select public.current_tecnico_papel()) = 'admin_empresa'
    )
  )
  with check (
    -- self-update: próprio registro, ativo
    (user_id = (select auth.uid()) and ativo = true)
    -- app_admin global
    or (select public.is_app_admin())
    -- admin_empresa: só pode criar gerente ou tecnico
    or (
      empresa_id = (select public.current_tecnico_empresa_id())
      and (select public.current_tecnico_papel()) = 'admin_empresa'
      and papel in ('gerente', 'tecnico')
    )
  );

-- ── app_admins: permitir self-update do campo nome ──────────
drop policy if exists "app_admins_update_own_nome" on app_admins;

create policy "app_admins_update_own_nome"
  on app_admins
  for update
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

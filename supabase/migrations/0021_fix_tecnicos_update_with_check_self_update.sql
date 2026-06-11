-- ============================================================
-- Migration: 0021_fix_tecnicos_update_with_check_self_update
--
-- Problema: a policy tecnicos_update (0016) tem self-update no
-- `using` mas NAO tem no `with check`. Isso faz com que
-- gerente/admin_empresa actualizando o proprio nome passem no
-- `using` (OK) mas falhem no `with check`, porque o bloco
-- admin_empresa so permite `papel in ('gerente', 'tecnico')`.
-- Um gerente ou admin_empresa tem papel='gerente' ou
-- papel='admin_empresa', que nao sao permitidos pelo with check
-- quando o caminho e' via admin_empresa (mesmo atualizando a
-- propria linha).
--
-- Solucao: replicar a condicao self-update tambem no `with check`,
-- exatamente como ja esta no `using`.
-- ============================================================

drop policy if exists "tecnicos_update" on public.tecnicos;

create policy "tecnicos_update"
  on public.tecnicos
  for update
  to authenticated
  using (
    -- self-update: proprio registro, ativo
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
    -- self-update: proprio registro, ativo  <-- ADICIONADO
    (user_id = (select auth.uid()) and ativo = true)
    -- app_admin global
    or (select public.is_app_admin())
    -- admin_empresa: so pode atualizar gerente ou tecnico
    or (
      empresa_id = (select public.current_tecnico_empresa_id())
      and (select public.current_tecnico_papel()) = 'admin_empresa'
      and papel in ('gerente', 'tecnico')
    )
  );
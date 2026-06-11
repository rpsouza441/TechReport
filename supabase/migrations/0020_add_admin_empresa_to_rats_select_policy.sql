begin;

-- Fix: rats_select_own_or_manager must include 'admin_empresa' and must
-- deny access to appAdmin (PO-01: appAdmin global has no RAT access).
drop policy if exists rats_select_own_or_manager on public.rats;

create policy rats_select_own_or_manager
on public.rats
for select
to authenticated
using (
  not (select public.is_app_admin())
  and (
    exists (
      select 1
      from public.tecnicos t
      where t.id = rats.tecnico_id
        and t.empresa_id = rats.empresa_id
        and t.user_id = (select auth.uid())
        and t.ativo = true
    )
    or exists (
      select 1
      from public.tecnicos t
      where t.empresa_id = rats.empresa_id
        and t.user_id = (select auth.uid())
        and t.ativo = true
        and t.papel in ('gerente', 'admin_empresa')
    )
  )
);

commit;
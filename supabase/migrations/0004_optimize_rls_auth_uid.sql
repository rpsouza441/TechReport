begin;

drop policy if exists empresas_select_own on public.empresas;
drop policy if exists tecnicos_select_self on public.tecnicos;

create policy tecnicos_select_self
on public.tecnicos
for select
to authenticated
using (
  user_id = (select auth.uid())
  and ativo = true
);

create policy empresas_select_own
on public.empresas
for select
to authenticated
using (
  ativo = true
  and exists (
    select 1
    from public.tecnicos t
    where t.empresa_id = empresas.id
      and t.user_id = (select auth.uid())
      and t.ativo = true
  )
);

drop policy if exists rats_select_own_or_manager on public.rats;
drop policy if exists rats_insert_company_member on public.rats;
drop policy if exists rats_update_company_member on public.rats;
drop policy if exists rats_delete_none on public.rats;

create policy rats_select_own_or_manager
on public.rats
for select
to authenticated
using (
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
      and t.papel in ('gerente')
  )
);

create policy rats_insert_company_member
on public.rats
for insert
to authenticated
with check (
  criado_por_user_id = (select auth.uid())
  and exists (
    select 1
    from public.tecnicos t
    where t.id = rats.tecnico_id
      and t.empresa_id = rats.empresa_id
      and t.user_id = (select auth.uid())
      and t.ativo = true
  )
);

create policy rats_update_company_member
on public.rats
for update
to authenticated
using (
  exists (
    select 1
    from public.tecnicos t
    where t.id = rats.tecnico_id
      and t.empresa_id = rats.empresa_id
      and t.user_id = (select auth.uid())
      and t.ativo = true
  )
)
with check (
  criado_por_user_id = (select auth.uid())
  and exists (
    select 1
    from public.tecnicos t
    where t.id = rats.tecnico_id
      and t.empresa_id = rats.empresa_id
      and t.user_id = (select auth.uid())
      and t.ativo = true
  )
);

create policy rats_delete_none
on public.rats
for delete
to authenticated
using (false);

commit;

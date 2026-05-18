begin;

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.app_admins a
    where a.user_id = (select auth.uid())
      and a.ativo = true
  );
$$;

create or replace function public.current_tecnico_empresa_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select t.empresa_id
  from public.tecnicos t
  where t.user_id = (select auth.uid())
    and t.ativo = true
  limit 1;
$$;

create or replace function public.current_tecnico_papel()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select t.papel
  from public.tecnicos t
  where t.user_id = (select auth.uid())
    and t.ativo = true
  limit 1;
$$;

drop policy if exists app_admins_select_self on public.app_admins;

create policy app_admins_select_self
on public.app_admins
for select
to authenticated
using (
  user_id = (select auth.uid())
  and ativo = true
);

drop policy if exists empresas_select_own_or_app_admin on public.empresas;
drop policy if exists empresas_insert_app_admin on public.empresas;
drop policy if exists empresas_update_app_admin on public.empresas;

create policy empresas_select_own_or_app_admin
on public.empresas
for select
to authenticated
using (
  (select public.is_app_admin())
  or (
    ativo = true
    and id = (select public.current_tecnico_empresa_id())
  )
);

create policy empresas_insert_app_admin
on public.empresas
for insert
to authenticated
with check ((select public.is_app_admin()));

create policy empresas_update_app_admin
on public.empresas
for update
to authenticated
using ((select public.is_app_admin()))
with check ((select public.is_app_admin()));

drop policy if exists tecnicos_select_allowed on public.tecnicos;
drop policy if exists tecnicos_insert_by_admin on public.tecnicos;
drop policy if exists tecnicos_update_by_admin on public.tecnicos;

create policy tecnicos_select_allowed
on public.tecnicos
for select
to authenticated
using (
  (select public.is_app_admin())
  or user_id = (select auth.uid())
  or (
    empresa_id = (select public.current_tecnico_empresa_id())
    and (select public.current_tecnico_papel()) = 'admin_empresa'
  )
);

create policy tecnicos_insert_by_admin
on public.tecnicos
for insert
to authenticated
with check (
  (select public.is_app_admin())
  or (
    empresa_id = (select public.current_tecnico_empresa_id())
    and (select public.current_tecnico_papel()) = 'admin_empresa'
    and papel in ('gerente', 'tecnico')
  )
);

create policy tecnicos_update_by_admin
on public.tecnicos
for update
to authenticated
using (
  (select public.is_app_admin())
  or (
    empresa_id = (select public.current_tecnico_empresa_id())
    and (select public.current_tecnico_papel()) = 'admin_empresa'
  )
)
with check (
  (select public.is_app_admin())
  or (
    empresa_id = (select public.current_tecnico_empresa_id())
    and (select public.current_tecnico_papel()) = 'admin_empresa'
    and papel in ('gerente', 'tecnico')
  )
);

commit;

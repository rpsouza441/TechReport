begin;

-- Consolida as duas policies de UPDATE em uma só para evitar
-- o aviso "multiple permissive policies for role authenticated".
-- Cada policy anterior é substituída por uma condição OR dentro da
-- nova policy unificada.

drop policy if exists empresas_update_admin_empresa on public.empresas;
drop policy if exists empresas_update_app_admin on public.empresas;

create policy empresas_update_authenticated
on public.empresas
for update
to authenticated
using (
  -- app_admin pode atualizar qualquer empresa
  (select public.is_app_admin())
  or
  -- admin_empresa pode atualizar apenas o nome da própria empresa
  (
    id = (select public.current_tecnico_empresa_id())
    and (select public.current_tecnico_papel()) = 'admin_empresa'
  )
)
with check (
  -- app_admin pode atualizar qualquer empresa
  (select public.is_app_admin())
  or
  -- admin_empresa pode atualizar apenas o nome da própria empresa
  (
    id = (select public.current_tecnico_empresa_id())
    and (select public.current_tecnico_papel()) = 'admin_empresa'
  )
);

commit;

begin;

-- Policy que permite admin_empresa fazer update em public.empresas
-- Apenas o campo nome da própria empresa (id = current_tecnico_empresa_id())
-- Papel deve ser 'admin_empresa'.
drop policy if exists empresas_update_admin_empresa on public.empresas;

create policy empresas_update_admin_empresa
on public.empresas
for update
to authenticated
using (
  id = (select public.current_tecnico_empresa_id())
  and (select public.current_tecnico_papel()) = 'admin_empresa'
)
with check (
  id = (select public.current_tecnico_empresa_id())
  and (select public.current_tecnico_papel()) = 'admin_empresa'
);

commit;

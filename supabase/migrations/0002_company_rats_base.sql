begin;

create table if not exists public.rats (
  id uuid primary key,
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  tecnico_id uuid not null references public.tecnicos(id),
  criado_por_user_id uuid not null references auth.users(id),
  numero text not null,
  cliente_nome text not null,
  descricao text not null,
  status text not null,
  deletado boolean not null default false,
  criado_em_dispositivo timestamptz not null,
  sincronizado_em timestamptz,
  origem_dispositivo text,
  versao integer not null default 1 check (versao > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  server_updated_at timestamptz not null default now()
);

create index if not exists rats_empresa_id_idx
on public.rats (empresa_id);

create index if not exists rats_tecnico_id_idx
on public.rats (tecnico_id);

create index if not exists rats_server_updated_at_idx
on public.rats (server_updated_at);

create or replace function public.set_server_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.server_updated_at = now();
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists rats_set_server_updated_at on public.rats;

create trigger rats_set_server_updated_at
before update on public.rats
for each row
execute function public.set_server_updated_at();

alter table public.rats enable row level security;

drop policy if exists rats_select_company_member on public.rats;
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
      and t.user_id = auth.uid()
      and t.ativo = true
  )
  or exists (
    select 1
    from public.tecnicos t
    where t.empresa_id = rats.empresa_id
      and t.user_id = auth.uid()
      and t.ativo = true
      and t.papel in ('gerente')
  )
);

create policy rats_insert_company_member
on public.rats
for insert
to authenticated
with check (
  criado_por_user_id = auth.uid()
  and exists (
    select 1
    from public.tecnicos t
    where t.id = rats.tecnico_id
      and t.empresa_id = rats.empresa_id
      and t.user_id = auth.uid()
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
      and t.user_id = auth.uid()
      and t.ativo = true
  )
)
with check (
  criado_por_user_id = auth.uid()
  and exists (
    select 1
    from public.tecnicos t
    where t.id = rats.tecnico_id
      and t.empresa_id = rats.empresa_id
      and t.user_id = auth.uid()
      and t.ativo = true
  )
);

create policy rats_delete_none
on public.rats
for delete
to authenticated
using (false);

commit;
begin;

create extension if not exists pgcrypto;

create table if not exists public.empresas (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique,
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tecnicos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  nome text not null,
  email text not null,
  papel text not null default 'tecnico',
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists tecnicos_empresa_id_idx
on public.tecnicos (empresa_id);

create index if not exists tecnicos_user_id_idx
on public.tecnicos (user_id);

alter table public.empresas enable row level security;
alter table public.tecnicos enable row level security;

drop policy if exists empresas_select_own on public.empresas;
drop policy if exists tecnicos_select_self on public.tecnicos;

create policy tecnicos_select_self
on public.tecnicos
for select
to authenticated
using (
  user_id = auth.uid()
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
      and t.user_id = auth.uid()
      and t.ativo = true
  )
);

commit;

begin;

create table if not exists public.tecnico_convites (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  email text not null,
  nome text not null,
  papel text not null,
  status text not null default 'pending',
  token_hash text not null,
  expires_at timestamptz not null,
  created_by_user_id uuid not null references auth.users(id) on delete cascade,
  accepted_by_user_id uuid references auth.users(id) on delete set null,
  accepted_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tecnico_convites_papel_check
    check (papel in ('admin_empresa', 'gerente', 'tecnico')),
  constraint tecnico_convites_status_check
    check (status in ('pending', 'accepted', 'expired', 'cancelled'))
);

create index if not exists tecnico_convites_empresa_id_idx
  on public.tecnico_convites (empresa_id);

create unique index if not exists tecnico_convites_pending_email_empresa_idx
  on public.tecnico_convites (empresa_id, lower(email))
  where status = 'pending';

alter table public.tecnico_convites enable row level security;

create or replace function public.is_admin_empresa_of(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tecnicos t
    where t.user_id = (select auth.uid())
      and t.ativo = true
      and t.papel = 'admin_empresa'
      and t.empresa_id = p_empresa_id
  );
$$;

drop policy if exists tecnico_convites_select_admin on public.tecnico_convites;

create policy tecnico_convites_select_admin
on public.tecnico_convites
for select
to authenticated
using (
  (select public.is_app_admin())
  or (select public.is_admin_empresa_of(empresa_id))
);

create or replace function public.create_tecnico_convite(
  p_email text,
  p_nome text,
  p_papel text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_email text;
  v_nome text;
  v_papel text;
  v_codigo text;
  v_hash text;
  v_convite_id uuid;
  v_expires_at timestamptz;
begin
  v_empresa_id := public.current_tecnico_empresa_id();

  if v_empresa_id is null
     or (select public.current_tecnico_papel()) <> 'admin_empresa' then
    raise exception 'Apenas admin da empresa pode convidar membros.';
  end if;

  v_email := lower(trim(p_email));
  v_nome := trim(p_nome);
  v_papel := trim(p_papel);

  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'Informe um e-mail válido.';
  end if;

  if v_nome = '' then
    raise exception 'Informe o nome do convidado.';
  end if;

  if v_papel not in ('admin_empresa', 'gerente', 'tecnico') then
    raise exception 'Papel inválido para convite.';
  end if;

  if exists (
    select 1
    from public.tecnicos t
    where t.empresa_id = v_empresa_id
      and lower(t.email) = v_email
      and t.ativo = true
  ) then
    raise exception 'Já existe um membro ativo com este e-mail.';
  end if;

  if exists (
    select 1
    from public.tecnico_convites c
    where c.empresa_id = v_empresa_id
      and lower(c.email) = v_email
      and c.status = 'pending'
      and c.expires_at > now()
  ) then
    raise exception 'Já existe convite pendente para este e-mail.';
  end if;

  v_codigo := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_hash := encode(extensions.digest(v_codigo, 'sha256'), 'hex');
  v_expires_at := now() + interval '7 days';

  insert into public.tecnico_convites (
    empresa_id,
    email,
    nome,
    papel,
    status,
    token_hash,
    expires_at,
    created_by_user_id
  )
  values (
    v_empresa_id,
    v_email,
    v_nome,
    v_papel,
    'pending',
    v_hash,
    v_expires_at,
    (select auth.uid())
  )
  returning id into v_convite_id;

  return jsonb_build_object(
    'convite_id', v_convite_id,
    'codigo_convite', v_codigo,
    'expires_at', v_expires_at
  );
end;
$$;

create or replace function public.cancel_tecnico_convite(p_convite_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select c.empresa_id
  into v_empresa_id
  from public.tecnico_convites c
  where c.id = p_convite_id;

  if v_empresa_id is null then
    raise exception 'Convite não encontrado.';
  end if;

  if not (
    (select public.is_app_admin())
    or (select public.is_admin_empresa_of(v_empresa_id))
  ) then
    raise exception 'Sem permissão para cancelar convite.';
  end if;

  delete from public.tecnico_convites
  where id = p_convite_id
    and status = 'pending';
end;
$$;

create or replace function public.validate_tecnico_convite(
  p_email text,
  p_codigo text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hash text;
  v_convite public.tecnico_convites%rowtype;
begin
  v_hash := encode(extensions.digest(upper(trim(p_codigo)), 'sha256'), 'hex');

  select *
  into v_convite
  from public.tecnico_convites c
  where c.token_hash = v_hash
  limit 1;

  if v_convite.id is null then
    raise exception 'Codigo de convite invalido.';
  end if;

  if v_convite.status <> 'pending' then
    raise exception 'Convite nao esta pendente.';
  end if;

  if v_convite.expires_at <= now() then
    update public.tecnico_convites
    set status = 'expired', updated_at = now()
    where id = v_convite.id;
    raise exception 'Convite expirado.';
  end if;

  if lower(v_convite.email) <> lower(trim(p_email)) then
    raise exception 'E-mail informado nao confere com o convite.';
  end if;

  return jsonb_build_object(
    'convite_id', v_convite.id,
    'email', v_convite.email,
    'nome', v_convite.nome,
    'papel', v_convite.papel,
    'expires_at', v_convite.expires_at
  );
end;
$$;

create or replace function public.accept_tecnico_convite(p_codigo text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_user_email text;
  v_hash text;
  v_convite public.tecnico_convites%rowtype;
  v_tecnico_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  select lower(u.email)
  into v_user_email
  from auth.users u
  where u.id = v_user_id;

  if v_user_email is null or v_user_email = '' then
    raise exception 'E-mail do usuário autenticado não encontrado.';
  end if;

  if exists (
    select 1
    from public.tecnicos t
    where t.user_id = v_user_id
      and t.ativo = true
  ) then
    raise exception 'Usuário já vinculado a uma empresa.';
  end if;

  v_hash := encode(extensions.digest(upper(trim(p_codigo)), 'sha256'), 'hex');

  select *
  into v_convite
  from public.tecnico_convites c
  where c.token_hash = v_hash
  limit 1;

  if v_convite.id is null then
    raise exception 'Código de convite inválido.';
  end if;

  if v_convite.status <> 'pending' then
    raise exception 'Convite não está pendente.';
  end if;

  if v_convite.expires_at <= now() then
    update public.tecnico_convites
    set status = 'expired', updated_at = now()
    where id = v_convite.id;
    raise exception 'Convite expirado.';
  end if;

  if lower(v_convite.email) <> v_user_email then
    raise exception 'E-mail autenticado não confere com o convite.';
  end if;

  insert into public.tecnicos (
    empresa_id,
    user_id,
    nome,
    email,
    papel,
    ativo,
    must_change_password
  )
  values (
    v_convite.empresa_id,
    v_user_id,
    v_convite.nome,
    v_convite.email,
    v_convite.papel,
    true,
    false
  )
  returning id into v_tecnico_id;

  update public.tecnico_convites
  set
    status = 'accepted',
    accepted_by_user_id = v_user_id,
    accepted_at = now(),
    updated_at = now()
  where id = v_convite.id;

  return v_tecnico_id;
end;
$$;

create or replace function public.update_tecnico_equipe(
  p_tecnico_id uuid,
  p_ativo boolean default null,
  p_must_change_password boolean default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.tecnicos%rowtype;
begin
  select *
  into v_row
  from public.tecnicos t
  where t.id = p_tecnico_id;

  if v_row.id is null then
    raise exception 'Membro da equipe não encontrado.';
  end if;

  if not (
    (select public.is_app_admin())
    or (select public.is_admin_empresa_of(v_row.empresa_id))
  ) then
    raise exception 'Sem permissão para alterar equipe.';
  end if;

  if v_row.papel = 'admin_empresa'
     and not (select public.is_app_admin()) then
    raise exception 'Somente admin global pode alterar admin da empresa.';
  end if;

  if v_row.user_id = (select auth.uid()) and p_ativo is false then
    raise exception 'Você não pode desativar a própria conta.';
  end if;

  update public.tecnicos
  set
    ativo = coalesce(p_ativo, ativo),
    must_change_password = coalesce(
      p_must_change_password,
      must_change_password
    ),
    updated_at = now()
  where id = p_tecnico_id;
end;
$$;

revoke all on function public.create_tecnico_convite(text, text, text) from public;
revoke all on function public.cancel_tecnico_convite(uuid) from public;
revoke all on function public.validate_tecnico_convite(text, text) from public;
revoke all on function public.accept_tecnico_convite(text) from public;
revoke all on function public.update_tecnico_equipe(uuid, boolean, boolean) from public;

grant execute on function public.create_tecnico_convite(text, text, text) to authenticated;
grant execute on function public.cancel_tecnico_convite(uuid) to authenticated;
grant execute on function public.validate_tecnico_convite(text, text) to anon, authenticated;
grant execute on function public.accept_tecnico_convite(text) to authenticated;
grant execute on function public.update_tecnico_equipe(uuid, boolean, boolean) to authenticated;

commit;

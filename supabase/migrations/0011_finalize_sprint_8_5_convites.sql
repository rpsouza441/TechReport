begin;

alter table public.tecnico_convites
drop constraint if exists tecnico_convites_papel_check;

alter table public.tecnico_convites
add constraint tecnico_convites_papel_check
check (papel in ('admin_empresa', 'gerente', 'tecnico'));

create extension if not exists pgcrypto with schema extensions;

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
    raise exception 'Convite nao encontrado.';
  end if;

  if not (
    (select public.is_app_admin())
    or (select public.is_admin_empresa_of(v_empresa_id))
  ) then
    raise exception 'Sem permissao para excluir convite.';
  end if;

  delete from public.tecnico_convites
  where id = p_convite_id
    and status = 'pending';
end;
$$;

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
    raise exception 'Informe um e-mail valido.';
  end if;

  if v_nome = '' then
    raise exception 'Informe o nome do convidado.';
  end if;

  if v_papel not in ('admin_empresa', 'gerente', 'tecnico') then
    raise exception 'Papel invalido para convite.';
  end if;

  if exists (
    select 1
    from public.tecnicos t
    where t.empresa_id = v_empresa_id
      and lower(t.email) = v_email
      and t.ativo = true
  ) then
    raise exception 'Ja existe um membro ativo com este e-mail.';
  end if;

  if exists (
    select 1
    from public.tecnico_convites c
    where c.empresa_id = v_empresa_id
      and lower(c.email) = v_email
      and c.status = 'pending'
      and c.expires_at > now()
  ) then
    raise exception 'Ja existe convite pendente para este e-mail.';
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

create or replace function public.create_empresa_convite(
  p_empresa_id uuid,
  p_email text,
  p_nome text,
  p_papel text default 'admin_empresa'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_nome text;
  v_papel text;
  v_codigo text;
  v_hash text;
  v_convite_id uuid;
  v_expires_at timestamptz;
begin
  if not (select public.is_app_admin()) then
    raise exception 'Apenas admin global pode convidar admin de empresa.';
  end if;

  if not exists (
    select 1
    from public.empresas e
    where e.id = p_empresa_id
  ) then
    raise exception 'Empresa nao encontrada.';
  end if;

  v_email := lower(trim(p_email));
  v_nome := trim(p_nome);
  v_papel := trim(p_papel);

  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'Informe um e-mail valido.';
  end if;

  if v_nome = '' then
    raise exception 'Informe o nome do convidado.';
  end if;

  if v_papel <> 'admin_empresa' then
    raise exception 'Admin global so pode iniciar convite de admin da empresa por aqui.';
  end if;

  if exists (
    select 1
    from public.tecnico_convites c
    where c.empresa_id = p_empresa_id
      and lower(c.email) = v_email
      and c.status = 'pending'
      and c.expires_at > now()
  ) then
    raise exception 'Ja existe convite pendente para este e-mail.';
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
    p_empresa_id,
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
    raise exception 'Membro da equipe nao encontrado.';
  end if;

  if not (
    (select public.is_app_admin())
    or (select public.is_admin_empresa_of(v_row.empresa_id))
  ) then
    raise exception 'Sem permissao para alterar equipe.';
  end if;

  if v_row.papel = 'admin_empresa'
     and not (select public.is_app_admin()) then
    raise exception 'Somente admin global pode alterar admin da empresa.';
  end if;

  if v_row.user_id = (select auth.uid()) and p_ativo is false then
    raise exception 'Voce nao pode desativar a propria conta.';
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

revoke all on function public.validate_tecnico_convite(text, text) from public;
revoke all on function public.create_empresa_convite(uuid, text, text, text)
from public;
grant execute on function public.validate_tecnico_convite(text, text)
to anon, authenticated;
grant execute on function public.create_empresa_convite(uuid, text, text, text)
to authenticated;

commit;

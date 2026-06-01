begin;

create extension if not exists pgcrypto with schema extensions;

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
  v_tecnico_empresa_id uuid;
  v_tecnico_email text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Usuario nao autenticado.';
  end if;

  select lower(u.email)
  into v_user_email
  from auth.users u
  where u.id = v_user_id;

  if v_user_email is null or v_user_email = '' then
    raise exception 'E-mail do usuario autenticado nao encontrado.';
  end if;

  v_hash := encode(extensions.digest(upper(trim(p_codigo)), 'sha256'), 'hex');

  select *
  into v_convite
  from public.tecnico_convites c
  where c.token_hash = v_hash
  limit 1;

  if v_convite.id is null then
    raise exception 'Codigo de convite invalido.';
  end if;

  if lower(v_convite.email) <> v_user_email then
    raise exception 'E-mail autenticado nao confere com o convite.';
  end if;

  select t.id, t.empresa_id, lower(t.email)
  into v_tecnico_id, v_tecnico_empresa_id, v_tecnico_email
  from public.tecnicos t
  where t.user_id = v_user_id
    and t.ativo = true
  limit 1;

  if v_tecnico_id is not null then
    if v_tecnico_empresa_id <> v_convite.empresa_id
       or v_tecnico_email <> v_user_email then
      raise exception 'Usuario ja vinculado a uma empresa.';
    end if;

    update public.tecnico_convites
    set
      status = 'accepted',
      accepted_by_user_id = v_user_id,
      accepted_at = coalesce(accepted_at, now()),
      updated_at = now()
    where id = v_convite.id
      and status = 'pending';

    return v_tecnico_id;
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

update public.tecnicos t
set
  must_change_password = false,
  updated_at = now()
where exists (
  select 1
  from public.tecnico_convites c
  where c.accepted_by_user_id = t.user_id
    and c.status = 'accepted'
);

commit;

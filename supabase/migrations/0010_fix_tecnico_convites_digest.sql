begin;

-- pgcrypto (digest/encode) lives in the extensions schema on Supabase.
-- 0009 used digest() with search_path = public, which fails at runtime.

create extension if not exists pgcrypto with schema extensions;

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

  if v_papel not in ('gerente', 'tecnico') then
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
    true
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

commit;

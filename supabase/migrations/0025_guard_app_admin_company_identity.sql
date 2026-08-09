begin;

-- D-03 is fail-closed: operators must resolve existing conflicts explicitly.
-- The migration never chooses a profile or mutates either side of the conflict.
do $identity_precondition$
begin
  if exists (
    select 1
    from public.tecnicos as t
    join public.app_admins as a
      on a.user_id = t.user_id
    where t.ativo = true
      and a.ativo = true
  ) then
    raise exception using
      errcode = 'P2003',
      message = 'Existem usuarios com perfis ativos de app_admin e empresa.';
  end if;
end;
$identity_precondition$;

create or replace function public.guard_app_admin_company_identity()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.ativo = true then
    -- Serialize both profile activation paths for this Auth user. Without this
    -- lock, concurrent inserts into the two tables could both pass their check.
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(new.user_id::text, 2003)
    );

    if exists (
      select 1
      from public.tecnicos as t
      where t.user_id = new.user_id
        and t.ativo = true
    ) then
      raise exception using
        errcode = 'P2003',
        message = 'Usuario ja possui perfil ativo em uma empresa.';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.guard_tecnico_app_admin_identity()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.ativo = true then
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(new.user_id::text, 2003)
    );

    if exists (
      select 1
      from public.app_admins as a
      where a.user_id = new.user_id
        and a.ativo = true
    ) then
      raise exception using
        errcode = 'P2003',
        message = 'Usuario ja possui perfil ativo de app_admin.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists app_admins_guard_company_identity
on public.app_admins;

create trigger app_admins_guard_company_identity
before insert or update of user_id, ativo
on public.app_admins
for each row
execute function public.guard_app_admin_company_identity();

drop trigger if exists tecnicos_guard_app_admin_identity
on public.tecnicos;

create trigger tecnicos_guard_app_admin_identity
before insert or update of user_id, ativo
on public.tecnicos
for each row
execute function public.guard_tecnico_app_admin_identity();

create or replace function public.accept_tecnico_convite(p_codigo text)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
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

  select pg_catalog.lower(u.email)
  into v_user_email
  from auth.users as u
  where u.id = v_user_id;

  if v_user_email is null or v_user_email = '' then
    raise exception 'E-mail do usuario autenticado nao encontrado.';
  end if;

  if exists (
    select 1
    from public.app_admins as a
    left join auth.users as u
      on u.id = a.user_id
    where a.ativo = true
      and (
        a.user_id = v_user_id
        or pg_catalog.lower(a.email) = v_user_email
        or pg_catalog.lower(u.email) = v_user_email
      )
  ) then
    raise exception using
      errcode = 'P2003',
      message = 'App admin ativo nao pode aceitar convite de empresa.';
  end if;

  v_hash := pg_catalog.encode(
    extensions.digest(pg_catalog.upper(pg_catalog.btrim(p_codigo)), 'sha256'),
    'hex'
  );

  select *
  into v_convite
  from public.tecnico_convites as c
  where c.token_hash = v_hash
  limit 1;

  if v_convite.id is null then
    raise exception 'Codigo de convite invalido.';
  end if;

  if pg_catalog.lower(v_convite.email) <> v_user_email then
    raise exception 'E-mail autenticado nao confere com o convite.';
  end if;

  select t.id, t.empresa_id, pg_catalog.lower(t.email)
  into v_tecnico_id, v_tecnico_empresa_id, v_tecnico_email
  from public.tecnicos as t
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
      accepted_at = pg_catalog.coalesce(accepted_at, pg_catalog.now()),
      updated_at = pg_catalog.now()
    where id = v_convite.id
      and status = 'pending';

    return v_tecnico_id;
  end if;

  if v_convite.status <> 'pending' then
    raise exception 'Convite nao esta pendente.';
  end if;

  if v_convite.expires_at <= pg_catalog.now() then
    update public.tecnico_convites
    set status = 'expired', updated_at = pg_catalog.now()
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
    accepted_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  where id = v_convite.id;

  return v_tecnico_id;
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
set search_path = pg_catalog, public
as $$
declare
  v_empresa_id uuid;
  v_current_papel text;
  v_email text;
  v_nome text;
  v_papel text;
  v_codigo text;
  v_hash text;
  v_convite_id uuid;
  v_expires_at timestamptz;
begin
  v_empresa_id := public.current_tecnico_empresa_id();
  v_current_papel := public.current_tecnico_papel();

  if v_empresa_id is null
     or v_current_papel not in ('admin_empresa', 'gerente') then
    raise exception 'Apenas admin da empresa ou gerente pode convidar membros.';
  end if;

  v_email := pg_catalog.lower(pg_catalog.btrim(p_email));
  v_nome := pg_catalog.btrim(p_nome);
  v_papel := pg_catalog.btrim(p_papel);

  if v_email = '' or pg_catalog.strpos(v_email, '@') = 0 then
    raise exception 'Informe um e-mail valido.';
  end if;

  if v_nome = '' then
    raise exception 'Informe o nome do convidado.';
  end if;

  if v_papel not in ('admin_empresa', 'gerente', 'tecnico') then
    raise exception 'Papel invalido para convite.';
  end if;

  if v_current_papel = 'gerente' and v_papel <> 'tecnico' then
    raise exception 'Gerente pode convidar apenas tecnico.';
  end if;

  if exists (
    select 1
    from public.app_admins as a
    left join auth.users as u
      on u.id = a.user_id
    where a.ativo = true
      and (
        pg_catalog.lower(a.email) = v_email
        or pg_catalog.lower(u.email) = v_email
      )
  ) then
    raise exception using
      errcode = 'P2003',
      message = 'App admin ativo nao pode receber convite de empresa.';
  end if;

  if exists (
    select 1
    from public.tecnicos as t
    where t.empresa_id = v_empresa_id
      and pg_catalog.lower(t.email) = v_email
      and t.ativo = true
  ) then
    raise exception 'Ja existe um membro ativo com este e-mail.';
  end if;

  if exists (
    select 1
    from public.tecnico_convites as c
    where c.empresa_id = v_empresa_id
      and pg_catalog.lower(c.email) = v_email
      and c.status = 'pending'
      and c.expires_at > pg_catalog.now()
  ) then
    raise exception 'Ja existe convite pendente para este e-mail.';
  end if;

  v_codigo := pg_catalog.upper(
    pg_catalog.substr(
      pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', ''),
      1,
      8
    )
  );
  v_hash := pg_catalog.encode(extensions.digest(v_codigo, 'sha256'), 'hex');
  v_expires_at := pg_catalog.now() + interval '7 days';

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
    auth.uid()
  )
  returning id into v_convite_id;

  return pg_catalog.jsonb_build_object(
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
set search_path = pg_catalog, public
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
  if not public.is_app_admin() then
    raise exception 'Apenas admin global pode convidar admin de empresa.';
  end if;

  if not exists (
    select 1
    from public.empresas as e
    where e.id = p_empresa_id
  ) then
    raise exception 'Empresa nao encontrada.';
  end if;

  v_email := pg_catalog.lower(pg_catalog.btrim(p_email));
  v_nome := pg_catalog.btrim(p_nome);
  v_papel := pg_catalog.btrim(p_papel);

  if v_email = '' or pg_catalog.strpos(v_email, '@') = 0 then
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
    from public.app_admins as a
    left join auth.users as u
      on u.id = a.user_id
    where a.ativo = true
      and (
        pg_catalog.lower(a.email) = v_email
        or pg_catalog.lower(u.email) = v_email
      )
  ) then
    raise exception using
      errcode = 'P2003',
      message = 'App admin ativo nao pode receber convite de empresa.';
  end if;

  if exists (
    select 1
    from public.tecnico_convites as c
    where c.empresa_id = p_empresa_id
      and pg_catalog.lower(c.email) = v_email
      and c.status = 'pending'
      and c.expires_at > pg_catalog.now()
  ) then
    raise exception 'Ja existe convite pendente para este e-mail.';
  end if;

  v_codigo := pg_catalog.upper(
    pg_catalog.substr(
      pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', ''),
      1,
      8
    )
  );
  v_hash := pg_catalog.encode(extensions.digest(v_codigo, 'sha256'), 'hex');
  v_expires_at := pg_catalog.now() + interval '7 days';

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
    auth.uid()
  )
  returning id into v_convite_id;

  return pg_catalog.jsonb_build_object(
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
set search_path = pg_catalog, public
as $$
declare
  v_row public.tecnicos%rowtype;
  v_current_empresa_id uuid;
  v_current_papel text;
begin
  select *
  into v_row
  from public.tecnicos as t
  where t.id = p_tecnico_id;

  if v_row.id is null then
    raise exception 'Membro da equipe nao encontrado.';
  end if;

  v_current_empresa_id := public.current_tecnico_empresa_id();
  v_current_papel := public.current_tecnico_papel();

  if not (
    public.is_app_admin()
    or public.is_admin_empresa_of(v_row.empresa_id)
    or (
      v_current_empresa_id = v_row.empresa_id
      and v_current_papel = 'gerente'
      and v_row.papel = 'tecnico'
    )
  ) then
    raise exception 'Sem permissao para alterar equipe.';
  end if;

  if v_row.papel = 'admin_empresa'
     and not public.is_app_admin() then
    raise exception 'Somente admin global pode alterar admin da empresa.';
  end if;

  if v_current_papel = 'gerente' and v_row.papel <> 'tecnico' then
    raise exception 'Gerente pode alterar apenas tecnico.';
  end if;

  if v_row.user_id = auth.uid() and p_ativo is false then
    raise exception 'Voce nao pode desativar a propria conta.';
  end if;

  if pg_catalog.coalesce(p_ativo, v_row.ativo) = true
     and exists (
       select 1
       from public.app_admins as a
       left join auth.users as u
         on u.id = a.user_id
       where a.ativo = true
         and (
           a.user_id = v_row.user_id
           or pg_catalog.lower(a.email) = pg_catalog.lower(v_row.email)
           or pg_catalog.lower(u.email) = pg_catalog.lower(v_row.email)
         )
     ) then
    raise exception using
      errcode = 'P2003',
      message = 'App admin ativo nao pode ser reativado como membro de empresa.';
  end if;

  update public.tecnicos
  set
    ativo = pg_catalog.coalesce(p_ativo, ativo),
    must_change_password = pg_catalog.coalesce(
      p_must_change_password,
      must_change_password
    ),
    updated_at = pg_catalog.now()
  where id = p_tecnico_id;
end;
$$;

revoke all on function public.guard_app_admin_company_identity() from public;
revoke all on function public.guard_app_admin_company_identity() from anon;
revoke all on function public.guard_app_admin_company_identity() from authenticated;
revoke all on function public.guard_tecnico_app_admin_identity() from public;
revoke all on function public.guard_tecnico_app_admin_identity() from anon;
revoke all on function public.guard_tecnico_app_admin_identity() from authenticated;

revoke all on function public.accept_tecnico_convite(text) from public;
revoke all on function public.accept_tecnico_convite(text) from anon;
revoke all on function public.create_tecnico_convite(text, text, text) from public;
revoke all on function public.create_tecnico_convite(text, text, text) from anon;
revoke all on function public.create_empresa_convite(uuid, text, text, text)
from public;
revoke all on function public.create_empresa_convite(uuid, text, text, text)
from anon;
revoke all on function public.update_tecnico_equipe(uuid, boolean, boolean)
from public;
revoke all on function public.update_tecnico_equipe(uuid, boolean, boolean)
from anon;

grant execute on function public.accept_tecnico_convite(text)
to authenticated;
grant execute on function public.create_tecnico_convite(text, text, text)
to authenticated;
grant execute on function public.create_empresa_convite(uuid, text, text, text)
to authenticated;
grant execute on function public.update_tecnico_equipe(uuid, boolean, boolean)
to authenticated;

commit;

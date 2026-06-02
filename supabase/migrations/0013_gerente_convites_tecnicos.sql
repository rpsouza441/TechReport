begin;

create or replace function public.is_equipe_viewer_of(p_empresa_id uuid)
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
      and t.empresa_id = p_empresa_id
      and t.papel in ('admin_empresa', 'gerente')
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
  or (
    papel = 'tecnico'
    and (select public.is_equipe_viewer_of(empresa_id))
  )
);

drop policy if exists tecnicos_select_allowed on public.tecnicos;

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
  or (
    empresa_id = (select public.current_tecnico_empresa_id())
    and (select public.current_tecnico_papel()) = 'gerente'
    and papel = 'tecnico'
  )
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

  if v_current_papel = 'gerente' and v_papel <> 'tecnico' then
    raise exception 'Gerente pode convidar apenas tecnico.';
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

create or replace function public.cancel_tecnico_convite(p_convite_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_convite public.tecnico_convites%rowtype;
begin
  select *
  into v_convite
  from public.tecnico_convites c
  where c.id = p_convite_id;

  if v_convite.id is null then
    raise exception 'Convite nao encontrado.';
  end if;

  if not (
    (select public.is_app_admin())
    or (select public.is_admin_empresa_of(v_convite.empresa_id))
    or (
      v_convite.papel = 'tecnico'
      and (select public.is_equipe_viewer_of(v_convite.empresa_id))
    )
  ) then
    raise exception 'Sem permissao para excluir convite.';
  end if;

  delete from public.tecnico_convites
  where id = p_convite_id
    and status = 'pending';
end;
$$;

revoke all on function public.is_equipe_viewer_of(uuid) from public;
grant execute on function public.is_equipe_viewer_of(uuid) to authenticated;

commit;

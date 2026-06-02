begin;

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
  v_current_empresa_id uuid;
  v_current_papel text;
begin
  select *
  into v_row
  from public.tecnicos t
  where t.id = p_tecnico_id;

  if v_row.id is null then
    raise exception 'Membro da equipe nao encontrado.';
  end if;

  v_current_empresa_id := public.current_tecnico_empresa_id();
  v_current_papel := public.current_tecnico_papel();

  if not (
    (select public.is_app_admin())
    or (select public.is_admin_empresa_of(v_row.empresa_id))
    or (
      v_current_empresa_id = v_row.empresa_id
      and v_current_papel = 'gerente'
      and v_row.papel = 'tecnico'
    )
  ) then
    raise exception 'Sem permissao para alterar equipe.';
  end if;

  if v_row.papel = 'admin_empresa'
     and not (select public.is_app_admin()) then
    raise exception 'Somente admin global pode alterar admin da empresa.';
  end if;

  if v_current_papel = 'gerente' and v_row.papel <> 'tecnico' then
    raise exception 'Gerente pode alterar apenas tecnico.';
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

commit;

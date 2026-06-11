-- ============================================================
-- Migration: 0022_update_own_display_name_rpc
--
-- Centraliza a troca do proprio nome em uma funcao SECURITY DEFINER.
-- Evita falhas por cliente sem sessao PostgREST restaurada e remove a
-- dependencia de updates diretos nas tabelas via RLS.
-- ============================================================

create or replace function public.update_own_display_name(p_nome text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_nome text := btrim(coalesce(p_nome, ''));
  v_updated_name text;
begin
  if v_user_id is null then
    raise exception 'Sessao expirada. Entre novamente.'
      using errcode = '28000';
  end if;

  if v_nome = '' then
    raise exception 'Informe o nome.'
      using errcode = '22023';
  end if;

  if char_length(v_nome) > 120 then
    raise exception 'O nome deve ter no maximo 120 caracteres.'
      using errcode = '22023';
  end if;

  with updated_tecnicos as (
    update public.tecnicos
       set nome = v_nome
     where user_id = v_user_id
       and ativo = true
     returning nome
  )
  select nome
    into v_updated_name
    from updated_tecnicos
   limit 1;

  if v_updated_name is not null then
    return v_updated_name;
  end if;

  with updated_app_admins as (
    update public.app_admins
       set nome = v_nome
     where user_id = v_user_id
       and ativo = true
     returning nome
  )
  select nome
    into v_updated_name
    from updated_app_admins
   limit 1;

  if v_updated_name is not null then
    return v_updated_name;
  end if;

  raise exception 'Perfil ativo nao encontrado para este usuario.'
    using errcode = 'P0002';
end;
$$;

grant execute on function public.update_own_display_name(text) to authenticated;

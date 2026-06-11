-- ============================================================
-- Migration: 0023_update_display_name_all_profiles
--
-- Ajusta update_own_display_name para usuarios com mais de um perfil ativo.
-- Ex.: app_admin que tambem tem vinculo em tecnicos. A 0022 retornava apos
-- atualizar tecnicos e deixava app_admins com nome antigo.
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
  v_updated_tecnico boolean := false;
  v_updated_app_admin boolean := false;
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

  update public.tecnicos
     set nome = v_nome
   where user_id = v_user_id
     and ativo = true;

  v_updated_tecnico := found;

  update public.app_admins
     set nome = v_nome
   where user_id = v_user_id
     and ativo = true;

  v_updated_app_admin := found;

  if v_updated_tecnico or v_updated_app_admin then
    return v_nome;
  end if;

  raise exception 'Perfil ativo nao encontrado para este usuario.'
    using errcode = 'P0002';
end;
$$;

grant execute on function public.update_own_display_name(text) to authenticated;

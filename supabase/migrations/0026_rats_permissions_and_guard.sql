begin;

-- D-01: every active company member creates only a RAT owned by their own
-- membership and authenticated user. Global app admins never access RATs.
drop policy if exists rats_insert_company_member on public.rats;

create policy rats_insert_company_member
on public.rats
for insert
to authenticated
with check (
  not (select public.is_app_admin())
  and criado_por_user_id = (select auth.uid())
  and exists (
    select 1
    from public.tecnicos as t
    where t.id = rats.tecnico_id
      and t.empresa_id = rats.empresa_id
      and t.user_id = (select auth.uid())
      and t.ativo = true
      and t.papel in ('tecnico', 'gerente', 'admin_empresa')
  )
);

-- D-02/D-07: owners update their own RATs; active managers and company admins
-- update RATs from their company. The guard below prevents ownership transfer.
drop policy if exists rats_update_company_member on public.rats;

create policy rats_update_company_member
on public.rats
for update
to authenticated
using (
  not (select public.is_app_admin())
  and (
    exists (
      select 1
      from public.tecnicos as t
      where t.id = rats.tecnico_id
        and t.empresa_id = rats.empresa_id
        and t.user_id = (select auth.uid())
        and t.ativo = true
        and t.papel in ('tecnico', 'gerente', 'admin_empresa')
    )
    or exists (
      select 1
      from public.tecnicos as t
      where t.empresa_id = rats.empresa_id
        and t.user_id = (select auth.uid())
        and t.ativo = true
        and t.papel in ('gerente', 'admin_empresa')
    )
  )
)
with check (
  not (select public.is_app_admin())
  and (
    exists (
      select 1
      from public.tecnicos as t
      where t.id = rats.tecnico_id
        and t.empresa_id = rats.empresa_id
        and t.user_id = (select auth.uid())
        and t.ativo = true
        and t.papel in ('tecnico', 'gerente', 'admin_empresa')
    )
    or exists (
      select 1
      from public.tecnicos as t
      where t.empresa_id = rats.empresa_id
        and t.user_id = (select auth.uid())
        and t.ativo = true
        and t.papel in ('gerente', 'admin_empresa')
    )
  )
);

-- D-08: physical deletion remains unavailable to every authenticated actor.
drop policy if exists rats_delete_none on public.rats;

create policy rats_delete_none
on public.rats
for delete
to authenticated
using (false);

create or replace function public.rats_guard_update()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_is_delete_transition boolean := old.deletado = false and new.deletado = true;
  v_is_restore_transition boolean := old.deletado = true and new.deletado = false;
begin
  if new.id is distinct from old.id then
    raise exception 'RAT id is immutable.';
  end if;

  if new.empresa_id is distinct from old.empresa_id then
    raise exception 'RAT empresa_id is immutable.';
  end if;

  if new.tecnico_id is distinct from old.tecnico_id then
    raise exception 'RAT tecnico_id is immutable.';
  end if;

  if new.criado_por_user_id is distinct from old.criado_por_user_id then
    raise exception 'RAT criado_por_user_id is immutable.';
  end if;

  if new.created_at is distinct from old.created_at then
    raise exception 'RAT created_at is immutable.';
  end if;

  if new.numero is distinct from old.numero then
    raise exception 'RAT numero is immutable.';
  end if;

  if v_actor_user_id is null then
    raise exception 'Authenticated RAT update actor is required.';
  end if;

  if v_is_delete_transition or v_is_restore_transition then
    if public.is_app_admin()
       or not exists (
         select 1
         from public.tecnicos as t
         where t.user_id = v_actor_user_id
           and t.empresa_id = old.empresa_id
           and t.ativo = true
           and (
             t.id = old.tecnico_id
             or t.papel in ('gerente', 'admin_empresa')
           )
       ) then
      raise exception 'Actor cannot delete or restore this RAT.';
    end if;

    -- Delete and restore are narrow transitions. Server-owned metadata and
    -- timestamp columns are deliberately ignored here because this trigger and
    -- rats_set_server_updated_at replace those values after authorization.
    if (
      to_jsonb(new) - array[
        'deletado',
        'updated_at',
        'server_updated_at',
        'ultimo_alterador_user_id',
        'ultima_alteracao_em'
      ]
    ) is distinct from (
      to_jsonb(old) - array[
        'deletado',
        'updated_at',
        'server_updated_at',
        'ultimo_alterador_user_id',
        'ultima_alteracao_em'
      ]
    ) then
      raise exception 'RAT delete or restore cannot change other fields.';
    end if;
  end if;

  -- T-20.2-17: actor and time always come from Auth and the server clock.
  new.ultimo_alterador_user_id := v_actor_user_id;
  new.ultima_alteracao_em := pg_catalog.now();

  return new;
end;
$$;

revoke all on function public.rats_guard_update() from public;
revoke all on function public.rats_guard_update() from anon;
revoke all on function public.rats_guard_update() from authenticated;

drop trigger if exists rats_00_guard_update on public.rats;

-- PostgreSQL fires same-kind triggers in name order. rats_00_guard_update runs
-- before rats_set_server_updated_at, so validation precedes timestamp mutation.
create trigger rats_00_guard_update
before update on public.rats
for each row
execute function public.rats_guard_update();

commit;

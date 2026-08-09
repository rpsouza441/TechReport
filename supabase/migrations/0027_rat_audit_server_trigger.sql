begin;

-- D-13/D-15: extend the existing audit table without rewriting legacy rows.
-- The NOT VALID constraint is enforced for new rows while preserving any
-- historical values that may predate the server-owned event contract.
alter table public.rat_audit_log
  add column if not exists event_type text;

alter table public.rat_audit_log
  add column if not exists actor_name text;

alter table public.rat_audit_log
  drop constraint if exists rat_audit_log_event_type_check;

alter table public.rat_audit_log
  add constraint rat_audit_log_event_type_check
  check (event_type is null or event_type in ('created', 'updated', 'trashed', 'restored'))
  not valid;

-- Stable cursor order for RAT history pages, including equal timestamps.
create index if not exists rat_audit_log_rat_page_idx
  on public.rat_audit_log (rat_id, edited_at desc, id desc);

-- T-20.2-18/T-20.2-19: audit rows are written only by the server trigger.
drop policy if exists rat_audit_log_insert_authorized on public.rat_audit_log;
drop policy if exists rat_audit_log_select_manager on public.rat_audit_log;
drop policy if exists rat_audit_log_no_delete on public.rat_audit_log;
drop policy if exists rat_audit_log_select_scope on public.rat_audit_log;

revoke all on table public.rat_audit_log from public;
revoke all on table public.rat_audit_log from anon;
revoke all on table public.rat_audit_log from authenticated;

grant select on table public.rat_audit_log to authenticated;

alter table public.rat_audit_log enable row level security;

-- D-06/T-20.2-20: an active technician reads their own RAT history; active
-- managers and company admins read history for their company. Global app
-- admins, inactive members and actors from another company fail closed.
create policy rat_audit_log_select_scope
on public.rat_audit_log
for select
to authenticated
using (
  not (select public.is_app_admin())
  and exists (
    select 1
    from public.rats as r
    join public.tecnicos as t
      on t.empresa_id = r.empresa_id
    where r.id = rat_audit_log.rat_id
      and t.user_id = (select auth.uid())
      and t.ativo = true
      and (
        t.id = r.tecnico_id
        or t.papel in ('gerente', 'admin_empresa')
      )
  )
);

-- D-04/D-05/D-10: derive actor, actor snapshot, event time and field diff at
-- the database boundary. The client never supplies any audit envelope value.
create or replace function public.audit_rat_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_actor_user_id uuid := auth.uid();
  v_actor_name text;
  v_event_type text;
  v_old_business jsonb;
  v_new_business jsonb;
  v_changes jsonb;
  v_excluded_fields constant text[] := array[
    'updated_at',
    'server_updated_at',
    'sincronizado_em',
    'origem_dispositivo',
    'versao',
    'ultimo_alterador_user_id',
    'ultima_alteracao_em',
    'created_at',
    'deletado'
  ];
begin
  if v_actor_user_id is null then
    raise exception 'Authenticated RAT audit actor is required.';
  end if;

  select t.nome
  into v_actor_name
  from public.tecnicos as t
  where t.user_id = v_actor_user_id
    and t.empresa_id = new.empresa_id
    and t.ativo = true
    and t.papel in ('tecnico', 'gerente', 'admin_empresa')
  order by t.id
  limit 1;

  if v_actor_name is null then
    raise exception 'Active company profile is required for RAT audit.';
  end if;

  v_new_business := to_jsonb(new) - v_excluded_fields;

  if tg_op = 'INSERT' then
    v_event_type := 'created';

    select coalesce(
      jsonb_object_agg(
        item.key,
        jsonb_build_object('old', null, 'new', item.value)
      ),
      '{}'::jsonb
    )
    into v_changes
    from jsonb_each(v_new_business) as item;
  else
    v_old_business := to_jsonb(old) - v_excluded_fields;

    v_event_type := case
      when old.deletado = false and new.deletado = true then 'trashed'
      when old.deletado = true and new.deletado = false then 'restored'
      else 'updated'
    end;

    select coalesce(
      jsonb_object_agg(
        new_item.key,
        jsonb_build_object('old', old_item.value, 'new', new_item.value)
      ),
      '{}'::jsonb
    )
    into v_changes
    from jsonb_each(v_new_business) as new_item
    join jsonb_each(v_old_business) as old_item
      on old_item.key = new_item.key
    where new_item.value is distinct from old_item.value;
  end if;

  insert into public.rat_audit_log (
    rat_id,
    user_id,
    edited_at,
    changes,
    event_type,
    actor_name
  )
  values (
    new.id,
    v_actor_user_id,
    clock_timestamp(),
    v_changes,
    v_event_type,
    v_actor_name
  );

  return new;
end;
$$;

revoke all on function public.audit_rat_change() from public;
revoke all on function public.audit_rat_change() from anon;
revoke all on function public.audit_rat_change() from authenticated;

drop trigger if exists rats_audit_server_change on public.rats;

create trigger rats_audit_server_change
after insert or update on public.rats
for each row
execute function public.audit_rat_change();

commit;

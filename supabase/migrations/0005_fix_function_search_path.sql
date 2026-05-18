begin;

create or replace function public.set_server_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.server_updated_at = now();
  new.updated_at = now();
  return new;
end;
$$;

commit;

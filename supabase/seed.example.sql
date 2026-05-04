-- Exemplo de seed manual para desenvolvimento.
-- Troque os placeholders antes de executar no Supabase SQL Editor.
-- Nao versionar emails, empresas ou usuarios reais neste arquivo.

begin;

insert into public.empresas (nome)
values ('<NOME_DA_EMPRESA>')
on conflict (nome) do update
set
  ativo = true,
  updated_at = now();

with usuario as (
  select id, email
  from auth.users
  where email = '<EMAIL_DO_USUARIO>'
),
empresa as (
  select id
  from public.empresas
  where nome = '<NOME_DA_EMPRESA>'
)
insert into public.tecnicos (
  empresa_id,
  user_id,
  nome,
  email,
  papel,
  ativo
)
select
  empresa.id,
  usuario.id,
  '<NOME_DO_TECNICO>',
  usuario.email,
  'tecnico',
  true
from empresa, usuario
on conflict (user_id) do update
set
  empresa_id = excluded.empresa_id,
  nome = excluded.nome,
  email = excluded.email,
  papel = excluded.papel,
  ativo = true,
  updated_at = now();

commit;

-- Checagem:
--
-- select
--   u.id as auth_user_id,
--   u.email,
--   e.id as empresa_id,
--   e.nome as empresa_nome,
--   t.id as tecnico_id,
--   t.nome as tecnico_nome,
--   t.papel,
--   t.ativo
-- from auth.users u
-- join public.tecnicos t on t.user_id = u.id
-- join public.empresas e on e.id = t.empresa_id
-- where u.email = '<EMAIL_DO_USUARIO>';

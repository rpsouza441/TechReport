-- Adiciona campos de auditoria à tabela rats para rastrear
-- quem alterou a RAT e quando, habilitando reabertura para correção
-- com invalidação de assinatura.
--
-- Decisões aplicadas (PS-04 / PM-01):
-- - ultimo_alterador_user_id usa uuid references auth.users(id)
--   (não tecnico_id) — mais direto para auditoria de segurança.
--
-- Decisões aplicadas (PO-05 / PM-02):
-- - Backfill apenas com dado confiável (author_id onde existe).
-- - Campos de reabertura/invalidação ficam NULL para RATs existentes.

begin;

-- Campos de auditoria de edição
alter table public.rats
  add column if not exists ultimo_alterador_user_id uuid
    references auth.users(id)
    on delete set null;

alter table public.rats
  add column if not exists ultima_alteracao_em timestamptz;

-- Campos de reabertura para correção
alter table public.rats
  add column if not exists reaberta_para_correcao_em timestamptz;

alter table public.rats
  add column if not exists reaberta_para_correcao_por_user_id uuid
    references auth.users(id)
    on delete set null;

alter table public.rats
  add column if not exists motivo_reabertura text;

-- Campos de invalidação de assinatura
alter table public.rats
  add column if not exists assinatura_invalidada_em timestamptz;

alter table public.rats
  add column if not exists assinatura_invalidada_por_user_id uuid
    references auth.users(id)
    on delete set null;

-- Backfill: ultimo_alterador_user_id recebe author_id onde existe.
-- author_id representa o usuário que criou a RAT — dado confiável
-- para RATs que nunca foram editadas por terceiros.
update public.rats
set
  ultimo_alterador_user_id = author_id,
  ultima_alteracao_em = updated_at
where
  ultimo_alterador_user_id is null
  and author_id is not null;

-- Campos de reabertura ficam NULL para RATs existentes.
-- Não há dado confiável para backfill desses campos.

commit;
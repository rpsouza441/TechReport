begin;

alter table public.rats
  add column if not exists responsavel_recebimento text,
  add column if not exists data_visita date,
  add column if not exists horario_inicio_atendimento time,
  add column if not exists horario_termino_atendimento time,
  add column if not exists equipamento_movimento_tipo text,
  add column if not exists equipamento_descricao text,
  add column if not exists equipamento_observacao text;

commit;
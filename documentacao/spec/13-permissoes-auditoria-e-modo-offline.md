# 13 — Permissões, Auditoria e Modo Offline

> **Propósito:** registrar as decisões de produto fechadas em 2026-08-09 e
> implementadas/validadas em 2026-08-10 para papéis da empresa, propriedade de
> RAT, auditoria, lixeira e simplificação do modo offline.

## Estado da decisão

As regras deste documento estão **confirmadas, implementadas e validadas**.
Quando houver conflito com documentos antigos, este documento prevalece.

## Papéis no modo empresa

| Papel | Criar RAT própria | Ver RAT própria | Ver RAT da empresa | Corrigir RAT de terceiro | Soft delete |
| --- | --- | --- | --- | --- | --- |
| `tecnico` | Sim | Sim | Não | Não | Somente própria |
| `gerente` | Sim | Sim | Sim | Sim, mesma empresa | RATs da mesma empresa |
| `admin_empresa` | Sim | Sim | Sim | Sim, mesma empresa | RATs da mesma empresa |
| `app_admin` | Não | Não | Não | Não | Não |

Regras complementares:

- toda RAT nasce pertencendo ao usuário que a criou;
- correção por gerente/admin_empresa nunca transfere o dono;
- nenhum papel acessa RAT de outra empresa;
- empresa pequena pode operar sem gerente;
- app_admin cria empresas e convida o primeiro admin_empresa, mas não participa
  do fluxo operacional de RAT;
- o mesmo usuário Auth não pode ser simultaneamente app_admin ativo e membro
  ativo de empresa.

## Auditoria

Toda alteração remota de RAT deve gerar registro imutável em
`public.rat_audit_log`, atribuído pelo servidor.

O registro deve conter:

- RAT alterada;
- usuário autenticado que realizou a operação;
- instante do servidor;
- campos efetivamente modificados;
- valor anterior e valor novo.

Visibilidade:

- técnico visualiza o histórico das próprias RATs;
- gerente e admin_empresa visualizam o histórico de qualquer RAT da mesma
  empresa;
- app_admin e usuários de outra empresa não visualizam o histórico.

O cliente não é fonte de verdade para ator ou horário da auditoria. Campos
técnicos como `updated_at` e `server_updated_at` devem ser excluídos do diff.

## Soft delete e lixeira

- técnico pode aplicar soft delete somente na própria RAT;
- gerente e admin_empresa podem aplicar soft delete em qualquer RAT da mesma
  empresa;
- técnico possui uma lixeira pessoal, limitada às próprias RATs, e pode
  restaurá-las;
- gerente e admin_empresa possuem uma lixeira com as RATs deletadas da empresa;
- gerente e admin_empresa podem restaurar qualquer RAT da mesma empresa;
- RAT deletada não aparece na lista operacional comum;
- delete físico permanece proibido ao aplicativo.

A restauração desfaz somente o soft delete: preserva proprietário, status,
assinatura e demais dados da RAT. No modo empresa, tanto o soft delete quanto a
restauração devem gerar registro na auditoria server-side.

## Modo offline

O modo offline continua independente do Supabase e orientado a um único usuário
local. Não replica papéis ou equipe do modo empresa.

Decisões:

- remover PIN, biometria e tela de desbloqueio;
- manter o SQLite criptografado com chave gerenciada automaticamente pelo app;
- manter RAT, assinatura, PDF, backup e restauração sem internet;
- oferecer área de administração local para perfil, RATs, lixeira, tema,
  backup/restauração e informações dos dados locais.

Remover PIN/biometria não autoriza remover a criptografia do banco nem expor a
chave ao usuário.

## Salvaguardas de evolução

Depois do reset de desenvolvimento:

- migration aplicada nunca deve ser reescrita;
- cada mudança recebe nova migration sequencial;
- migrations devem usar transação quando tecnicamente possível;
- RLS deve ser testada por papel e por empresa;
- alterações destrutivas exigem backup e validação prévia;
- migrations aplicadas devem possuir histórico rastreável no ambiente;
- mudança de permissão deve ser validada no cliente e no servidor.

## Evidências de implementação

- `0025_guard_app_admin_company_identity.sql`: impede dupla identidade ativa;
- `0026_rats_permissions_and_guard.sql`: consolida RLS, campos imutáveis e
  delete/restore estreitos;
- `0027_rat_audit_server_trigger.sql`: gera auditoria server-side e controla
  sua leitura;
- telas de auditoria e lixeira conectadas por papel e empresa;
- bootstrap e administração local sem PIN/biometria, mantendo o banco
  criptografado;
- 67 asserções pgTAP no Supabase self-hosted e 357 testes Flutter aprovados em
  2026-08-10.

## Validação manual restante

O comportamento está pronto para UAT com uma empresa nova, contas separadas de
admin_empresa, gerente e técnico e execução dos fluxos de criação, correção,
auditoria, lixeira e restauração.

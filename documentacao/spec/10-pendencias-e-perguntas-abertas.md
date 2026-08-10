# 10 — Pendencias e Perguntas Abertas

> **Proposito:** registrar lacunas explicitamente — nada escondido entre spec e
> codigo.
>
> **Ultima revisao:** fase **20.2** concluida (2026-08-10).
>
> **Fontes:** diff codigo vs `docs/sprint8.2/`, `estado-do-projeto.md`,
> grep no repositorio.

## P-01 — Sprint 8.2 implementada no codigo; falta fechamento de QA

| Item | Esperado (Sprint 8.2) | Estado no repo |
| --- | --- | --- |
| Campo no formulario RAT | UI + view model | **Implementado** |
| PDF / share textual | Exibir documento ou "Nao informado" | **Implementado** |
| Export/import local JSON | Campo `responsavelDocumento` | **Implementado** |
| Migration Supabase | `alter table rats add responsavel_documento` | **Implementado** — `0008_responsavel_documento.sql` |
| Acentuacao PT-BR | Revisao ampla | **Parcial** — algumas telas corrigidas |
| `flutter analyze` sem erros | Criterio de fechamento | **Feito** em 2026-08-10; 29 avisos/infos |
| `flutter test` | Criterio de fechamento | **Feito** em 2026-08-10, 357 testes |

**Implementado (confirmado):** dominio, Drift v9, drift repo, DTO, enqueue,
leitura remota, formulario, PDF/share, export/import e migration remota.

**Pendente:** QA manual e testes automatizados especificos para regressao do
campo.

---

## P-02 — Documentacao desatualizada antes desta reorganizacao

`documentacao/estado-do-projeto.md` e `README.md` raiz citavam Sprint 6 como
"frente atual". **Corrigido neste commit de documentacao** para Sprint 8.2.

Materiais internos em `docs/README.md` ainda listam Sprint 6 como ativa —
**esperado**, pois `docs/` nao e versionado e pode estar defasado; nao alterar
via commit oficial.

---

## P-03 — Funcionalidades fora do MVP implementado

Confirmado como **nao implementado** (referencia `docs/prompt.md` e codigo):

- upload remoto de anexos;
- area gerencial dedicada com filtros avancados;
- RBAC avancado alem dos papeis atuais;
- provisionamento automatico de instancia Supabase;
- aprovacao da release candidate em aparelho fisico;
- hardening local residual/reset, sem migracao de banco legado nesta fase (Sprint 11).

---

## P-04 — Admin empresa / equipe (Sprint 8.5)

**Status:** implementado no codigo em nivel operacional inicial.

**Confirmado:** migrations `0009` a `0014`, `CompanyAdminRepository`, telas
admin e tela de aceite de convite cobrem listagem, criacao, cancelamento,
validacao e aceite de convites.

**Validado manualmente em 2026-06-01:**

- criar/inativar/ativar empresa pelo app;
- convidar admin da empresa;
- copiar codigo/link e compartilhar convite;
- criar conta pelo app com convite valido;
- confirmar e-mail manualmente em desenvolvimento;
- login normal conclui convite pendente salvo quando o convite ainda existe;
- login Auth sem linha em `public.tecnicos` bloqueia acesso ao modo empresa;
- convite cancelado antes da confirmacao deixa a conta em `auth.users`, mas nao
  cria membro na equipe.

**Pendente:** QA manual/RLS ampliado e testes automatizados antes de considerar
pronto para release candidate.

---

## P-05 — Numeracao de RAT

**Pergunta aberta:** `numero` e texto livre ou deve seguir sequencia por
tecnico/empresa?

**Estado:** campo `String` sem gerador automatico evidente no domain.

**Fonte parcial:** `docs/prompt.md` (nao reproduzido integralmente aqui).

---

## P-06 — Validacao de documento do responsavel

**Decisao fechada para 8.2:** sem validacao CPF/CNPJ.

**Pergunta futura:** ha necessidade de mascara, tipo (CPF/CNPJ/RG) ou
validacao fiscal em sprint posterior?

---

## P-07 — Cobertura de testes automatizados

**Estado:** a suite automatizada cobre sync, auth, administracao, permissoes,
auditoria, lixeira, restore, backup e criptografia. Em 2026-08-10, 357 testes
Flutter e 67 assercoes pgTAP passaram. O QA manual em aparelho fisico continua
pendente.

Foi criada a proposta de sprint de testes em
[`11-sprint-testes-automatizados.md`](./11-sprint-testes-automatizados.md).

---

## P-08 — Metric Slate — cobertura de telas

**Pendencia:** nem todas as telas usam tokens/componentes compartilhados.

Sub-sprint 8.1 (tema visual amplo) documentada em `docs/sprint8.1/` — status
de fechamento **nao confirmado** nesta spec.

---

## P-09 — Migration remota vs DTO

Codigo envia `responsavel_documento` no payload e a migration `0008` esta
versionada.

**Risco residual:** ambientes Supabase que nao aplicaram a migration ainda podem
falhar no sync. A acao operacional e aplicar a sequencia versionada ate `0027`,
preservando a lacuna historica intencional `0017`.

---

## P-10 — Perguntas ao time (bloqueantes futuras)

1. Sprint 8.2 deve ser fechada antes de retomar 8.1 (visual) ou 8.5 (equipe)?
2. Qual criterio formal marca "Sprint 8 fechada" vs sub-sprints 8.x?
3. `documentacao/` deve passar a espelhar specs por sprint ou apenas este
   pacote SDD agregado? (**Decisao atual:** pacote agregado + estado-do-projeto**)

---

## Checklist de sincronizacao spec ↔ codigo

Use antes de fechar Sprint 8.2:

- [x] Formulario expoe `responsavelDocumento`
- [x] PDF e share exibem campo
- [x] Export/import JSON inclui campo
- [x] Migration Supabase versionada
- [ ] Teste manual minimo (10 passos em `docs/sprint8.2/passos.md`)
- [ ] Atualizar `documentacao/estado-do-projeto.md`
- [ ] Atualizar RF-04.4 nesta spec para **Implementado**
## P-11 - Remocao do bloqueio local legado

**Decisao superveniente (2026-08-09):** remover PIN, biometria e tela de
desbloqueio do modo local. A criptografia do SQLite continua ativa com chave
gerenciada automaticamente. A execucao esta consolidada em P-21.

---

## P-12 - Sprint 8.5 operacional

**Status:** decisoes atualizadas em `docs/sprint8.5/spec-driven.md`.

**Confirmado:** fluxo operacional de convite/criacao pelo app existe. Em uso
real, o Supabase Dashboard nao deve ser parte da criacao de usuario. Em
desenvolvimento, pode-se confirmar e-mail manualmente enquanto SMTP/templates
nao estiverem configurados.

**Regra validada:** usuario existente apenas em `auth.users` nao e membro da
empresa. Para entrar na equipe, precisa aceitar convite valido e gerar linha em
`public.tecnicos`.

**Estado atual:** a cobertura automatizada foi ampliada e a matriz final de
RLS passou por cenarios positivos/negativos no Supabase self-hosted. Permanece
o QA manual de release.

---

## P-13 - Deep link de convite

**Concluido:** o app gera `techreport://convite?codigo=XXXXXXXX`, possui intent
filter Android, usa `app_links` e abre `CompanyAcceptInviteScreen` com o codigo.

---
## P-14 - Exception handler global

**Concluido:** `runZonedGuarded`, `FlutterError.onError` e
`PlatformDispatcher.instance.onError` encaminham falhas nao tratadas ao log
global; erros esperados continuam mapeados nas camadas de apresentacao.

---

## P-15 - Reenviar confirmacao de e-mail

**Estado parcial:** a tela e o ViewModel oferecem a acao sem salvar senha, mas
o repositorio ainda retorna indisponibilidade amigavel porque a versao atual do
SDK nao expoe o reenvio usado pelo projeto. A integracao real depende de SDK
compativel ou Edge Function/RPC.

---

## P-16 - Perfil empresa editavel e nome da empresa

**Concluido:** `Meu perfil` permite editar o nome exibido via
`update_own_display_name`.

**Pendencia residual:** confirmar em UAT que o nome da empresa e exibido em
todos os pontos esperados do perfil remoto.

**Acao futura:** corrigir apenas os pontos de exibicao que o UAT identificar,
sem ampliar a RLS.

---

## P-17 - Gerente com equipe limitada

**Decisao atual:** gerente pode acessar a area Equipe em modo limitado.

**Permitido para gerente:**

- visualizar tecnicos da propria empresa;
- convidar apenas `tecnico`;
- ativar/inativar `tecnico`;
- exigir/remover troca de senha de `tecnico`.

**Nao permitido para gerente:**

- convidar `gerente`;
- convidar `admin_empresa`;
- ativar/inativar `gerente` ou `admin_empresa`;
- exigir/remover troca de senha de `gerente` ou `admin_empresa`;
- alterar admins da empresa.

---

## P-18 - Configuracao Supabase some apos flutter run

**Observacao de validacao:** durante o desenvolvimento, foi percebido que apos
rodar `flutter run` depois de atualizacoes, os dados salvos do servidor Supabase
podem sumir do app.

**Impacto:** o usuario/desenvolvedor precisa informar novamente URL/chave
publica, atrasando testes do modo empresa.

**Hipoteses a investigar:**

- reinstalacao/debug limpando storage local do app;
- mudanca de app id/package/applicationId entre builds;
- storage usado para endpoint remoto diferente do storage de tokens;
- hot restart/hot reload vs reinstall completo;
- limpeza de dados do emulador/dispositivo pelo tooling.

**Acao futura:** mapear onde `RemoteEndpointRepository` persiste URL/chave,
testar `flutter run` vs reinstall limpo, e decidir se configuracao de servidor
deve ter backup/import ou modo dev mais estavel.

---

## P-19 — Alinhar RLS com a matriz final de papeis

**Decisao fechada:** todo membro cria RAT propria; gerente/admin_empresa podem
corrigir RAT de terceiro da mesma empresa sem alterar o dono; tecnico ve apenas
as proprias; app_admin nao acessa RAT.

**Concluido em 2026-08-10:** migrations `0025` e `0026`, protecao de campos
estruturais, guards Flutter e testes positivos/negativos por papel e empresa.

---

## P-20 — Auditoria e lixeira de RAT

**Decisao fechada:** auditoria server-side por campo; tecnico ve historico
proprio; gerente/admin_empresa veem historico da empresa. Tecnico usa lixeira e
restaura somente RAT propria; gerente/admin_empresa usam a lixeira e restauram
qualquer RAT da mesma empresa. Restaurar preserva proprietario, status,
assinatura e demais dados e gera auditoria.

**Concluido em 2026-08-10:** migration `0027`, trigger server-side, repositorio
somente leitura, timeline de auditoria, lixeiras por escopo e restore estreito
local/remoto.

---

## P-21 — Remover PIN e biometria do modo local

**Decisao fechada:** modo local nao tera PIN, biometria nem tela de desbloqueio.
SQLite continua criptografado com chave automatica.

**Concluido em 2026-08-10:** onboarding/bootstrap nao exigem PIN ou biometria e
a administracao local oferece perfil, RATs, lixeira, tema, backup/restauracao e
informacoes dos dados. Classes legadas de PIN podem permanecer internamente,
mas nao fazem parte do fluxo navegavel.

---

## P-22 — Impedir dupla identidade

**Problema confirmado em desenvolvimento:** existe historico de usuario ativo
simultaneamente em `app_admins` e `tecnicos`.

**Concluido em 2026-08-10:** migration `0025` impede dupla identidade ativa em
ambos os sentidos e os testes de banco validam convites/aceites conflitantes.

---

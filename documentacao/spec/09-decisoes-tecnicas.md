# 09 — Decisoes Tecnicas

> **Proposito:** registrar decisoes arquiteturais e de produto consolidadas no
> TechReport, com rastreabilidade.
>
> **Fontes:** `docs/prompt.md`, `docs/decisions/` (consulta interna),
> `documentacao/arquitetura.md`, migrations, codigo.

Formato: **DEC-XX** — decisao — status — fonte.

## DEC-01 — Supabase como backend remoto do MVP

**Decisao:** usar Supabase (Auth + Postgres + RLS) em vez de backend proprio
no MVP.

**Status:** Confirmado e implementado.

**Fonte:** `docs/prompt.md`, `pubspec.yaml`.

**Consequencias:** migrations SQL versionadas em `supabase/migrations/`; app
usa apenas chave publica.

---

## DEC-02 — Arquitetura local-first

**Decisao:** toda escrita de RAT passa primeiro pelo SQLite local; sync e
explicito via fila.

**Status:** Confirmado.

**Fonte:** entidade `RatSyncStatus`, `sync_queue_items`, use cases de sync.

---

## DEC-03 — Camadas presentation / domain / data

**Decisao:** separar UI, regras e infra; domain isolado de SDKs.

**Status:** Confirmado.

**Fonte:** estrutura `lib/features/`, `documentacao/arquitetura.md`.

---

## DEC-04 — Sessao remota distinta da Session Supabase

**Decisao:** dominio usa `SessaoRemota` com refs de token, nunca tokens puros.

**Status:** Confirmado.

**Fonte:** `sessao_remota.dart`, ADR interno em `docs/adr/` (consulta).

---

## DEC-05 — Dois modos no mesmo app

**Decisao:** local e empresa coexistem; usuario escolhe no bootstrap; dados
locais nao sao apagados ao usar empresa.

**Status:** Confirmado.

**Fonte:** `AppModeChoiceScreen`, `select_app_mode`.

---

## DEC-06 — App admin no mesmo aplicativo Flutter

**Decisao:** administracao global (`app_admin`) ocorre dentro do app, sem
painel web separado no MVP.

**Status:** Confirmado.

**Fonte:** `docs/decisions/app-admin-no-mesmo-app.md` (consulta interna),
migration 0006, `AppAdminArea`.

---

## DEC-07 — RLS como autorizacao remota

**Decisao:** Flutter nao implementa autorizacao remota sozinho; policies Postgres
definem escopo.

**Status:** Confirmado.

**Fonte:** migrations 0002, 0004, 0007; contrato
`docs/contracts/seguranca-supabase-rls.md`.

---

## DEC-08 — Soft delete de RAT

**Decisao:** exclusao preserva registro (`deletedAt` / `deletado`).

**Status:** Confirmado.

**Fonte:** entidade `Rat`, schema remoto.

---

## DEC-09 — Metric Slate como direcao visual

**Decisao:** adotar design system Metric Slate (tokens + componentes
compartilhados) progressivamente.

**Status:** Confirmado — implementacao parcial.

**Fonte:** `lib/app/theme/metric_slate_*`, widgets `tech_report_*`,
`docs/stitch-techreport/design-system.md` (consulta).

---

## DEC-10 — Documentacao oficial separada de `docs/`

**Decisao:** material de sprint e prompts ficam em `docs/` (gitignored); spec
e guias publicos ficam em `documentacao/`.

**Status:** Confirmado — esta reorganizacao SDD.

**Fonte:** regras do projeto, `.gitignore` linha `/docs/`.

---

## DEC-11 — Campo documento do responsavel opcional (Sprint 8.2)

**Decisao:** adicionar `responsavelDocumento` opcional, sem validacao fiscal,
sem exigencia para assinatura.

**Status:** Confirmado como decisao de produto; implementacao parcial.

**Fonte:** `docs/sprint8.2/README.md`.

---

## DEC-12 — Trilha de sprints pos-Sprint 5

**Decisao replanejada** (`docs/decisions/plano-pos-sprint5-prompt2.md`):

| Sprint | Foco |
| --- | --- |
| 6 | RAT completo, PDF, schema, Metric Slate base |
| 7 | Admin e papeis |
| 8 | UX empresa, conta, sync observavel |
| 9 | QA, build Android, RC |
| 10 | Hardening seguranca local |

**Status:** Confirmado como plano; sprints 6–8 largely executadas no codigo.

**Nota:** sub-sprints 8.1, 8.2, 8.5 existem apenas em `docs/` (consulta).

---

## Decisoes ainda abertas

Transferidas para [10-pendencias-e-perguntas-abertas.md](./10-pendencias-e-perguntas-abertas.md):

- numeracao automatica de RAT;
- hardening local residual/reset, sem migracao de banco legado nesta fase (Sprint 11).

---

## DEC-13 — Matriz final de papeis da RAT

**Decisao:** todo membro de empresa pode criar RAT propria. Tecnico ve apenas
as proprias; gerente/admin_empresa veem e podem corrigir RATs da mesma empresa,
sem alterar criador ou dono. app_admin nao acessa RAT.

**Status:** Implementado nas migrations `0025` e `0026` e nos guards Flutter;
validado por testes de papel/empresa.

---

## DEC-14 — Auditoria server-side por campo

**Decisao:** toda alteracao remota de RAT gera historico imutavel atribuido
pelo servidor, com ator, instante e diff old/new. Tecnico ve historico proprio;
gerente/admin_empresa veem historico da empresa.

**Status:** Implementado pela migration `0027`, repositorio somente leitura e
tela de historico.

---

## DEC-15 — Soft delete e lixeira empresarial

**Decisao:** tecnico aplica soft delete proprio; gerente/admin_empresa podem
aplicar na mesma empresa. Tecnico consulta/restaura somente as proprias RATs;
gerente/admin_empresa consultam/restauram as RATs deletadas da empresa. A
restauracao preserva proprietario, status, assinatura e demais dados. Soft
delete e restauracao geram auditoria; delete fisico permanece proibido.

**Status:** Implementado no dominio, fila de sync e telas de lixeira
pessoal/empresarial.

---

## DEC-16 — Modo offline sem PIN ou biometria

**Decisao:** remover PIN, biometria e tela de desbloqueio do modo local,
preservando SQLite criptografado com chave automatica e criando area de
administracao pessoal.

**Status:** Implementado no onboarding/bootstrap e na administracao local; a
criptografia automatica permanece ativa.

---

## DEC-17 — Evolucao segura de migrations

**Decisao:** depois do reset de desenvolvimento, migrations aplicadas nao sao
reescritas. Mudancas usam novas versoes sequenciais, testes de RLS, historico
de aplicacao e backup antes de operacoes destrutivas.

**Status:** Confirmado e aplicado no reset controlado de desenvolvimento, com
backup, replay assinado das migrations e postflight.

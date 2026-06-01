# 00 — Visao Geral

> **Proposito:** descrever o que e o TechReport, para quem e em que contexto
> de sprint o repositorio se encontra.
>
> **Fontes:** `documentacao/visao-geral.md`, `README.md`, `pubspec.yaml`,
> estrutura `lib/features/`, materiais internos `docs/prompt.md` e
> `docs/sprint8.2/README.md`.

## Produto

**Confirmado:** TechReport e um aplicativo Flutter para criacao de Relatorios de
Atendimento Tecnico (RAT), em portugues do Brasil.

Prioridades do MVP (ordem confirmada em `docs/prompt.md`):

1. fluxo local confiavel;
2. RAT local;
3. assinatura;
4. compartilhamento local/PDF;
5. modo empresa com Supabase;
6. RLS e isolamento remoto;
7. fila de sincronizacao local-first;
8. polimento de produto e publicacao Android.

## Modos de uso

| Modo | Descricao | Backend |
| --- | --- | --- |
| **Local** | Uso individual sem internet | Drift/SQLite no dispositivo |
| **Empresa** | Autenticacao remota, sync e isolamento por empresa | Supabase (Auth + Postgres + RLS) |

**Confirmado:** os dois modos coexistem; o usuario escolhe no bootstrap
(`AppModeChoiceScreen` em `lib/app/navigation/tech_report_app.dart`).

## Stack tecnica

**Confirmado** (`pubspec.yaml`):

- Flutter / Dart SDK `^3.11.4`;
- Drift + drift_flutter (SQLite local);
- supabase_flutter (modo empresa);
- flutter_secure_storage (tokens);
- pdf + share_plus (relatorio);
- file_picker (importacao local);
- uuid.

## Modulos principais

**Confirmado** (`lib/features/`):

| Modulo | Responsabilidade |
| --- | --- |
| `local_auth` | Onboarding, PIN, desbloqueio, home local, export/import |
| `company_auth` | Modo empresa, endpoint, login, sessao remota, conta |
| `rat` | CRUD de RAT, lista, formulario, PDF, compartilhamento |
| `signature` | Captura e persistencia de assinatura |
| `sync` | Fila local, download incremental, central de sync |
| `company_admin` | Areas `app_admin` e `admin_empresa` |

Infra compartilhada em `lib/shared/` (banco Drift, widgets Metric Slate,
seguranca local).

## Estado atual do desenvolvimento

**Confirmado:**

- Sprint 5 fechada funcionalmente em 2026-05-12 (sync MVP de RAT, RLS basica).
- Sprints 6 a 8 entregaram, entre outros: RAT com campos estendidos, admin de
  papeis, tela de conta, logout com pendencias, sync center, tema Metric Slate
  parcial (evidencia no codigo e em `lib/app/navigation/company_shell.dart`).

**Confirmado — sprint atual de fechamento:** **Sprint 8.2 / 8.5**

Objetivos (`docs/sprint8.2/README.md`):

1. campo opcional `responsavelDocumento` na RAT (ponta a ponta);
2. revisao de acentuacao PT-BR em textos visiveis.

**Confirmado — Sprint 8.2 implementada no codigo:**

- dominio, banco local (schema Drift v7), repositorios, DTO e payload de sync
  incluem `responsavelDocumento`;
- migration Supabase `0008_responsavel_documento.sql` adiciona
  `responsavel_documento`;
- formulario, PDF, share textual e export/import local expoem/preservam o
  campo;
- `flutter analyze` e `flutter test` passaram em 2026-06-01.

**Confirmado — Sprint 8.5 implementada no codigo:**

- migrations `0009` a `0012` criam/ajustam `tecnico_convites` e RPCs;
- app possui telas/use cases para convites, aceite de convite e equipe;
- ainda precisa de QA manual/RLS e cobertura automatizada antes de marcar como
  release candidate.

## Principios invariantes

**Confirmado** (repetidos em `documentacao/visao-geral.md` e codigo):

- modo local funciona sem backend;
- app nunca contem `SERVICE_ROLE_KEY` nem credenciais administrativas;
- tokens puros ficam apenas em storage seguro (camada data);
- migrations Supabase sao aplicadas fora do app;
- Supabase e o backend remoto oficial do MVP; backend proprio e possibilidade
  futura.

## Fora do escopo imediato

**Confirmado** (`docs/sprint8.2/README.md` e `documentacao/estado-do-projeto.md`):

- sync remoto de assinatura;
- upload remoto de anexos;
- validacao fiscal de CPF/CNPJ no campo documento;
- build Android / release candidate (Sprint 9);
- criptografia do SQLite (Sprint 10 — planejada internamente).

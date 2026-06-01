# 02 — Requisitos Nao Funcionais

> **Proposito:** qualidades do sistema independentes de funcionalidade especifica.
>
> **Fontes:** `docs/prompt.md`, `docs/contracts/seguranca-supabase-rls.md`,
> `documentacao/arquitetura.md`, codigo de seguranca e sync.

## RNF-01 — Seguranca

| ID | Requisito | Evidencia |
| --- | --- | --- |
| RNF-01.1 | App usa apenas URL publica e chave anon/public do Supabase | Confirmado — `RemoteServerConfigScreen`, docs |
| RNF-01.2 | Nunca embutir `SERVICE_ROLE_KEY` ou senha de banco | Confirmado — ausente no codigo |
| RNF-01.3 | Tokens de acesso/refresh apenas em secure storage | Confirmado — `FlutterSecureTokenStore` |
| RNF-01.4 | Dominio nao expoe tokens puros | Confirmado — `SessaoRemota` usa refs |
| RNF-01.5 | Isolamento remoto via RLS em todas as tabelas privadas | Confirmado — migrations 0001–0007 |
| RNF-01.6 | Operacoes admin pelo app usam usuario autenticado + RLS | Confirmado — `0006_admin_roles_base.sql` |

## RNF-02 — Disponibilidade offline (local-first)

| ID | Requisito | Evidencia |
| --- | --- | --- |
| RNF-02.1 | Modo local opera sem rede | Confirmado |
| RNF-02.2 | Modo empresa grava RAT localmente antes do sync | Confirmado — Drift + fila |
| RNF-02.3 | Sessao remota permite janela offline (`offlineAccessUntil`) | Confirmado — `SessaoRemota` |
| RNF-02.4 | Logout remoto nao apaga dados locais automaticamente | Confirmado — `sign_out_company` |

## RNF-03 — Integridade e rastreabilidade de dados

| ID | Requisito | Evidencia |
| --- | --- | --- |
| RNF-03.1 | Soft delete de RAT local e flag remota `deletado` | Confirmado |
| RNF-03.2 | Migrations Drift versionadas (`schemaVersion`) | Confirmado — v7 atual |
| RNF-03.3 | Migrations Supabase versionadas fora do app | Confirmado — `supabase/migrations/` |
| RNF-03.4 | Checkpoint de download por escopo de visibilidade | Implementado — `sync_checkpoint` |

## RNF-04 — Manutenibilidade

| ID | Requisito | Evidencia |
| --- | --- | --- |
| RNF-04.1 | Arquitetura em camadas presentation / domain / data | Confirmado — estrutura `lib/` |
| RNF-04.2 | UI nao importa SDK Supabase ou Drift diretamente | Confirmado — revisao de imports |
| RNF-04.3 | DTO remoto nao vaza para dominio | Confirmado — `rat_remote_dto.dart` |
| RNF-04.4 | Injecao centralizada via `AppScope` | Confirmado — `app/di/app_scope.dart` |

## RNF-05 — Usabilidade

| ID | Requisito | Status |
| --- | --- | --- |
| RNF-05.1 | Textos visiveis em PT-BR com acentuacao correta | Parcial — Sprint 8.2 |
| RNF-05.2 | Layout utilizavel em telas pequenas | Parcial — Metric Slate em evolucao |
| RNF-05.3 | Mensagens de erro sem expor token ou segredo | Confirmado — revisao em view models |

## RNF-06 — Performance e escala (MVP)

| ID | Requisito | Notas |
| --- | --- | --- |
| RNF-06.1 | Lista de RATs carrega do SQLite local | Confirmado |
| RNF-06.2 | Download remoto incremental por checkpoint | Confirmado |
| RNF-06.3 | Limites de escala enterprise | **Pendencia** — nao especificado |

## RNF-07 — Portabilidade

| ID | Requisito | Evidencia |
| --- | --- | --- |
| RNF-07.1 | Projeto Flutter multi-plataforma | Confirmado — pastas android, ios, web, etc. |
| RNF-07.2 | Release candidate Android | Pendente — Sprint 9 |

## RNF-08 — Privacidade local

| ID | Requisito | Status |
| --- | --- | --- |
| RNF-08.1 | SQLite local sem criptografia nativa no MVP | Confirmado |
| RNF-08.2 | Criptografia de banco local | Pendente — Sprint 10 (planejada em `docs/sprint10/`) |

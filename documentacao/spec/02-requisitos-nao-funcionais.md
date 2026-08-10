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
| RNF-01.5 | Isolamento remoto via RLS em todas as tabelas privadas | Confirmado — migrations 0001–0027 aplicaveis |
| RNF-01.6 | Operacoes admin pelo app usam usuario autenticado + RLS | Confirmado — `0006_admin_roles_base.sql` |
| RNF-01.7 | app_admin ativo nao pode acumular perfil ativo de empresa | Confirmado — migration `0025` |
| RNF-01.8 | Ator e horario da auditoria de RAT sao atribuidos pelo servidor | Confirmado — migration `0027` |

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
| RNF-03.2 | Migrations Drift versionadas (`schemaVersion`) | Confirmado — v9 atual |
| RNF-03.3 | Migrations Supabase versionadas fora do app | Confirmado — `supabase/migrations/` |
| RNF-03.4 | Checkpoint de download por escopo de visibilidade | Implementado — `sync_checkpoint` |
| RNF-03.5 | Alteracoes remotas de RAT geram diff imutavel em `rat_audit_log` | Confirmado — trigger server-side `0027` |
| RNF-03.6 | Migration aplicada nao e reescrita; mudanca nova usa versao sequencial | Decisao confirmada |
| RNF-03.7 | Mudanca destrutiva exige backup e validacao previa | Decisao confirmada |

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
| RNF-07.2 | Release candidate Android | Parcial — APK release gerado; aprovacao depende de QA em aparelho fisico |

## RNF-08 — Privacidade local

| ID | Requisito | Status |
| --- | --- | --- |
| RNF-08.1 | SQLite local permanece criptografado | Confirmado |
| RNF-08.2 | Chave de criptografia e gerenciada automaticamente e nao exposta na UI | Confirmado |
| RNF-08.3 | Modo local nao exige PIN, biometria ou tela de desbloqueio | Confirmado |

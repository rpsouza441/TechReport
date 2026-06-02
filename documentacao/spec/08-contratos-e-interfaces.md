# 08 — Contratos e Interfaces

> **Proposito:** fronteiras entre camadas — repositorios e use cases expostos
> ao restante do app.
>
> **Fontes:** `lib/features/*/domain/`, `app_scope.dart`.

## Convencoes

- Repositorios definem persistencia; implementacoes ficam em `data/`.
- Use cases orquestram uma operacao de negocio.
- View models consomem use cases/repos injetados; nao instanciam infra.

## Repositorios principais

| Contrato | Arquivo | Implementacao(oes) |
| --- | --- | --- |
| `RatRepository` | `rat/domain/repositories/rat_repository.dart` | `DriftRatRepository` |
| `RemoteRatRepository` | `rat/domain/repositories/remote_rat_repository.dart` | `SupabaseRemoteRatRepository` |
| `AssinaturaRepository` | `signature/domain/repositories/assinatura_repository.dart` | `DriftAssinaturaRepository` |
| `SyncQueueRepository` | `sync/domain/repositories/sync_queue_repository.dart` | `DriftSyncQueueRepository` |
| `SyncCheckpointRepository` | `sync/domain/repositories/sync_checkpoint_repository.dart` | `LocalSyncCheckpointRepository` |
| `TecnicoLocalRepository` | `local_auth/domain/...` | `DriftTecnicoLocalRepository` |
| `SessaoLocalRepository` | `local_auth/domain/...` | `DriftSessaoLocalRepository` |
| `AuthRepository` | `company_auth/domain/...` | `SupabaseAuthRepository` |
| `RemoteSessionRepository` | `company_auth/domain/...` | `LocalRemoteSessionRepository` |
| `RemoteEndpointRepository` | `company_auth/domain/...` | `LocalRemoteEndpointRepository` |
| `AppModeRepository` | `company_auth/domain/...` | `LocalAppModeRepository` |
| `CompanyAdminRepository` | `company_admin/domain/...` | `SupabaseCompanyAdminRepository` |
| `PinSecretRepository` | `local_auth/domain/...` | `LocalPinSecretStore` |

**Confirmado** — wiring em `AppScope.create()`.

## Use cases principais

### Local auth

| Use case | Responsabilidade |
| --- | --- |
| `BootstrapLocalSession` | Inicializa sessao local |
| `CompleteLocalOnboarding` | Conclui onboarding |
| `UnlockLocalSession` / `LockLocalSession` | PIN |
| `ChangeLocalPin` | Altera PIN |
| `ApplyLocalDataImport` / `PreviewLocalDataImport` | Backup |

### Company auth

| Use case | Responsabilidade |
| --- | --- |
| `SelectAppMode` | Persiste modo |
| `SignInCompany` / `SignOutCompany` | Auth remota |
| `BootstrapCompanySession` | Restaura sessao |
| `ChangeCompanyPassword` | Troca senha |

### RAT

| Use case | Responsabilidade |
| --- | --- |
| `ShareRatLocally` | Texto + delegacao PDF |

Formulario e lista usam `RatRepository` diretamente via view models
(**Confirmado** — padrao atual do projeto).

### Sync

| Use case | Responsabilidade |
| --- | --- |
| `EnqueueRatSync` | Enfileira operacao RAT |
| `ProcessSyncQueue` | Processa fila |
| `DownloadRemoteRats` | Pull incremental |

### Admin

| Use case | Responsabilidade |
| --- | --- |
| `ListAdminEmpresas` | Lista empresas (app admin) |
| `ListAdminTecnicos` | Lista tecnicos |
| `ListAdminConvites` | Lista convites da empresa |
| `CreateTecnicoConvite` | Cria convite conforme permissao: admin empresa convida admin/gerente/tecnico; gerente convida apenas tecnico |
| `CreateEmpresaConvite` | Cria convite de admin empresa a partir do app admin |
| `CancelTecnicoConvite` | Cancela convite pendente |
| `UpdateTecnicoEquipe` | Atualiza flags permitidas: admin empresa altera gerente/tecnico; gerente altera apenas tecnico |
| `CreateAdminEmpresa` / `UpdateAdminEmpresa` | Operacoes de administracao global sobre empresas/admins |

## Servicos de infra (data layer)

| Servico | Papel |
| --- | --- |
| `FlutterSecureTokenStore` | Tokens Auth |
| `SupabaseClientFactory` | Client autenticado |
| `LocalSignatureAssetStore` | Arquivos de assinatura |
| `RatPdfShareService` | Geracao PDF |
| `LocalDataExportShareService` | Backup JSON |

**Regra:** servicos nao sao consumidos por domain entities.

## DTO e mapeamento remoto

**Confirmado** — `RatRemoteDto`:

- serializa para colunas snake_case de `public.rats`;
- inclui `responsavel_documento` no JSON de sync.

Fronteira: apenas repositorios Supabase importam o DTO.

## Contratos de seguranca (resumo)

| Permitido no app | Proibido no app |
| --- | --- |
| `supabaseUrl`, anon key | `SERVICE_ROLE_KEY` |
| Auth email/senha | SQL DDL em runtime |
| Leitura/escrita via RLS | Credenciais Postgres |

Detalhes em `documentacao/configuracao-supabase.md` e contratos internos
`docs/contracts/` (consulta).

## Extensibilidade

**Confirmado** — decisao de desacoplamento por repositorio permite substituir
Supabase por backend proprio no futuro, mantendo domain/presentation.

**Hipotese:** contratos de admin completo (RPC/Edge Functions) ainda nao estao
formalizados na documentacao oficial — dependem de evolucao pos-Sprint 7.

**Atualizacao:** contratos de admin/equipe ja existem via RPCs Supabase em
`CompanyAdminRepository`; o app nao usa `SERVICE_ROLE_KEY`.

## Injecao (`AppScope`)

**Confirmado:** singleton manual por execucao do app; criado uma vez no
bootstrap. Nao usa framework DI externo (get_it, etc.) no estado atual.

**Pendencia:** documentar ciclo de vida/test doubles para testes de integracao —
nao ha guia oficial alem de testes widget isolados.

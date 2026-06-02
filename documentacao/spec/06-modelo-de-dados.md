# 06 — Modelo de Dados

> **Proposito:** entidades e tabelas locais/remotas com correspondencias.
>
> **Fontes:** `tech_report_local_database.dart`, entidades domain, migrations
> `supabase/migrations/`.

## Visao geral

```text
LOCAL (Drift)                    REMOTO (Supabase)
─────────────────                ─────────────────
tecnico_locals                   auth.users
sessao_locals                    public.empresas
rats                      ←sync→ public.rats
assinaturas               (local only no MVP)
sync_queue_items          (local only)
                                 public.tecnicos
                                 public.app_admins
```

## Entidade Rat (dominio)

**Confirmado** — `lib/features/rat/domain/entities/rat.dart`:

| Campo | Tipo | Notas |
| --- | --- | --- |
| `id` | String | UUID |
| `authorId` | String | Autor local |
| `empresaId`, `usuarioId`, `tecnicoId` | String? | Preenchidos no modo empresa |
| `ownerType` | enum | `localTecnico` \| `companyTecnico` |
| `numero` | String | Identificador visivel |
| `clienteNome` | String | Obrigatorio |
| `responsavelRecebimento` | String? | Nome de quem recebe |
| `responsavelDocumento` | String? | **Sprint 8.2** — opcional |
| `dataVisita` | DateTime? | |
| `horarioInicioAtendimento` | String? | |
| `horarioTerminoAtendimento` | String? | |
| `descricao` | String | |
| `equipamentoMovimentoTipo` | enum? | retirada, entrega, etc. |
| `equipamentoDescricao` | String? | |
| `equipamentoObservacao` | String? | |
| `status` | enum | draft, finalizado, enviado, arquivado |
| `syncStatus` | enum | localOnly, pendingSync, synced, syncError |
| `createdAt`, `updatedAt` | DateTime | |
| `deletedAt` | DateTime? | Soft delete |

## Tabela local `rats` (Drift)

**Confirmado** — espelha campos acima; `schemaVersion` 7 adiciona
`responsavelDocumento`.

## Tabela remota `public.rats`

**Confirmado** — migrations 0002 + 0003:

| Coluna remota | Campo app | Migration |
| --- | --- | --- |
| `id` | `id` | 0002 |
| `empresa_id` | `empresaId` | 0002 |
| `tecnico_id` | `tecnicoId` | 0002 |
| `criado_por_user_id` | `usuarioId` | 0002 |
| `numero`, `cliente_nome`, `descricao`, `status` | homonimos | 0002 |
| `deletado` | soft delete | 0002 |
| `responsavel_recebimento` | `responsavelRecebimento` | 0003 |
| `data_visita`, horarios, equipamento_* | homonimos | 0003 |
| `responsavel_documento` | `responsavelDocumento` | 0008 |

**Confirmado Sprint 8.2:** a migration Supabase
`0008_responsavel_documento.sql` adiciona `responsavel_documento text`.

## Assinatura

**Confirmado** — tabela local `assinaturas`:

| Campo | Descricao |
| --- | --- |
| `ratId` | FK logica para RAT |
| `storageMode` | Modo de armazenamento do asset |
| `assetRef` | Referencia ao arquivo local |
| `deletedAt` | Soft delete |

Sem tabela remota equivalente no MVP.

## Sessao local

**Confirmado** — `sessao_locals`:

- `mode`, `tecnicoLocalId`, flags de PIN/biometria/onboarding.

## Sessao remota (dominio, nao tabela Drift dedicada)

**Confirmado** — persistida via `local_remote_session_repository` + secure
storage para tokens:

| Campo | Descricao |
| --- | --- |
| `empresaId`, `tecnicoId`, `usuarioId` | Contexto empresa |
| `papelGlobal`, `papelEmpresa` | Papeis |
| `accessTokenRef`, `refreshTokenRef` | Refs, nao tokens puros |
| `mustChangePassword` | Flag de troca obrigatoria |
| `expiresAt`, `offlineAccessUntil` | Validade |

## Sync queue

**Confirmado** — `sync_queue_items`:

| Campo | Descricao |
| --- | --- |
| `entityType` | Ex.: RAT |
| `entityId` | ID da entidade |
| `operation` | create/update/delete |
| `payload` | JSON serializado |
| `status`, `attempts`, `lastError` | Controle de retry |

## Empresa e tecnicos (remoto)

**Confirmado** — migration 0001 + 0006:

### `public.empresas`

- `id`, `nome`, `ativo`, timestamps.

### `public.tecnicos`

- vinculo `user_id` → `auth.users`;
- `empresa_id`, `papel` (`tecnico`, `gerente`, `admin_empresa`);
- `must_change_password` (0006).

### `public.app_admins`

- admin global; `must_change_password` default true.

### `public.tecnico_convites`

**Confirmado** — migrations 0009 a 0014:

- `id`, `empresa_id`, `email`, `nome`, `papel`, `status`;
- `codigo_digest`, `created_by`, `created_at`, `expires_at`, `accepted_at`;
- RPCs de criar, validar, aceitar e cancelar convite;
- RPC de atualizacao de equipe com restricoes por papel.

## DTO remoto RAT

**Confirmado** — `rat_remote_dto.dart` mapeia snake_case Supabase ↔ dominio.

Regra: DTO nao e exposto a presentation/domain fora da camada data.

## Checkpoint de sync

**Confirmado** — `local_sync_checkpoint_repository` persiste marca temporal
por escopo (empresa/usuario/papel) para download incremental.

**Pendencia:** formato exato do checkpoint nao esta documentado nesta spec além
da existencia do repositorio — detalhes em codigo
`sync_checkpoint_repository.dart`.

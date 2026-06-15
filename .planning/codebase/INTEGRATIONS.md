# External Integrations

**Analysis Date:** 2025-06-15

## APIs & External Services

**Backend (Self-Hosted Supabase):**
- Supabase - Backend-as-a-Service platform
  - Auth: Email/password authentication with session management
  - Database: PostgreSQL via Supabase client
  - RPC: Server-side functions (convites, display name updates)
  - Tables: `tecnicos`, `app_admins`, `empresas`, `rats`, `assinaturas`
  - SDK: `supabase_flutter` ^2.0.0
  - Auth Flow: Implicit flow (`AuthFlowType.implicit`)
  - Implementation: `lib/features/company_auth/data/repositories/supabase_auth_repository.dart`

**Remote Endpoint Configuration:**
- Users can configure custom Supabase server URLs (self-hosted)
- Public key stored via SecureTokenStore
- Connection tested via `RemoteServerConnectionTester`
- Repository: `lib/features/company_auth/data/repositories/local_remote_endpoint_repository.dart`

## Data Storage

**Local Database:**
- SQLite with SQLite3MultipleCiphers encryption
- Database file: `tech_report_local.db` in app documents directory
- Tables: `tecnico_locals`, `sessao_locals`, `rats`, `assinaturas`, `sync_queue_items`
- Schema version: 9
- Implementation: `lib/shared/infra/database/tech_report_local_database.dart`

**Secure Storage:**
- Flutter Secure Storage for:
  - Database encryption key (`db_encryption_key`)
  - Supabase access/refresh tokens
  - Remote endpoint configuration
- Key store: `lib/shared/infra/security/database_key_store.dart`
- Token store: `lib/features/company_auth/data/services/flutter_secure_token_store.dart`

**File Storage:**
- Local signature assets stored in app documents directory
- Implementation: `lib/features/signature/data/services/local_signature_asset_store.dart`

## Authentication & Identity

**Remote Authentication (Supabase Auth):**
- Email/password sign-in/sign-up
- Session refresh with refresh tokens
- Password change via `client.auth.updateUser()`
- Invite acceptance via RPC calls (`accept_tecnico_convite`, `validate_tecnico_convite`)
- Roles: `app_admin`, `admin_empresa`, `gerente`, `tecnico`

**Local Authentication:**
- PIN-based local session lock/unlock
- Biometric authentication support (flag-based)
- Secure PIN storage via `LocalPinSecretStore`
- Local session state in `SessaoLocals` table

## Cloud Services

**Supabase (Backend):**
- Self-hosted or cloud Supabase instance
- Configuration stored locally per installation
- Endpoint: User-configurable (no hardcoded URL)

## Third-Party SDKs

| SDK | Version | Purpose |
|-----|---------|---------|
| supabase_flutter | ^2.0.0 | Backend client (auth + database) |
| flutter_secure_storage | ^10.0.0 | Secure credential storage |
| drift | ^2.32.1 | Local database ORM |
| sqlite3 | ^3.3.1 | SQLite native bindings |
| pdf | ^3.12.0 | PDF document generation |
| share_plus | ^12.0.2 | Native share sheet |
| file_picker | ^11.0.2 | File selection |
| app_links | ^6.0.0 | Deep linking |
| http | ^1.2.0 | HTTP requests |
| uuid | ^4.5.3 | UUID generation |
| archive | ^4.0.4 | Archive handling |
| crypto | ^3.0.6 | Cryptographic functions |
| package_info_plus | ^9.0.1 | App metadata |

## Sync & Offline

**Sync Queue:**
- Local queue of pending operations (`SyncQueueItems` table)
- Supports RAT creation/updates and signature uploads
- Process via `ProcessSyncQueue` use case
- Checkpoints stored via `LocalSyncCheckpointRepository`

**Remote Sync:**
- Download remote RATs via `DownloadRemoteRats`
- Upload queue via `EnqueueRatSync`, `EnqueueAssinaturaSync`
- Offline access grants 7-day session validity

## Monitoring & Observability

**Error Tracking:**
- Custom error logging via `AppErrorLog`
- FlutterError handler for uncaught exceptions
- PlatformDispatcher error handler for isolate errors

**Logs:**
- Structured debug logging via `LocalDatabaseDebugLog`
- Audit logging for sensitive operations (bootstrap failures)
- Log levels: info, error, audit

## Environment Configuration

**Required runtime configuration:**
- Supabase URL (user-provided endpoint)
- Supabase anon/public key (user-provided)
- Database encryption key (generated and stored securely)

**Stored locally:**
- Remote endpoint configuration
- Auth tokens (access + refresh)
- Session state
- Sync checkpoints

## Webhooks & Callbacks

**Supabase Realtime:**
- Not detected in current implementation

**Deep Links:**
- `app_links` package integrated for deep linking support
- Not actively configured in current code

---

*Integration audit: 2025-06-15*
# 07 — Fluxos Principais

> **Proposito:** sequencias end-to-end dos caminhos criticos do app.
>
> **Fontes:** `tech_report_app.dart`, use cases, view models, materiais
> `docs/flows/` (consulta interna).

## FL-01 — Bootstrap do aplicativo

```text
main → bootstrap → AppScope.create (Drift, repos, use cases)
  → AppBootstrapViewModel.bootstrap()
  → estado derivado de modo salvo + sessao local/remota
  → AppShell renderiza tela adequada
```

**Estados possiveis (`AppBootstrapStatus`):**

| Estado | Tela |
| --- | --- |
| `modeChoiceRequired` | Escolha local/empresa |
| `localOnboarding` | Onboarding |
| `localLocked` | Desbloqueio PIN |
| `localUnlocked` | Home local |
| `remoteEndpointRequired` | Config Supabase |
| `remoteLoginRequired` | Login |
| `companyUnlocked` | CompanyShell |

**Confirmado.**

## FL-02 — Criar RAT (modo local)

```text
LocalHome → RatForm (novo)
  → RatFormViewModel.saveDraft / finalize
  → DriftRatRepository.persist
  → syncStatus: localOnly
  → opcional: SignatureCapture → DriftAssinaturaRepository
  → ShareRatLocally / RatPdfShareService
```

**Confirmado.**

## FL-03 — Criar RAT (modo empresa)

```text
CompanyShell → RatList → RatForm
  → persistencia local imediata (ownerType: companyTecnico)
  → EnqueueRatSync (payload inclui campos RAT)
  → ProcessSyncQueue → SupabaseRemoteRatRepository.upsert
  → atualiza syncStatus na entidade/lista
```

**Confirmado.**

**Nota Sprint 8.2:** payload inclui `responsavelDocumento`; a coluna remota
esta versionada em `0008_responsavel_documento.sql`.

## FL-04 — Download incremental

```text
login ou sync manual
  → DownloadRemoteRats
  → le checkpoint do escopo atual
  → consulta public.rats (server_updated_at > checkpoint)
  → merge no Drift respeitando RLS efetiva
  → atualiza checkpoint
```

**Confirmado.**

## FL-05 — Logout empresa com pendencias

```text
usuario aciona sair
  → countPending(empresaId, usuarioId)
  → se > 0: dialogo (sync antes / sair / cancelar)
  → SignOutCompany (limpa sessao remota + tokens)
  → dados locais permanecem
  → bootstrap → tela de login
```

**Confirmado** — `company_shell.dart`.

## FL-06 — Login e montagem de sessao

```text
email/senha → Supabase Auth
  → user.id
  → consulta public.tecnicos (e public.app_admins se aplicavel)
  → monta SessaoRemota (sem tokens puros)
  → salva tokens em FlutterSecureTokenStore
  → CompanyShell
```

**Confirmado** — `bootstrap_company_session`, `sign_in_company`.

## FL-07 — Troca de senha obrigatoria

```text
login com must_change_password = true
  → CompanyHome exibe aviso
  → ChangeCompanyPassword
  → atualiza flag local/remota
  → libera uso normal
```

**Confirmado.**

## FL-08 — Admin global

```text
login app_admin (sem tecnico vinculado)
  → CompanyShell area appAdmin
  → ListAdminEmpresas / ListAdminTecnicos via Supabase + RLS
```

**Confirmado** — parcial em operacoes de escrita.

## FL-09 — Export/import backup local

```text
export: LocalDataExportShareService → JSON (rats + assinaturas + assets refs)
  → share via SO

import: file picker → LocalDataImportParser → preview
  → ApplyLocalDataImport → merge Drift
```

**Confirmado.**

**Confirmado 8.2:** export/import preserva `responsavelDocumento`.

## FL-10 — Central de sincronizacao

```text
CompanyShell → SyncCenterScreen
  → SyncCenterViewModel.load (fila + falhas)
  → acoes: refresh, retry item, sync all (conforme VM)
```

**Confirmado.**

## FL-11 — Fluxo Sprint 8.2 (documento responsavel)

```text
RatForm: campo opcional documento
  → trim vazio → null
  → save local + enqueue sync
  → PDF/share: linha "Documento do responsavel"
  → backup JSON: responsavelDocumento
  → download remoto: restaura coluna
```

**Status:** Implementado no codigo; ver pendencias de testes em
[10-pendencias-e-perguntas-abertas.md](./10-pendencias-e-perguntas-abertas.md).

## FL-12 — Convite de empresa e criacao de conta

```text
admin global/admin empresa
  -> cria convite pelo app
  -> app gera codigo/link compartilhavel
  -> convidado abre Aceitar convite
  -> valida codigo + e-mail
  -> Criar conta: Supabase Auth signUp
  -> se Auth exigir confirmacao: salvar e-mail+codigo em storage seguro
  -> usuario confirma e-mail
  -> login normal aceita convite pendente automaticamente
  -> accept_tecnico_convite cria public.tecnicos
  -> CompanyShell
```

**Confirmado Sprint 8.5:** senha nao e salva localmente. O storage seguro guarda
somente e-mail, codigo e data do convite pendente.

### Variante: ja tenho conta

```text
Aceitar convite -> Ja tenho conta
  -> login Supabase
  -> accept_tecnico_convite
  -> cria/retorna vinculo em public.tecnicos
  -> CompanyShell
```

### Variante: Auth sem vinculo TechReport

Se existe usuario em `auth.users`, mas nao existe convite pendente/aceito nem
linha em `public.tecnicos`, o login normal autentica no Supabase, mas o app deve
bloquear a entrada:

```text
Conta remota autenticada, mas nao vinculada a uma empresa TechReport.
```

Nesse caso o app limpa sessao/tokens locais para nao reutilizar sessao anterior.
Para recuperar, criar novo convite para o e-mail e usar `Aceitar convite` ->
`Ja tenho conta`.

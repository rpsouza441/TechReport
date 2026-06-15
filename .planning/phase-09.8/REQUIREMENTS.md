# Requirements — Phase 9.8

**Error Handling Improvements**

---

## EH-01: Silent catch blocks em bootstrap.dart

**Problem:** `catch (_)` em bootstrap.dart descarta exceções sem logging.

**Files:**
- `lib/app/bootstrap/bootstrap.dart:74` - `_logBootstrapScopeAuditFailure`
- `lib/app/bootstrap/bootstrap.dart:82` - key store access

**Acceptance criteria:**
- [ ] Adicionar logging com `debugPrint` ou `logger`
- [ ] Manter user-facing messages quando apropriado
- [ ] Não quebrar o app se o logging falhar

**Source:** CONCERNS.md - Missing Error Handling

---

## EH-02: Silent catch blocks em company_shell.dart

**Problem:** `catch (_)` em sync status descarta exceções.

**Files:**
- `lib/app/navigation/company_shell.dart:494`

**Acceptance criteria:**
- [ ] Logar erro com contexto
- [ ] Informar usuário se a operação falhou

**Source:** CONCERNS.md - Missing Error Handling

---

## EH-03: Silent catch blocks em app_admin_view_model.dart

**Problem:** Múltiplos `catch (_)` em view model.

**Files:**
- `lib/features/company_admin/presentation/view_models/app_admin_view_model.dart:40,59,95,123`

**Acceptance criteria:**
- [ ] Adicionar logging em cada catch
- [ ] Manter `errorMessage` para UI
- [ ] Evitar Duplicate logging

**Source:** CONCERNS.md - Missing Error Handling

---

## EH-04: Silent catch blocks em supabase_auth_repository.dart

**Problem:** `catch (_)` em repository descarta exceções críticas de auth.

**Files:**
- `lib/features/company_auth/data/repositories/supabase_auth_repository.dart:73,142,223,366`

**Acceptance criteria:**
- [ ] Logar com stack trace
- [ ] Manter user-friendly error messages
- [ ] Considerar exception types específicos

**Source:** CONCERNS.md - Missing Error Handling

---

## EH-05: Catch blocks sem exception types específicos

**Problem:** `catch (_)` perde contexto de erro.

**Files:**
- `lib/features/rat/presentation/view_models/rat_form_view_model.dart:388,498,527,627`

**Acceptance criteria:**
- [ ] Usar `catch (e, st)` para capturar stack trace
- [ ] Logar `st` em nível debug
- [ ] Manter mensagens de erro para o usuário

**Source:** CONCERNS.md - Missing Error Handling

---

## EH-06: Validação fraca em backup import

**Problem:** Legacy JSON import não valida checksum.

**Files:**
- `lib/features/local_auth/data/services/local_backup_parser.dart:57-58`

**Acceptance criteria:**
- [ ] Adicionar aviso para legacy backups
- [ ] Implementar validação básica (hash do conteúdo)
- [ ] Documentar limitações do legacy format

**Source:** CONCERNS.md - Missing Error Handling

---

## Out of Scope

- Refatoração completa de exception handling (futuro)
- Implementação de sistema de error boundaries global
- Integração com crash reporting (Sentry, etc.)

---

*Requirements created: 2026-06-15*

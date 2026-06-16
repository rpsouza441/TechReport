# TechReport — Roadmap

**Current phase:** Sprint 9.8 (planned)
**Last updated:** 2026-06-15

---

## Phase Structure

```
Sprint 1-4     → Core MVP (local mode)
Sprint 5      → Sync MVP, PDF, signatures
Sprint 6-7    → Extended RAT fields, admin features
Sprint 8/8.5  → Team management, invites, permissions
Sprint 9/9.5-9.7 → Hardening, UI cleanup, security, tech debt
Sprint 9.8-9.19   → Remaining CONCERNS.md items (error handling, performance, security, etc.)
Sprint 20         → QA, Android build, release candidate
Sprint 21         → Residual hardening, legacy DB migration (future)
Sprint 22         → Physical device testing (future)
```

---

## Completed Phases

### Sprint 1-4: Core MVP (Local Mode)
- RAT entity with core fields
- Local SQLite storage
- PIN protection
- Basic UI

### Sprint 5: Sync MVP
- Supabase integration
- RAT sync with conflict resolution
- PDF generation
- Signature capture
- RLS for technician/manager

### Sprint 6-7: Extended Features
- Extended RAT fields (responsável documento, etc.)
- Company admin panel
- App admin capabilities
- Theme system

### Sprint 8/8.5: Team Features
- Invite system
- Team management
- Permission model
- Account creation flow

### Sprint 9: Hardening (Current)
- Error handling improvements
- UI duplication cleanup (Sprint 9.4)
- Security hardening (PBKDF2, backups)
- Theme refinements

### Sprint 9.5: Code Review Fixes (Complete)
**Source:** REVIEW.md from `/gsd-code-review`

**Objectives:**
- Fix all critical issues from code review
- Fix all warnings from code review
- Address informational items where applicable
- Zero findings left unresolved before release

**Deliverables:**
- CR-01: Error handling in reopenForCorrection
- WR-01: UpdateTecnicoLocal injection fix
- WR-02: shouldRepaint optimization
- WR-03: Magic number as constant
- IN-01: Comment in Portuguese
- IN-02: UUID for signature ID (optional)
- IN-03: Fire-and-forget pattern documented

**Success criteria:**
- All CRITICAL findings resolved
- All WARNING findings resolved
- All INFO findings addressed or explicitly deferred
- Tests pass after changes

### Sprint 9.6: Sync Queue Bug Fixes (Complete)
**Source:** Bugs discovered during offline testing

**Objectives:**
- Corrigir RAT que fica pendente apos falha offline ✅
- Corrigir botao retry que nao funciona ✅
- Adicionar identificacao da operacao na fila ✅

**Deliverables:**
- RAT fica pendente apos falha — itens processados apos restart ✅
- Retry funcional — botao dispara sync corretamente ✅
- Fila indica operacao — mostra qual RAT/assinatura ✅

**Commits:**
- `76163c6` fix(v9.6): sync queue bug fixes
- `87d3b7a` fix(v9.6): pass vm to _buildSection for getRatInfo access
- `3fbc7cb` fix(v9.6): retry manual ignora nextAttemptAt e processa falhados imediatamente
- `2274e91` fix(v9.6): nao sobrescreve status failed ao reabrir app
- `5fbeda0` fix(v9.6): tryMarkProcessing aceita status failed para retry
- `16e5dff` fix(v9.6): recarregar lista RATs apos retry de sync

### Sprint 9.7: Tech Debt Cleanup (Complete)
**Source:** CONCERNS.md - Tech Debt section

**Objectives:**
- Remover generated Drift file do source tree ✅
- Extrair constantes de magic numbers ✅
- Refatorar metodos grandes ✅
- Extrair widgets compostos ✅

**Deliverables:**
- `.g.dart` removido do git tracking ✅
- `_buildRatForSave()` extraído do `save()` ✅
- `ConviteCard` extraído para arquivo separado ✅
- admin_empresa_area.dart: 833 → 672 linhas ✅
- rat_form_view_model.dart: 956 → 912 linhas ✅

**Commits:**
- `b627c37` docs(v9.7): create plan for Tech Debt cleanup
- `5030dd6` test(v9.7): add edge case tests for save()
- `4852c85` refactor(v9.7): extract _buildRatForSave method
- `79e8df5` refactor(v9.7): extract ConviteCard widgets

---

## Upcoming Phases

### Sprint 9.8: Error Handling (Complete)
**Source:** CONCERNS.md - Missing Error Handling

**Objectives:**
- Corrigir silent catch blocks ✅
- Adicionar logging de erros ✅
- Melhorar mensagens para o usuário ✅

**Deliverables:**
- bootstrap.dart: debugPrint com stack trace ✅
- company_shell.dart: logging de erros de sync ✅
- app_admin_view_model.dart: debugPrint em todos os catch ✅
- supabase_auth_repository.dart: logging com stack trace ✅
- rat_form_view_model.dart: debugPrint com stack trace ✅
- local_backup_parser.dart: SHA-256 hash para legacy backups ✅

**Commits:**
- `448ae16` fix(v9.8): add error logging to catch blocks

---

## Upcoming Phases

### Sprint 9.9: Performance (Complete)
**Source:** CONCERNS.md - Performance Concerns

**Objectives:**
- Corrigir AnimatedBuilder rebuilds ✅
- Implementar paginação ✅
- Corrigir gerador de números RAT ✅

**Deliverables:**
- admin_empresa_area.dart: ListenableBuilder substituindo AnimatedBuilder ✅
- rat_list_screen.dart: ListenableBuilder substituindo AnimatedBuilder ✅
- rat_form_view_model.dart: timestamp + UUID para número de RAT ✅

**Commits:**
- `13663ec` fix(v9.9): performance improvements

---

## Upcoming Phases

### Sprint 9.10: Security (Complete)
**Source:** CONCERNS.md - Security Considerations

**Objectives:**
- Migrar para PKCE ✅
- Aumentar PBKDF2 iterações ✅
- Configurar secure storage ✅
- Adicionar criptografia de backup ⚠️ (deferido)

**Deliverables:**
- supabase_client_factory.dart: PKCE auth flow ✅
- local_pin_secret_store.dart: 100k iterações + migração automática ✅
- flutter_secure_token_store.dart: storageNamespace configurado ✅
- CONCERNS.md: backup encryption marcado como deferido ⚠️

**Commits:**
- `72545af` fix(v9.10): security improvements

---

## Upcoming Phases

### Sprint 9.11: UI Duplication
**Status:** Planned
**Source:** CONCERNS.md - Performance Concerns

**Objectives:**
- Corrigir AnimatedBuilder rebuilds
- Implementar paginação na lista RATs

### Sprint 20: Release Preparation
**Target:** 2026-06 (1-2 sprints)

**Objectives:**
- QA and manual testing
- Android build verification
- Play Store assets preparation
- Privacy policy
- Beta testing with real users

**Deliverables:**
- Working Android APK
- Play Store listing draft
- Test plan execution
- Bug fixes from testing

**Success criteria:**
- Zero critical bugs
- All core flows tested manually
- APK builds without errors
- Screenshots and description ready

---

### Sprint 21: Residual Hardening (Future)
**Status:** Planned, not started

**Objectives:**
- Remaining security hardening
- Legacy database migration path
- Performance optimization
- Accessibility improvements

**Note:** Legacy DB migration deferred — do not migrate old `rat/` directory data in this phase.

---

### Sprint 22: Physical Device Testing (Future)
**Status:** Planned, not started

**Objectives:**
- Test on physical Android devices
- Verify biometric authentication
- Performance profiling on real hardware
- Edge case validation

---

## Release Milestones

| Milestone | Target | Status |
|----------|--------|--------|
| Sprint 20 Release Candidate | Q2 2026 | Planned |
| Play Store Submission | Q2 2026 | Planned |
| GitHub Release | Q2 2026 | Planned |
| First Real Users | Q3 2026 | Future |

---

## Dependencies

```
Sprint 20
├── All Sprint 9.x complete
├── All critical concerns resolved
├── Manual test plan executed
└── Play Store account ready

Sprint 21
├── Sprint 20 complete
├── First release feedback
└── Remaining technical debt

Sprint 22
├── Sprint 21 complete
└── Physical devices available
```

---

## Notes

- Sub-sprints (8.1, 8.2, 8.5, 9.1-9.4) exist in `docs/` for operational details
- This roadmap shows major phases only
- Adjust based on actual progress and user feedback

---

*Update this roadmap when phases are completed or scope changes.*

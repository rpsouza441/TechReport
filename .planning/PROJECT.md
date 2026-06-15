# TechReport — Project Context

**Created:** 2026-06-15
**Type:** Brownfield (existing codebase in production-ready development)
**Status:** Pre-release (Sprint 9.6 complete, Sprint 10 next)

---

## Current Milestone: v9.6 Complete

**Goal:** Corrigir bugs criticos na fila de sincronizacao que impedem recovery de operacoes que falharam offline.

**Status:** ✅ COMPLETO

**Fixes applied:**
- Auto-retry ao iniciar app
- Retry manual processa itens falhados
- Fila mostra ID da RAT
- Lista RATs atualiza após retry

**Commits:** 6 commits em 9.6

---

## Next Milestone: v10.0 Release Preparation

## 1. Vision

**One-line:** Mobile RAT (Report of Technical Assistance) management with digital signature capture for client proof-of-acceptance.

**Problem solved:** Eliminate paper-based RAT workflows where clients discard second copies. TechReport captures handwritten signatures on-device, providing immutable proof that the client accepted the service.

**Business model:** Free local mode (anyone can use); paid remote mode (requires Supabase instance). Consider charging for Supabase configuration assistance.

---

## 2. Why This Project Exists

**Personal motivation:** The owner's company uses RATs today with paper-based pain points:
- Clients take second copies and discard them
- No reliable proof of client acceptance
- Manual archival and retrieval issues

**Core differentiator:** Digital signature capture on mobile (handwriting on screen) combined with offline-first local storage and optional cloud sync.

---

## 3. Target Users

| User | Role | Primary action |
|------|------|----------------|
| Field technicians | Primary users | Create RATs, collect signatures |
| Clients | Signers | Review and sign on tablet/phone |
| Managers | Viewers | Review completed RATs (remote mode) |
| Company admins | Administrators | Manage team, invites, permissions (remote mode) |

**Note:** Solo developer building for own use case, with potential to open-source.

---

## 4. Technical Stack

**Framework:** Flutter (Dart)
**State management:** ChangeNotifier + ViewModel pattern
**Local database:** Drift (SQLite with encryption via SQLite3MultipleCiphers)
**Remote backend:** Supabase (PostgreSQL + Auth + Realtime)
**Architecture:** Clean Architecture with MVVM presentation layer

**Key dependencies:**
- `drift` + `sqlite3_flutter_libs` — local database
- `supabase_flutter` — remote sync
- `pdf` + `printing` — PDF generation
- `flutter_secure_storage` — secure credential storage
- `local_auth` — biometric authentication

**Details:** See `.planning/codebase/STACK.md`

---

## 5. Dual-Mode Operation

TechReport operates in two modes:

| Mode | Storage | Features | Target |
|------|---------|----------|--------|
| **Local** | On-device encrypted SQLite | PIN lock, biometric, backup/restore | Solo technicians, privacy-focused |
| **Company** | Supabase + local | Team sync, invites, admin panel | Teams with shared backend |

**Design decision:** Local mode is fully functional standalone. Remote mode adds collaboration features.

---

## 6. Core Features (MVP)

1. **RAT Creation** — Capture service details (client, equipment, description, etc.)
2. **Digital Signature** — Handwritten signature on screen, stored as image
3. **PDF Generation** — Export/share RAT as PDF document
4. **Local Storage** — Encrypted SQLite with PIN/biometric protection
5. **Cloud Sync** (remote mode) — Sync RATs to Supabase with conflict resolution
6. **Team Management** (remote mode) — Invite technicians, manage permissions

---

## 7. Current State

**Sprint:** Sprint 9 — decisions and adjustments post Sprint 8
**Roadmap position:** Pre-release (1-2 sprints from first public release)

**Completed:**
- Core RAT CRUD with digital signature
- PDF generation and sharing
- Local mode with PIN/biometric lock
- Encrypted local database
- Remote mode with Supabase sync
- Team management and invites
- Admin panels (company + app-level)

**In progress (Sprint 9):**
- Error handling improvements
- UI duplication cleanup (Sprint 9.4)
- Security hardening (PBKDF2 iterations, backup encryption)
- Theme system refinement

**Pending before release:**
- QA and testing
- Android build / release candidate
- Play Store submission

---

## 8. Known Concerns

**Priority concerns before release:**

| Concern | Source | Priority |
|---------|--------|----------|
| Error handling gaps | CONCERNS.md | High |
| UI duplication | Sprint 9.4 | Medium |
| Security hardening | CONCERNS.md (PBKDF2, backups) | High |
| Accessibility gaps | CONCERNS.md | Medium |
| Test coverage | CONCERNS.md | Medium |

**Details:** See `.planning/codebase/CONCERNS.md`

---

## 8.1 Performance Concerns

**Source:** `.planning/codebase/CONCERNS.md` — Performance Concerns section

| Issue | File | Impact | Fix |
|-------|------|--------|-----|
| AnimatedBuilder rebuilds entire widget tree | `company_shell.dart`, `admin_empresa_area.dart`, `rat_list_screen.dart` | Scroll performance degrades | Use `Selector` or `context.select` |
| No pagination in RAT list | `rat_list_screen.dart` | Memory issues with 100+ RATs | Implement `ListView.builder` with pagination |
| Microsecond collision in RAT number | `rat_form_view_model.dart:811-813` | Duplicate RAT numbers if created in same microsecond | Use UUID or add counter |

---

## 8.2 Accessibility Gaps

**Source:** `.planning/codebase/CONCERNS.md` — Accessibility Gaps section

| Issue | File | Impact | Fix |
|-------|------|--------|-----|
| Missing semanticsLabel on icon buttons | `admin_empresa_area.dart`, `rat_list_item_card.dart` | Screen readers can't describe buttons | Add `semanticsLabel` to all IconButtons |
| No keyboard navigation | `admin_empresa_area.dart`, `local_settings_screen.dart` | Motor-impaired users can't fully use app | Add `FocusNode` management |
| Color contrast not verified | `tech_report_status_chip.dart` | May not meet WCAG AA | Verify 4.5:1 contrast ratio |

---

## 8.3 Tech Debt (Specific)

**Source:** `.planning/codebase/CONCERNS.md` — Tech Debt section

| Issue | File | Lines | Fix |
|-------|------|-------|-----|
| God ViewModel (RatFormViewModel) | `rat_form_view_model.dart` | 879 | Break into `RatFormState`, `RatPdfGenerator`, `RatSyncHandler` |
| Large screen files | `admin_empresa_area.dart` | 833 | Extract `_FormSection` widgets |
| Database key rotation fragile | `open_encrypted_database.dart:91-203` | Complex | Add tests before changes |
| Magic strings | Multiple files | Scattered | Use enums and constants |
| Duplicate error handling | `admin_empresa_view_model.dart` | Multiple | Create base ViewModel class |

---

## 8.4 UI Duplication (Sprint 9.4 Pending)

**Source:** `.planning/codebase/CONCERNS.md` — UI Duplication section

**Already resolved:**
- UI-03: `_EmptyRatState` → `TechReportStateView.empty`
- UI-04: `_SettingsCard` + `ProfileCard` → `LocalInfoCard`

**Still pending:**

| ID | Issue | Files | Solution |
|----|-------|-------|----------|
| UI-07 | Dialog de descarte duplicado | `rat_form_screen.dart`, `company_edit_profile_screen.dart` | Create `showDiscardDialog()` |
| UI-09 | AlertDialogs de confirmacao | 8+ arquivos | Create `showTechReportConfirmationDialog()` |
| UI-12 | Convite cards duplicados | `admin_empresa_area.dart`, `app_admin_company_detail_screen.dart` | Extract to `company_admin/widgets/` |
| UI-13 | Admin chips/toggles duplicados | Mesmos arquivos acima | Extract `AdminUserActionChips` |
| CODE-01 | PDF duplicado (preview vs export) | `rat_pdf_share_service.dart` | Extract `_renderRatPdfBytes()` |
| CODE-02 | AlertDialog booleano espalhado | Mltiplos arquivos | Consolidar com UI-09 |

**Reference:** `docs/sprint9.4/specs/` contains specs for each item.

---

## 8.5 Documentation Gaps

**Source:** `.planning/codebase/CONCERNS.md` — Missing Documentation section

| Gap | Impact | Fix |
|-----|--------|-----|
| No database migration strategy | Schema changes risk data loss | Document and implement version-based migrations |
| RPC calls undocumented | Unknown API contracts | Add doc comments to `supabase_auth_repository.dart` |
| No Architecture Decision Records | Key decisions not explained | Create `.planning/adr/` with ADRs |

---

## 8.6 Fragile Areas (Careful Modifications)

**Source:** `.planning/codebase/CONCERNS.md` — Fragile Areas section

| Area | Risk | Safe modification |
|------|------|-------------------|
| Database key rotation | Silent data loss if rekey fails | Add extensive tests first |
| Invite expiration (7 days) | No user notification | Add UI warning before expiry |
| Supabase session refresh | Silent logout on network issues | Add retry logic |

---

## 9. Constraints & Decisions

**Constraints:**
- Must work offline (field technicians often have poor connectivity)
- Must be simple to deploy (anyone can set up Supabase)
- Must be secure (sensitive client data on device)

**Decisions already made:**
- SQLite3MultipleCiphers for database encryption
- Supabase over other backends (simplicity, Auth built-in)
- Drift ORM over other options (type-safe, Flutter-native)
- ChangeNotifier over BLoC/Riverpod (simplicity, Flutter-recommended)

**ADRs:** Not yet documented — consider adding in `.planning/adr/`

---

## 10. Release Plan

**Next milestone:** Sprint 10 — QA, Android build, release candidate

**Release criteria:**
- [ ] All Sprint 9 concerns addressed
- [ ] Manual testing complete
- [ ] Android APK builds successfully
- [ ] Play Store assets prepared (screenshots, description, etc.)
- [ ] Privacy policy in place
- [ ] Test with real users (field technicians)

**Future considerations:**
- GitHub release with APK download
- Documentation for self-hosted Supabase setup
- Possible paid tier for Supabase configuration assistance

---

## 11. Project Health

| Metric | Status | Notes |
|--------|--------|-------|
| Code organization | Good | Clean Architecture + feature modules |
| Shared components | Good | TechReportCard, ErrorBanner, etc. |
| Test coverage | Low | 17 test files, limited integration tests |
| Documentation | Good | specs in `documentacao/`, sprints in `docs/` |
| Technical debt | Medium | Large ViewModels, some duplication |
| Security | Medium | Hardening in progress |
| Performance | Medium | AnimatedBuilder rebuilds, no pagination |
| Accessibility | Low | Missing semantics, no keyboard nav |

---

## 12. Related Documents

- `.planning/codebase/` — Technical mapping (STACK, ARCHITECTURE, CONCERNS, etc.)
- `.planning/intel/codebase-patterns.md` — UI duplication patterns
- `documentacao/spec/` — Functional requirements and rules
- `docs/sprint9/` — Current sprint details
- `docs/sprint10/` — Next sprint plan
- `README.md` — Project overview

---

## 13. Next Steps

1. **Complete Sprint 9** — Address remaining concerns
2. **Sprint 10** — QA, Android build, release candidate
3. **Beta testing** — Deploy to real field technicians
4. **Play Store release** — Submit for review
5. **GitHub release** — Open-source with instructions

---

*This document is the source of truth for project context. Update when scope, constraints, or priorities change.*

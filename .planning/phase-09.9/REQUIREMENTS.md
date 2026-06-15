# Requirements — Phase 9.9

**Performance Improvements**

---

## PERF-01: AnimatedBuilder rebuilds entire widget tree

**Problem:** `AnimatedBuilder` com ViewModel faz rebuild completo do widget tree.

**Files:**
- `lib/app/navigation/company_shell.dart:250`
- `lib/features/company_admin/presentation/screens/admin_empresa_area.dart:42-73`
- `lib/features/rat/presentation/screens/rat_list_screen.dart:90-125`

**Acceptance criteria:**
- [ ] Usar `Selector` ou `context.select` para rebuilds granulares
- [ ] Manter funcionalidade existente
- [ ] Performance de scroll não degradada

**Source:** CONCERNS.md - Performance Concerns

---

## PERF-02: No pagination/infinite scroll optimization

**Problem:** `ListView.separated` renderiza todos os RATs sem virtualização.

**Files:**
- `lib/features/rat/presentation/screens/rat_list_screen.dart:195-228`

**Acceptance criteria:**
- [ ] Usar `ListView.builder` para virtualização
- [ ] Implementar paginação com `PaginationController` ou similar
- [ ] Manter filtros e ordenação

**Source:** CONCERNS.md - Performance Concerns

---

## PERF-03: RAT number generator uses microseconds

**Problem:** `_newRatNumber()` usa `microsecondsSinceEpoch` — risco de duplicidade.

**Files:**
- `lib/features/rat/presentation/view_models/rat_form_view_model.dart:811-813`

**Acceptance criteria:**
- [ ] Usar UUID ou GUID para garantir unicidade
- [ ] Manter formato legível se possível
- [ ] Sem breaking changes na API

**Source:** CONCERNS.md - Performance Concerns

---

## Out of Scope

- Refatoração completa de estado (requer arquitetura maior)
- Cache de imagens
- Otimização de queries SQLite

---

*Requirements created: 2026-06-15*

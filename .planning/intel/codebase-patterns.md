# Codebase Patterns

## UI Duplication Analysis

**Source:** `docs/sprint9.4/README.md` - Sprint 9.4 - Levantamento de Componentizacao e Reutilizacao de UI

**Analysis date:** 2026-06-11 (original), 2026-06-14 (normalizacao aplicada)

**Scope:** ~45 arquivos de apresentacao (screens, widgets, view models)

---

## Classification Matrix

| Pattern | Definition | Target Location | Examples |
|---------|------------|-----------------|----------|
| **Cross-feature reuse** | Widget usado em 3+ features diferentes | `lib/shared/presentation/widgets/` | TechReportCard, TechReportErrorBanner, TechReportStateView |
| **Local extraction** | Evita duplicacao DENTRO da mesma feature | `lib/features/X/presentation/widgets/` | _ConviteCard (admin), _TecnicoActions (admin) |
| **Logical extraction** | Logica no-visual (PDF, sync, assinatura) | `lib/features/X/domain/services/` | RatPdfGenerator, RatSyncHandler |
| **No extraction** | Widget especifico demais ou apenas 1-2 usos | Manter inline | Shells local/empresa, RAT Form fields |

**Decision criteria:**
- Abstracao com mais de 5 props condicionais = rejeitar
- Componentes especificos de feature = nao mover para shared sem evidencia cross-feature
- Tamanho isolado do arquivo nao e prova de duplicacao

---

## Key Findings

### Well-reused components (shared/)
| Component | File | Usage | Status |
|-----------|------|-------|--------|
| TechReportCard | tech_report_card.dart | 21 files | Excelente |
| TechReportErrorBanner | tech_report_error_banner.dart | 16 files | Excelente |
| TechReportFormHeader | tech_report_form_header.dart | 14 files | Bom |
| TechReportStateView | tech_report_state_view.dart | 7 files | Bom |
| TechReportSectionHeader | tech_report_section_header.dart | 8 files | Bom |
| MetricSlateSpacing | metric_slate_spacing.dart | All | Excelente |

### Underutilized components
| Component | Current usage | Should use |
|----------|---------------|-----------|
| TechReportInfoRow | 4 files | admin_empresa_area.dart, app_admin_company_detail_screen.dart |
| TechReportModeTitle | 3 files | Avaliar se merece manter |

---

## Pending Refactoring Items

See `.planning/codebase/CONCERNS.md` section "UI Duplication" for full details.

**Quick reference:**
- UI-07: Dialog de descarte (`showDiscardDialog`)
- UI-09: AlertDialog booleano (`showTechReportConfirmationDialog`)
- UI-12: Convite cards (`_ConviteCard`, `_ConviteShareSheet`)
- UI-13: Admin chips/toggles (`AdminUserActionChips`)
- CODE-01: PDF unificado (`_renderRatPdfBytes`)
- CODE-02: Consolidar com UI-09

---

## Related Documents

- `docs/sprint9.4/README.md` - Full analysis
- `docs/sprint9.4/specs/` - Specs for each pending item
- `docs/sprint9.4/specs/traceability.md` - Status tracking
- `.planning/codebase/CONCERNS.md` - Technical concerns including UI duplication

# Requirements — Phase 9.7

**Tech Debt Cleanup**

---

## TD-01: Generated file no source tree

**Problem:** Arquivo gerado `tech_report_local_database.g.dart` (6603 linhas) esta no source control.

**Acceptance criteria:**
- [ ] Arquivo `.g.dart` removido do git tracking
- [ ] `.gitignore` atualizado
- [ ] Build continua funcionando

**Source:** CONCERNS.md - Tech Debt

---

## TD-02: Magic numbers no RatFormViewModel

**Problem:** Magic numbers espalhados no codigo dificultam manutencao.

**Acceptance criteria:**
- [ ] Magic numbers extraidos como `static const`
- [ ] Nomes descritivos para cada constante
- [ ] Usages substituidos

**Source:** CONCERNS.md - Tech Debt

---

## TD-03: Metodos grandes no RatFormViewModel

**Problem:** Metodos com mais de 50 linhas dificultam leitura e teste.

**Acceptance criteria:**
- [ ] Metodos grandes refatorados
- [ ] Metodos menores com nomes descritivos
- [ ] Logica mantida intacta

**Source:** CONCERNS.md - Tech Debt

---

## TD-04: Widgets compostos em screens

**Problem:** Screens com mais de 700 linhas e widgets aninhados.

**Acceptance criteria:**
- [ ] Widgets internos extraidos para arquivos separados
- [ ] Screens mais limpas e organizadas
- [ ] Composicao sobre aninhamento

**Source:** CONCERNS.md - Tech Debt

---

## Out of Scope

- Refatoracao completa do RatFormViewModel (muito grande para uma phase)
- Extracao de classes separadas (ProfileFetcher, etc.)
- Modificacoes em funcionalidade

---

*Requirements created: 2026-06-15*

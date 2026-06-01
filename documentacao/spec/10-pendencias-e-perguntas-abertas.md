# 10 — Pendencias e Perguntas Abertas

> **Proposito:** registrar lacunas explicitamente — nada escondido entre spec e
> codigo.
>
> **Ultima revisao:** alinhada a Sprint **8.2** (2026-05-30).
>
> **Fontes:** diff codigo vs `docs/sprint8.2/`, `estado-do-projeto.md`,
> grep no repositorio.

## P-01 — Sprint 8.2 implementada no codigo; falta fechamento de QA

| Item | Esperado (Sprint 8.2) | Estado no repo |
| --- | --- | --- |
| Campo no formulario RAT | UI + view model | **Implementado** |
| PDF / share textual | Exibir documento ou "Nao informado" | **Implementado** |
| Export/import local JSON | Campo `responsavelDocumento` | **Implementado** |
| Migration Supabase | `alter table rats add responsavel_documento` | **Implementado** — `0008_responsavel_documento.sql` |
| Acentuacao PT-BR | Revisao ampla | **Parcial** — algumas telas corrigidas |
| `flutter analyze` limpo | Criterio de fechamento | **Feito** em 2026-06-01 |
| `flutter test` | Criterio de fechamento | **Feito** em 2026-06-01, 15 testes |

**Implementado (confirmado):** dominio, Drift v7, drift repo, DTO, enqueue,
leitura remota, formulario, PDF/share, export/import e migration remota.

**Pendente:** QA manual e testes automatizados especificos para regressao do
campo.

---

## P-02 — Documentacao desatualizada antes desta reorganizacao

`documentacao/estado-do-projeto.md` e `README.md` raiz citavam Sprint 6 como
"frente atual". **Corrigido neste commit de documentacao** para Sprint 8.2.

Materiais internos em `docs/README.md` ainda listam Sprint 6 como ativa —
**esperado**, pois `docs/` nao e versionado e pode estar defasado; nao alterar
via commit oficial.

---

## P-03 — Funcionalidades fora do MVP implementado

Confirmado como **nao implementado** (referencia `docs/prompt.md` e codigo):

- sync remoto de assinatura;
- upload remoto de anexos;
- visualizacao/restauracao de RATs deletados;
- area gerencial dedicada com filtros avancados;
- edicao gerencial de RAT de outro tecnico;
- auditoria de ultimo modificador;
- RBAC avancado alem dos papeis atuais;
- provisionamento automatico de instancia Supabase;
- build Android / release candidate (Sprint 9);
- criptografia SQLite (Sprint 10).

---

## P-04 — Admin empresa / equipe (Sprint 8.5)

**Status:** implementado no codigo em nivel operacional inicial.

**Confirmado:** migrations `0009` a `0012`, `CompanyAdminRepository`, telas
admin e tela de aceite de convite cobrem listagem, criacao, cancelamento,
validacao e aceite de convites.

**Validado manualmente em 2026-06-01:**

- criar/inativar/ativar empresa pelo app;
- convidar admin da empresa;
- copiar codigo/link e compartilhar convite;
- criar conta pelo app com convite valido;
- confirmar e-mail manualmente em desenvolvimento;
- login normal conclui convite pendente salvo quando o convite ainda existe;
- login Auth sem linha em `public.tecnicos` bloqueia acesso ao modo empresa;
- convite cancelado antes da confirmacao deixa a conta em `auth.users`, mas nao
  cria membro na equipe.

**Pendente:** QA manual/RLS ampliado e testes automatizados antes de considerar
pronto para release candidate.

---

## P-05 — Numeracao de RAT

**Pergunta aberta:** `numero` e texto livre ou deve seguir sequencia por
tecnico/empresa?

**Estado:** campo `String` sem gerador automatico evidente no domain.

**Fonte parcial:** `docs/prompt.md` (nao reproduzido integralmente aqui).

---

## P-06 — Validacao de documento do responsavel

**Decisao fechada para 8.2:** sem validacao CPF/CNPJ.

**Pergunta futura:** ha necessidade de mascara, tipo (CPF/CNPJ/RG) ou
validacao fiscal em sprint posterior?

---

## P-07 — Cobertura de testes automatizados

**Pendencia:** testes existem para tema, widgets, login empresa e lista RAT; nao
ha suite integrada de sync/auth/RLS/convites.

Foi criada a proposta de sprint de testes em
[`11-sprint-testes-automatizados.md`](./11-sprint-testes-automatizados.md).

---

## P-08 — Metric Slate — cobertura de telas

**Pendencia:** nem todas as telas usam tokens/componentes compartilhados.

Sub-sprint 8.1 (tema visual amplo) documentada em `docs/sprint8.1/` — status
de fechamento **nao confirmado** nesta spec.

---

## P-09 — Migration remota vs DTO

Codigo envia `responsavel_documento` no payload e a migration `0008` esta
versionada.

**Risco residual:** ambientes Supabase que nao aplicaram a migration ainda podem
falhar no sync. A acao operacional e aplicar migrations ate `0012`.

---

## P-10 — Perguntas ao time (bloqueantes futuras)

1. Sprint 8.2 deve ser fechada antes de retomar 8.1 (visual) ou 8.5 (equipe)?
2. Qual criterio formal marca "Sprint 8 fechada" vs sub-sprints 8.x?
3. `documentacao/` deve passar a espelhar specs por sprint ou apenas este
   pacote SDD agregado? (**Decisao atual:** pacote agregado + estado-do-projeto**)

---

## Checklist de sincronizacao spec ↔ codigo

Use antes de fechar Sprint 8.2:

- [x] Formulario expoe `responsavelDocumento`
- [x] PDF e share exibem campo
- [x] Export/import JSON inclui campo
- [x] Migration Supabase versionada
- [ ] Teste manual minimo (10 passos em `docs/sprint8.2/passos.md`)
- [ ] Atualizar `documentacao/estado-do-projeto.md`
- [ ] Atualizar RF-04.4 nesta spec para **Implementado**
## P-11 - Bloqueio por PIN antes do modo empresa

**Pendencia:** quando o app esta bloqueado por PIN/local, o usuario pode ficar
preso antes de acessar o modo empresa caso nao saiba o PIN.

**Risco:** suporte precisa orientar reset de cache local, ruim para usuario
final.

**Acao futura:** avaliar recuperacao de PIN, troca de modo antes do PIN ou reset
seguro do cache local.

---

## P-12 - Sprint 8.5 operacional

**Status:** decisoes atualizadas em `docs/sprint8.5/spec-driven.md`.

**Confirmado:** fluxo operacional de convite/criacao pelo app existe. Em uso
real, o Supabase Dashboard nao deve ser parte da criacao de usuario. Em
desenvolvimento, pode-se confirmar e-mail manualmente enquanto SMTP/templates
nao estiverem configurados.

**Regra validada:** usuario existente apenas em `auth.users` nao e membro da
empresa. Para entrar na equipe, precisa aceitar convite valido e gerar linha em
`public.tecnicos`.

**Pendencia principal:** ampliar cobertura automatizada e validar RLS/RPCs com
mais cenarios negativos.

---

## P-13 - Deep link de convite ainda nao configurado

**Status atual:** o app gera link no formato
`techreport://convite?codigo=XXXXXXXX`, mas ele ainda funciona apenas como texto
copiavel/compartilhavel.

**Pendencia:** configurar deep link nativo para abrir o app e preencher o codigo
automaticamente na tela `Aceitar convite`.

**Acao futura:**

- Android: configurar intent filter no `AndroidManifest.xml`;
- iOS: configurar URL scheme no `Info.plist`;
- Flutter: ler link recebido com pacote como `app_links`;
- Navegacao: abrir `CompanyAcceptInviteScreen` com codigo preenchido.

---
## P-14 - Exception handler global

**Pendencia:** o app ainda nao tem um tratamento global padronizado para
excecoes nao esperadas de Flutter/Dart/plugins. Quando ocorre uma assertion de
plugin/framework, a mensagem tecnica pode aparecer na UI.

**Risco:** usuario final ve erro tecnico como `_dependents.isEmpty`,
`asyncStorage`, stack traces ou mensagens internas de pacote.

**Acao futura:**

- configurar `FlutterError.onError` e `PlatformDispatcher.instance.onError`;
- registrar/logar erros tecnicos em canal apropriado;
- exibir mensagem amigavel generica na UI;
- manter mapeamentos locais para erros esperados de Auth/Supabase.

---

## P-15 - Reenviar confirmacao de e-mail

**Pendencia:** a tela pos-cadastro com convite orienta o usuario a confirmar o
e-mail, mas ainda nao oferece botao para reenviar confirmacao.

**Acao futura:** avaliar suporte via Supabase Auth/SMTP e adicionar acao
`Reenviar confirmacao` sem salvar senha localmente.

---

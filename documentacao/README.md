# Documentacao Do TechReport

Esta pasta reune a **documentacao oficial versionada** do TechReport.

Materiais auxiliares de sprint, prompts e decisoes de trabalho ficam em `docs/`
(nao versionados — ver `.gitignore`).

## Comece Aqui

1. [Visao geral](./visao-geral.md)
2. [Especificacao SDD](./spec/README.md) — mapa completo dos specs
3. [Arquitetura](./arquitetura.md)
4. [Estado do projeto](./estado-do-projeto.md)
5. [Execucao local](./execucao-local.md)
6. [Configuracao Supabase](./configuracao-supabase.md)
7. [Contribuicao](./contribuicao.md)

## Estrutura

```text
documentacao/
  README.md                 ← este arquivo
  visao-geral.md            ← produto e modos
  arquitetura.md            ← camadas e modulos (resumo)
  estado-do-projeto.md      ← marcos e sprint atual
  configuracao-supabase.md  ← setup remoto
  execucao-local.md         ← como rodar e testar
  contribuicao.md           ← fluxo de trabalho
  spec/                     ← especificacao Spec-Driven Development
    README.md               ← mapa dos arquivos de spec
    00-visao-geral.md … 10-pendencias-e-perguntas-abertas.md
```

## Sprint atual

**Sprint 9** — decisoes e ajustes pos Sprint 8: hardening local (criptografia,
PIN com hash), sync de assinatura, backup local, tema configuravel com dark mode
e polimento de telas.

Detalhes operacionais da sprint: consultar `docs/sprint9/` localmente (nao
versionado).

## Relacao com `docs/`

| Pasta | Versionada | Uso |
| --- | --- | --- |
| `documentacao/` | Sim | Spec, arquitetura, guias publicos |
| `docs/` | Nao (gitignored) | Sprints, prompts, contratos internos |

Ao implementar uma feature, atualize a spec em `documentacao/spec/` quando o
comportamento mudar; registre pendencias em
`spec/10-pendencias-e-perguntas-abertas.md`.
Sprint 9 (hardening local, sync de assinatura, backup e polimento): consultar
`docs/sprint9/README.md` localmente.

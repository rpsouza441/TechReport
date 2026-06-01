# Especificacao Oficial — TechReport

Esta pasta concentra a documentacao orientada a Spec-Driven Development (SDD)
do TechReport. Cada arquivo descreve o produto e a arquitetura de forma
rastreavel, separada dos materiais auxiliares de sprint em `docs/` (nao
versionados).

## Convencoes

| Marcador | Significado |
| --- | --- |
| **Confirmado** | Evidencia direta no codigo, migrations ou documentacao ja validada |
| **Hipotese** | Inferencia plausivel ainda nao fechada formalmente |
| **Pendencia** | Lacuna conhecida; ver tambem `10-pendencias-e-perguntas-abertas.md` |

## Mapa dos arquivos

| Arquivo | Proposito |
| --- | --- |
| [00-visao-geral.md](./00-visao-geral.md) | Produto, modos de uso, escopo MVP e sprint atual |
| [01-requisitos-funcionais.md](./01-requisitos-funcionais.md) | Capacidades funcionais por area |
| [02-requisitos-nao-funcionais.md](./02-requisitos-nao-funcionais.md) | Seguranca, offline, performance, i18n |
| [03-casos-de-uso.md](./03-casos-de-uso.md) | Atores, casos de uso e criterios de aceite resumidos |
| [04-regras-de-negocio.md](./04-regras-de-negocio.md) | Regras de RAT, sessao, papeis e sync |
| [05-arquitetura.md](./05-arquitetura.md) | Camadas, modulos e dependencias |
| [06-modelo-de-dados.md](./06-modelo-de-dados.md) | Entidades locais e remotas |
| [07-fluxos-principais.md](./07-fluxos-principais.md) | Fluxos end-to-end do app |
| [08-contratos-e-interfaces.md](./08-contratos-e-interfaces.md) | Repositorios, use cases e fronteiras |
| [09-decisoes-tecnicas.md](./09-decisoes-tecnicas.md) | ADRs e decisoes consolidadas |
| [10-pendencias-e-perguntas-abertas.md](./10-pendencias-e-perguntas-abertas.md) | Lacunas, duvidas e proximos passos |
| [11-sprint-testes-automatizados.md](./11-sprint-testes-automatizados.md) | Sprint proposta para cobrir funcionalidades ja implementadas com testes |

## Relacao com outras pastas

```text
documentacao/     -> documentacao oficial versionada (esta pasta + guias)
docs/             -> sprints, prompts, contratos internos (gitignored)
lib/              -> implementacao Flutter
supabase/         -> schema remoto versionado
```

## Sprint de referencia

**Confirmado:** o repositorio esta em fechamento das **Sprints 8.2 e 8.5**.
O codigo ja contem `responsavelDocumento`, convites/equipe e filtros da lista;
o proximo passo recomendado e cobertura de testes + QA antes da Sprint 9.

Detalhes operacionais da sprint ficam em `docs/sprint8.2/` (consulta interna,
nao versionada).

## Ordem de leitura sugerida

1. `00-visao-geral.md`
2. `05-arquitetura.md` ou `07-fluxos-principais.md` (conforme perfil)
3. `06-modelo-de-dados.md`
4. `10-pendencias-e-perguntas-abertas.md` (estado atual e lacunas)
**Sprint 8.5:** guia operacional de equipe/convites em
`docs/sprint8.5/spec-driven.md`.

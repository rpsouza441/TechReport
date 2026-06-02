# 04 — Regras de Negocio

> **Proposito:** regras que governam comportamento do dominio, independentes de
> implementacao UI.
>
> **Fontes:** entidades em `lib/features/*/domain/`, migrations Supabase,
> `docs/contracts/`, sprint 8.2.

## RN-01 — Modos independentes

| Regra | Descricao |
| --- | --- |
| RN-01.1 | Modo local nao exige Supabase configurado |
| RN-01.2 | Troca de modo nao apaga automaticamente dados locais |
| RN-01.3 | RAT local (`ownerType: localTecnico`) e RAT empresa (`companyTecnico`) coexistem no mesmo SQLite com escopo distinto |

**Confirmado.**

## RN-02 — RAT — ciclo de vida

| Regra | Descricao |
| --- | --- |
| RN-02.1 | RAT inicia como rascunho (`draft`) |
| RN-02.2 | Finalizacao exige campos obrigatorios definidos no formulario (cliente, descricao, etc.) |
| RN-02.3 | Assinatura exige RAT finalizada (**Confirmado** em `rat_form_view_model.dart`) |
| RN-02.4 | Exclusao e soft delete (`deletedAt` local; `deletado` remoto) |
| RN-02.5 | Tecnico dono pode editar/excluir proprio RAT; gerente tem leitura ampliada |

**Confirmado** — enums `RatStatus`, policies RLS em `0002_company_rats_base.sql`.

## RN-03 — Responsavel e documento (Sprint 8.2)

| Regra | Descricao |
| --- | --- |
| RN-03.1 | `responsavelRecebimento` identifica quem recebe/assina |
| RN-03.2 | `responsavelDocumento` e opcional; vazio → `null` |
| RN-03.3 | Documento nao e obrigatorio para assinar |
| RN-03.4 | Nao ha validacao de CPF/CNPJ nesta sprint |
| RN-03.5 | Documento nao substitui nome do responsavel |

**Confirmado** — escopo `docs/sprint8.2/README.md`; parcialmente implementado.

## RN-04 — Assinatura

| Regra | Descricao |
| --- | --- |
| RN-04.1 | Assinatura e asset local referenciado por `assetRef` |
| RN-04.2 | Uma assinatura vinculada a uma RAT por vez (modelo atual) |
| RN-04.3 | Sync remoto de assinatura nao faz parte do MVP atual |

**Confirmado** — tabela `Assinaturas`, **Pendente** sync remoto.

## RN-05 — Sincronizacao

| Regra | Descricao |
| --- | --- |
| RN-05.1 | Escrita local e imediata; sync e assincrono via fila |
| RN-05.2 | Cada item de fila pertence a `empresaId` + `usuarioId` |
| RN-05.3 | Falha incrementa tentativas e registra `lastError` |
| RN-05.4 | Retry manual reprocessa item sem exigir reeditar RAT |
| RN-05.5 | Download remoto respeita checkpoint por escopo de visibilidade |

**Confirmado.**

## RN-06 — Papeis e visibilidade

| Papel | Leitura RAT | Escrita RAT | Admin |
| --- | --- | --- | --- |
| `tecnico` | Proprios | Proprios | Nao |
| `gerente` | Empresa | Proprios (nao edita de outro tecnico) | Equipe limitada: gerencia tecnicos |
| `admin_empresa` | Empresa | Conforme policy | Equipe (parcial) |
| `app_admin` | Global conforme RLS | Nao operacional de campo | Global |

**Confirmado** — RLS e `SessaoRemotaPapelEmpresa`.

**Hipotese:** edicao gerencial de RAT de outro tecnico permanece fora do escopo
ate decisao explicita (mencionado como pendencia pos-Sprint 5).

## RN-07 — Sessao remota

| Regra | Descricao |
| --- | --- |
| RN-07.1 | Sessao expira conforme `expiresAt` do token |
| RN-07.2 | Janela offline permitida ate `offlineAccessUntil` |
| RN-07.3 | Tokens puros nunca entram em entidade de dominio |
| RN-07.4 | `app_admin` pode existir sem contexto de empresa (`hasCompanyContext == false`) |

**Confirmado** — `sessao_remota.dart`.

## RN-08 — Seguranca operacional

| Regra | Descricao |
| --- | --- |
| RN-08.1 | App nunca aplica SQL de schema remoto |
| RN-08.2 | Seed com dados reais fica apenas no ambiente da instancia |
| RN-08.3 | Admin inicial criado via Auth + seed SQL pelo operador |

**Confirmado** — `documentacao/configuracao-supabase.md`.

## RN-09 — Numeracao e identificadores

| Regra | Descricao |
| --- | --- |
| RN-09.1 | IDs locais gerados com UUID |
| RN-09.2 | ID remoto de RAT preservado no upload (nao recriado no servidor) |

**Confirmado** — uso de `uuid`, DTO de sync.

**Pendencia:** regra formal de numeracao visivel (`numero` da RAT) nao esta
documentada além do campo texto livre — ver perguntas abertas.

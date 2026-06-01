# Contribuicao

> **Proposito:** orientar desenvolvedores sobre fluxo de trabalho, convencoes e
> onde documentar mudancas.
>
> **Fontes:** estrutura do repo, ESAA em `docs/spec/README.md` (consulta),
> principios arquiteturais em `documentacao/arquitetura.md`.

## Antes de codar

1. Leia [estado-do-projeto.md](./estado-do-projeto.md) para saber a sprint ativa.
2. Consulte a spec em [spec/](./spec/README.md) relacionada a sua mudanca.
3. Para detalhes de sprint, use `docs/` localmente (nao versionado).

## Convencoes de codigo

**Confirmado** no repositorio:

- features em `lib/features/<nome>/` com `presentation`, `domain`, `data`;
- infra compartilhada em `lib/shared/`;
- bootstrap/DI em `lib/app/`;
- UI nao acessa Drift, Supabase ou tokens diretamente;
- textos visiveis ao usuario em portugues do Brasil (com acentuacao correta).

## Alteracoes de schema

### Local (Drift)

1. Altere `lib/shared/infra/database/tech_report_local_database.dart`.
2. Incremente `schemaVersion` e bloco `onUpgrade`.
3. Rode `dart run build_runner build --delete-conflicting-outputs`.
4. Atualize repositorios/DTOs/domain.
5. Atualize [spec/06-modelo-de-dados.md](./spec/06-modelo-de-dados.md).

### Remoto (Supabase)

1. Adicione arquivo numerado em `supabase/migrations/`.
2. **Nunca** aplique SQL pelo app Flutter.
3. Documente em [configuracao-supabase.md](./configuracao-supabase.md) se o
   fluxo operacional mudar.
4. Atualize spec e pendencias.

## Alteracoes de produto

Ao fechar uma feature:

1. Marque requisitos em [spec/01-requisitos-funcionais.md](./spec/01-requisitos-funcionais.md).
2. Remova ou atualize itens em
   [spec/10-pendencias-e-perguntas-abertas.md](./spec/10-pendencias-e-perguntas-abertas.md).
3. Atualize [estado-do-projeto.md](./estado-do-projeto.md).

## O que nao commitar

| Item | Motivo |
| --- | --- |
| Pasta `docs/` | Gitignored — material auxiliar local |
| Credenciais reais | Seguranca |
| `.env` com secrets | Seguranca |
| Arquivos gerados desnecessarios | `build/`, `.dart_tool/` ja ignorados |

## Commits

Siga o estilo do repositorio (mensagens curtas focadas no *porque*).

Exemplo para esta reorganizacao de documentacao:

```text
docs: estruturar spec SDD em documentacao/spec
```

## Pull requests

Inclua:

- resumo do que mudou;
- referencia a sprint/spec;
- test plan (analyze, test, passos manuais);
- confirmacao de que `docs/` nao foi incluido.

## Testes

Minimo antes de PR:

```bash
flutter analyze
flutter test
```

Sprints recentes exigem tambem teste manual documentado (ver sprint ativa em
`docs/`).

## Divida tecnica conhecida

Ver [spec/10-pendencias-e-perguntas-abertas.md](./spec/10-pendencias-e-perguntas-abertas.md).

Nao implemente fora do escopo da sprint ativa sem registrar decisao.

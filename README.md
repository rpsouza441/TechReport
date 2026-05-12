# TechReport

TechReport e a reconstrucao de um aplicativo Flutter para Relatorios de
Atendimento Tecnico `RAT`.

O produto e local-first e possui dois modos:

- `local`: uso individual do tecnico, com persistencia no dispositivo,
  assinatura e compartilhamento local/PDF.
- `empresa`: autenticacao remota, isolamento por empresa, Supabase e
  sincronizacao progressiva.

## Direcao Tecnica

- Flutter como app principal.
- Drift/SQLite para persistencia local.
- Supabase como backend remoto oficial do MVP.
- RLS e policies para isolamento remoto.
- Arquitetura por camadas: presentation, domain, data/infra.
- Nenhuma `SERVICE_ROLE_KEY` no app.
- Migrations Supabase aplicadas fora do Flutter.

Backend proprio fica apenas como possibilidade futura.

## Estrutura Do Repositorio

- `lib/`: codigo-fonte do app Flutter.
- `supabase/migrations/`: schema remoto versionado.
- `supabase/seed.example.sql`: seed seguro com placeholders.
- `documentacao/`: documentacao publica do projeto.
- `docs/`: sprints, decisoes, contratos, prompts e referencias internas.
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`: plataformas do
  projeto Flutter.

## Documentacao

Para entender o projeto de forma limpa, comece por:

- [`documentacao/README.md`](documentacao/README.md)
- [`documentacao/visao-geral.md`](documentacao/visao-geral.md)
- [`documentacao/arquitetura.md`](documentacao/arquitetura.md)
- [`documentacao/estado-do-projeto.md`](documentacao/estado-do-projeto.md)

Para retomar desenvolvimento por sprint:

- [`docs/README.md`](docs/README.md)
- [`docs/sprint6/README.md`](docs/sprint6/README.md)
- [`docs/sprint6/passos.md`](docs/sprint6/passos.md)

## Estado Atual

Sprint 5 foi fechada funcionalmente em 2026-05-12:

- modo local existe;
- modo empresa autentica via Supabase;
- sessao remota nao expoe tokens puros no dominio;
- RLS basica foi validada;
- sync MVP de RAT existe;
- tecnico comum e gerente possuem escopos diferentes.

Proxima frente: Sprint 6 - conformidade do produto base, com RAT completo, PDF,
schema local/remoto e Metric Slate nas telas tocadas.

## Como Rodar

```bash
flutter pub get
flutter run
```

## Observacoes

- O modo local deve continuar funcionando sem backend.
- O app nunca deve aplicar migrations Supabase em runtime.
- O app nunca deve conter credenciais administrativas.
- `docs/prompt.md` e o alvo canonico do produto.
- `docs/prompt2.md` guia a continuidade pos-sprints.


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
- Banco local criptografado via SQLite3MultipleCiphers (`sqlite3mc`).
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
- [`docs/sprint9/README.md`](docs/sprint9/README.md)
- [`docs/sprint9/passos.md`](docs/sprint9/passos.md)

## Estado Atual

**Sprint 9 - decisoes e ajustes pos Sprint 8** (em andamento).

Ja entregue:

- modo local com onboarding, PIN opcional (hash + salt, 4-8 digitos),
  bloqueio/desbloqueio, CRUD de RAT, assinatura e compartilhamento textual/PDF;
- banco local criptografado (`sqlite3mc`) e backup local versionado;
- modo empresa com login Supabase, sessao remota sem tokens puros, RLS,
  sync de RAT e de assinatura (Supabase Storage privado);
- papeis tecnico/gerente/admin_empresa/app_admin com equipe e convites;
- admin global com detalhe da empresa para gerir admins;
- edicao do nome exibido no perfil, deep link `techreport://convite`,
  reenvio de confirmacao de e-mail e exception handler global;
- tema configuravel em 3 variantes (cobalt, volt, burgundy) com light/dark
  respeitando o sistema;
- previa e remodelacao do PDF, polimento das telas principais e filtros/busca.

Proxima frente: Sprint 10 - QA, build Android e release candidate.

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


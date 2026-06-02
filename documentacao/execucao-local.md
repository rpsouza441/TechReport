# Execucao Local

> **Proposito:** preparar ambiente de desenvolvimento e executar o app.
>
> **Fontes:** `README.md` raiz, `pubspec.yaml`, `documentacao/configuracao-supabase.md`.

## Pre-requisitos

**Confirmado:**

- Flutter SDK compativel com Dart `^3.11.4`;
- toolchain da plataforma alvo (Android SDK, Xcode, etc., conforme necessidade);
- para modo empresa: instancia Supabase configurada (ver guia dedicado).

## Instalacao

Na raiz do repositorio:

```bash
flutter pub get
```

Quando alterar tabelas Drift (`tech_report_local_database.dart`):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Executar o app

```bash
flutter run
```

Escolha dispositivo/emulador quando solicitado.

## Modo local (sem backend)

1. Abra o app.
2. Escolha **modo local**.
3. Conclua onboarding (nome, email, PIN).
4. Crie RATs, assine e compartilhe — tudo offline.

Banco local: `tech_report_local.sqlite` (Drift).

## Modo empresa (com Supabase)

1. Prepare instancia conforme [configuracao-supabase.md](./configuracao-supabase.md).
2. Aplique migrations em `supabase/migrations/` em ordem numerica.
3. No app: modo empresa → informe URL e chave publica → login.

**Importante:** para testar sync de `responsavelDocumento` e convites/equipe,
aplique todas as migrations ate `0014` em ordem numerica.

## Verificacao estatica

```bash
flutter analyze
```

Criterio de fechamento das sprints recentes: zero issues.

## Testes automatizados

```bash
flutter test
```

**Confirmado:** existem testes de tema, widgets compartilhados e algumas telas
em `test/`. Cobertura ainda limitada.

## Teste manual minimo (Sprint 8.2)

Referencia completa: `docs/sprint8.2/passos.md` (consulta local).

Resumo:

1. Criar RAT sem documento do responsavel.
2. Criar RAT com documento.
3. Editar e conferir persistencia.
4. PDF e share.
5. Export/import backup local.
6. Sync remoto (modo empresa).
7. Assinatura sem documento preenchido.
8. Conferir acentuacao nas telas tocadas.

## Observacoes

- Nunca commitar credenciais reais (URL/chave de producao, senhas, seeds com
  dados reais).
- `supabase/seed.example.sql` usa placeholders — substituir apenas no ambiente
  local da instancia.
- Pasta `docs/` e ignorada pelo Git; clone limpo pode nao traze-la — copie de
  backup local se necessario para consulta de sprints.

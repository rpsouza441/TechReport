# Arquitetura

TechReport usa organizacao por camadas e funcionalidades (feature-first).

Documentacao detalhada: [spec/05-arquitetura.md](./spec/05-arquitetura.md).

## Camadas

### Presentation

Contem telas, widgets e view models.

Responsabilidades:

- exibir estado para o usuario;
- coletar entradas;
- chamar use cases ou repositorios injetados;
- nao conhecer detalhes de Supabase, Drift, AuthResponse ou tokens puros.

### Domain

Contem entidades, contratos de repositorio e casos de uso.

Responsabilidades:

- representar regras do produto;
- definir fronteiras entre UI, persistencia local e servicos remotos;
- evitar dependencia direta de SDKs externos.

### Data / Infra

Contem implementacoes concretas e servicos de dispositivo.

Responsabilidades:

- persistir dados locais (Drift);
- inicializar clientes remotos (Supabase);
- guardar tokens em storage seguro;
- mapear respostas externas para entidades do dominio via DTOs.

## Modulos (`lib/features/`)

| Modulo | Funcao |
| --- | --- |
| `local_auth` | Sessao local, PIN, home, backup |
| `company_auth` | Modo empresa, login, sessao remota, conta |
| `rat` | Relatorios de atendimento |
| `signature` | Assinatura capturada no dispositivo |
| `sync` | Fila e download remoto |
| `company_admin` | Admin global e equipe |

Compartilhado: `lib/shared/` (banco SQLite, widgets Metric Slate, PIN store).

Bootstrap e navegacao: `lib/app/` (`AppScope`, `TechReportApp`, `CompanyShell`).

## Persistencia

O app usa SQLite local (Drift) para operacao offline e experiencia local-first.

O backend remoto e responsabilidade do operador da instancia Supabase. O app
**nao** aplica migrations remotas em runtime.

Tabelas locais: `tecnico_locals`, `sessao_locals`, `rats`, `assinaturas`,
`sync_queue_items` — ver [spec/06-modelo-de-dados.md](./spec/06-modelo-de-dados.md).

## Sessao remota

A sessao remota do TechReport nao e a mesma coisa que a `Session` do Supabase.

No dominio (`SessaoRemota`), ficam referencias e identificadores:

- empresa, usuario remoto, tecnico;
- endpoint ativo;
- refs para access/refresh token (nao os tokens puros);
- papeis (`app_admin`, `admin_empresa`, `gerente`, `tecnico`);
- validade e janela offline.

Access token e refresh token puros ficam apenas na camada data, em
`FlutterSecureTokenStore`.

## Sync

Escrita local imediata + fila (`sync_queue_items`) + processamento assincrono.

Download incremental usa checkpoint por escopo de visibilidade.

## Seguranca remota

Autorizacao no Postgres via RLS; app usa apenas chave publica + Auth.

Guia operacional: [configuracao-supabase.md](./configuracao-supabase.md).

## Diagrama simplificado

```text
┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│ Presentation │ ──► │   Domain    │ ◄── │  Data/Infra  │
│  (Flutter)   │     │ (entidades) │     │ Drift/Supabase│
└──────────────┘     └─────────────┘     └──────────────┘
                            ▲
                     AppScope (DI)
```

## Contratos

Lista de repositorios e use cases: [spec/08-contratos-e-interfaces.md](./spec/08-contratos-e-interfaces.md).

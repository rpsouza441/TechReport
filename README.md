# TechReport

TechReport e a reconstrucao de um aplicativo de relatorios de atendimento tecnico.

O projeto nasce como uma nova base Flutter, com foco em reduzir o acoplamento do app antigo, melhorar a experiencia visual e preparar a evolucao para um backend mais robusto.

## Objetivo

O produto esta sendo pensado em dois modos:

- local: uso individual do tecnico, com persistencia no dispositivo, assinatura e compartilhamento por email
- empresa: autenticacao remota, sincronizacao e isolamento de dados por empresa

A direcao tecnica atual prioriza:

- Flutter como frontend
- arquitetura mais limpa e desacoplada
- persistencia local first
- backend proprio no modo empresa
- SQL no servidor, preferencialmente Postgres

## Estrutura do repositorio

- `lib/`: codigo-fonte do app Flutter
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`: plataformas suportadas pelo projeto
- `test/`: testes automatizados
- `documentacao/`: documentacao publica do projeto
- `rat/`: projeto legado copiado apenas como referencia funcional e historica

O diretorio `rat/` nao faz parte do novo produto e esta ignorado no Git.

## Documentacao

Para entender o projeto de forma limpa, comece por:

- [`documentacao/README.md`](documentacao/README.md)
- [`documentacao/visao-geral.md`](documentacao/visao-geral.md)
- [`documentacao/arquitetura.md`](documentacao/arquitetura.md)
- [`documentacao/configuracao-supabase.md`](documentacao/configuracao-supabase.md)

## Estado atual

Neste momento, o repositorio contem a base Flutter do novo produto, o fluxo
local-first e a entrada inicial do modo empresa com configuracao de servidor,
login remoto via Supabase e sessao remota separada da sessao local.

As proximas prioridades sao:

1. validar isolamento de dados por RLS
2. manter o modo local funcionando sem backend
3. preparar sincronizacao futura de RATs
4. evoluir permissoes e administracao do modo empresa

## Como rodar

```bash
flutter pub get
flutter run
```

## Observacoes

- O app antigo servira como referencia de fluxo e regras de negocio, nao como base arquitetural.
- A reconstrucao deve reaproveitar o dominio e os casos de uso, mas nao o acoplamento antigo ao Firebase.
- O foco inicial e fazer bem o modo local antes de avancar para sincronizacao e backend.

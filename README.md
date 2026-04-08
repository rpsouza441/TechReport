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
- `rat/`: projeto legado copiado apenas como referencia funcional e historica

O diretorio `rat/` nao faz parte do novo produto e esta ignorado no Git.

## Estado atual

Neste momento, o repositorio contem a base inicial criada com Flutter e sera evoluido aos poucos para o novo produto.

As prioridades iniciais sao:

1. definir o dominio do app
2. estruturar o MVP local
3. reconstruir as telas principais com uma base moderna
4. preparar a futura entrada do modo empresa

## Como rodar

```bash
flutter pub get
flutter run
```

## Observacoes

- O app antigo servira como referencia de fluxo e regras de negocio, nao como base arquitetural.
- A reconstrucao deve reaproveitar o dominio e os casos de uso, mas nao o acoplamento antigo ao Firebase.
- O foco inicial e fazer bem o modo local antes de avancar para sincronizacao e backend.

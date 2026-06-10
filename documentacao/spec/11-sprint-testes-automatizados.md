# 11 — Sprint de Testes Automatizados

> **Proposito:** transformar funcionalidades ja implementadas em comportamento
> protegido por testes antes do release candidate.
>
> **Status:** proposta criada apos validacao dos specs em 2026-06-01.

## Objetivo

Criar cobertura automatizada para fluxos implementados que hoje dependem de QA
manual ou validacao indireta.

## Escopo prioritario

| Area | Testes esperados | Prioridade |
| --- | --- | --- |
| `responsavelDocumento` | formulario, trim vazio -> null, persistencia, edicao, PDF/share, export/import | Alta |
| RAT lista | filtros por texto/status, limpar filtro, escopo de sessao preservado | Alta |
| Sync queue | pending, processing, synced, failed, retry e erro controlado | Alta |
| Convites/equipe | criar, listar, cancelar, aceitar convite e mapear erros de RPC | Alta |
| Auth empresa | sign in, sign up com convite, sign in com convite, troca obrigatoria de senha | Media |
| RLS/manual remoto | roteiro de validacao por tecnico, gerente, admin_empresa e app_admin | Media |
| PDF/share | documento ausente como "Nao informado", assinatura sem distorcao, ausencia de tokens | Media |
| Export/import | compatibilidade com backup antigo e preservacao de `responsavelDocumento` | Media |

## Fora do escopo

- Implementar funcionalidade nova.
- Criar CI/CD completo.
- Testar Supabase real em suite unit/widget local sem ambiente preparado.
- Criptografar banco local.

## Estrategia

1. Priorizar testes unitarios de domain/use cases e parsers.
2. Usar fakes/mocks para repositorios e RPCs Supabase.
3. Manter testes widget apenas para fluxos visuais criticos.
4. Registrar roteiro manual separado para RLS e Supabase real.
5. Rodar `flutter analyze` e `flutter test` ao final.

## Criterio de aceite

- `flutter analyze` passa limpo.
- `flutter test` passa.
- Ha testes cobrindo pelo menos:
  - `responsavelDocumento` ponta a ponta local;
  - filtros da lista RAT;
  - export/import com campo novo;
  - caminho feliz e erro de convite;
  - transicoes basicas da fila de sync.
- Lacunas que exigem Supabase real ficam documentadas em roteiro manual.

## Relacao com Sprint 10

Esta cobertura deve acontecer antes ou junto do congelamento da Sprint 10. Se o
release candidate for iniciado sem esta cobertura, registrar explicitamente o
risco de regressao em sync, convites, PDF/share e export/import.

# Estado Do Projeto

O TechReport esta em desenvolvimento ativo.

**Sprint atual:** fechamento **8.2 / 8.5** + sprint de testes automatizados.

**Ultima atualizacao desta pagina:** 2026-06-01 (validacao spec vs codigo).

## Ja Existe

### Base e modo local

- base Flutter multi-plataforma;
- modo local com onboarding, PIN, bloqueio/desbloqueio;
- CRUD de RAT local;
- captura de assinatura local;
- compartilhamento textual e PDF;
- exportacao/importacao de backup local (JSON).

### Modo empresa

- escolha entre modo local e modo empresa;
- configuracao de servidor remoto (URL + chave publica);
- login remoto com Supabase Auth;
- sessao remota sem tokens puros no dominio;
- schema Supabase: empresas, tecnicos, rats, app_admins e convites (migrations
  0001-0012);
- fila local de sync para RAT;
- upload/download incremental de RATs;
- status de sync na lista;
- isolamento por `empresaId` / `tecnicoId` / RLS;
- papeis: tecnico, gerente, admin_empresa, app_admin;
- retry manual de sync com falha;
- soft delete local/remoto;
- tela de conta/perfil remoto e troca de senha;
- logout com confirmacao quando ha pendencias de sync;
- central de sincronizacao;
- areas admin global e equipe com convites;
- tema Metric Slate e widgets compartilhados (cobertura parcial).

### RAT estendida (pos-Sprint 6)

- campos de visita, horarios, equipamento, responsavel pelo recebimento;
- alinhamento local/remoto para campos da migration 0003.

## Em Andamento — Sprint 8.2

| Entrega | Status |
| --- | --- |
| Campo `responsavelDocumento` no dominio e Drift (v7) | Feito |
| Payload sync / DTO / repos data | Feito |
| Formulario, PDF, share, export/import | Feito |
| Migration Supabase `responsavel_documento` | Feito (`0008`) |
| Revisao acentuacao PT-BR | Parcial |
| Testes automatizados especificos | Pendente |

Detalhes: [spec/10-pendencias-e-perguntas-abertas.md](./spec/10-pendencias-e-perguntas-abertas.md).

## Marcos Fechados

| Marco | Data | Resultado resumido |
| --- | --- | --- |
| Sprint 5 | 2026-05-12 | Sync MVP de RAT, RLS tecnico/gerente validada |

Sprints 6 a 8 entregaram funcionalidades listadas acima; nao ha data formal de
fechamento documentada na spec oficial para cada uma — **pendencia de registro**
(P-10 na spec de pendencias).

## Proximos Marcos (planejamento interno)

```text
Sprint 8.2/8.5     → fechamento por QA/testes
Sprint testes      → cobertura automatizada para fluxos ja implementados
Sprint 9           → QA, build Android, release candidate
Sprint 10          → hardening seguranca local (SQLite criptografado)
```

Fonte do replanejamento: `docs/decisions/plano-pos-sprint5-prompt2.md` (consulta
local).

## Ainda Fora Do Escopo Implementado

- sync remoto de assinatura;
- upload remoto de anexos;
- visualizacao/restauracao de RATs deletados;
- area gerencial dedicada com operacoes avancadas;
- edicao gerencial de RAT de outro tecnico;
- auditoria de ultimo modificador;
- RBAC avancado;
- provisionamento automatico de instancia Supabase;
- criptografia do SQLite/local assets;
- build Android/release candidate.

## Testes Recentes Documentados (Sprint 5)

- Tecnico comum ve apenas proprios RATs;
- tecnicos da mesma empresa nao veem RATs uns dos outros;
- gerente ve RATs da propria empresa;
- upload corrigido com client Supabase autenticado;
- retry de sync failed sem reeditar RAT;
- banco local nomeado `tech_report_local.sqlite`.

**Pendencia:** executar a sprint de testes automatizados descrita em
`documentacao/spec/11-sprint-testes-automatizados.md`.

## Documentacao

- Spec SDD: [spec/README.md](./spec/README.md)
- Execucao: [execucao-local.md](./execucao-local.md)
## Nota Sprint 8.5

O guia operacional atualizado de equipe, convites e provisionamento pelo app
esta em `docs/sprint8.5/spec-driven.md`.

**Status validado:** ha implementacao no codigo e migrations; falta QA/RLS e
testes automatizados para fechamento.

Decisoes fechadas:

- ciclo de vida de usuarios deve ocorrer pelo app, sem Supabase Dashboard no uso
  normal;
- popup de convite deve virar tela;
- convite deve gerar codigo/link copiavel;
- convidado deve criar conta pelo app somente com convite valido;
- usuario em `auth.users` sem linha em `public.tecnicos` nao e membro da
  empresa e nao deve acessar modo empresa;
- convite cancelado antes da confirmacao de e-mail nao cria membro fantasma;
- admin global gerencia empresas/admins globais/admins empresa;
- admin da empresa convida `admin_empresa`, `gerente` e `tecnico`;
- gerente/tecnico nao gerenciam equipe.

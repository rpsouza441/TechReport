# Estado Do Projeto

O TechReport esta em desenvolvimento ativo.

**Sprint atual:** **Sprint 9 - decisoes e ajustes pos Sprint 8**.

**Ultima atualizacao desta pagina:** 2026-06-08 (maioria dos ajustes do Sprint 9 implementados).

## Ja Existe

### Base e modo local

- base Flutter multi-plataforma;
- modo local com onboarding, PIN opcional (hash + salt, 4-8 digitos),
  bloqueio/desbloqueio;
- banco local criptografado via SQLite3MultipleCiphers (`sqlite3mc`);
- CRUD de RAT local;
- captura de assinatura local persistida em BLOB no SQLite;
- compartilhamento textual e PDF, com previa do PDF;
- backup local completo versionado (fluxo principal) e export/import JSON legado;
- tema configuravel em 3 variantes (cobalt, volt, burgundy) com light/dark
  respeitando o sistema.

### Modo empresa

- escolha entre modo local e modo empresa;
- configuracao de servidor remoto (URL + chave publica);
- login remoto com Supabase Auth;
- sessao remota sem tokens puros no dominio;
- schema Supabase: empresas, tecnicos, rats, app_admins, convites e anexos de
  assinatura (migrations 0001-0016);
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
- criacao de conta pelo app com convite valido;
- aceite de convite com conta existente;
- gerente com area Equipe limitada, convite de tecnico e gestao de tecnico;
- admin da empresa com convite e gestao de gerente/tecnico;
- admin global com tela de detalhe da empresa para gerir admins da empresa;
- edicao do nome exibido no perfil (persistida no Supabase, migration 0016);
- sync remoto de assinatura via Supabase Storage privado (migration 0015);
- deep link nativo `techreport://convite`, reenvio de confirmacao de e-mail e
  exception handler global;
- tema Metric Slate e widgets compartilhados (cobertura parcial).

### RAT estendida

- campos de visita, horarios, equipamento, responsavel pelo recebimento;
- documento do responsavel (`responsavelDocumento`);
- alinhamento local/remoto para campos das migrations ate `0008`.

## Fechamento Sprint 8

| Entrega | Status |
| --- | --- |
| Conta remota, perfil e troca de senha | Feito |
| Logout com pendencias de sync | Feito |
| Centro de sincronizacao | Feito |
| Checkpoint por empresa/usuario/papel | Feito |
| Protecao de escopo RAT/PDF | Feito |
| Export/import local JSON | Feito |
| Campo `responsavelDocumento` | Feito |
| Equipe, convites e permissoes Sprint 8.5 | Validado manualmente |
| `flutter analyze` | Feito em 2026-06-04 |
| `flutter test` | Feito em 2026-06-04, 15 testes |
| Validacao manual completa do modo local | Feito em 2026-06-04 |
| Revisao ampla de acentuacao PT-BR | Parcial/backlog |
| Testes automatizados especificos de auth/sync/convites | Pendente |

Detalhes: [spec/10-pendencias-e-perguntas-abertas.md](./spec/10-pendencias-e-perguntas-abertas.md).

## Marcos Fechados

| Marco | Data | Resultado resumido |
| --- | --- | --- |
| Sprint 5 | 2026-05-12 | Sync MVP de RAT, RLS tecnico/gerente validada |
| Sprint 8.5 | 2026-06-04 | Equipe, convites, criacao de conta pelo app e permissoes validadas manualmente |
| Sprint 8 Final | 2026-06-04 | Modo local validado: PIN, bloqueio/desbloqueio e troca de modo |

Sprints 6 a 8 entregaram funcionalidades listadas acima. O Sprint 9 foi aberto
para aplicar decisoes e ajustes encontrados no fechamento, antes da sprint de
QA/build/release candidate.

## Proximos Marcos

```text
Sprint 9           -> decisoes e ajustes pos Sprint 8
Sprint 10          -> QA, build Android, release candidate
Sprint 11          -> hardening residual/reset local, sem migracao de banco legado nesta fase
```

Fonte do replanejamento: `docs/decisions/plano-pos-sprint5-prompt2.md` e
validacao manual de Sprint 8.5.

## Ainda Fora Do Escopo Implementado

- upload remoto de anexos genericos (alem da assinatura);
- visualizacao/restauracao de RATs deletados;
- area gerencial dedicada com filtros avancados;
- edicao gerencial de RAT de outro tecnico;
- auditoria de ultimo modificador;
- RBAC avancado;
- provisionamento automatico de instancia Supabase;
- exibicao/edicao do nome da empresa pelo proprio usuario;
- migracao de banco local antigo para usuarios reais; sem aplicacao nesta fase,
  pois ainda nao ha usuarios reais com dados a preservar;
- reset/recuperacao de PIN esquecido;
- build Android/release candidate.

## Sprint 9 - Decisoes E Ajustes

O Sprint 9 atual concentra melhorias que surgiram durante a validacao do Sprint
8 Final. Fonte operacional: `docs/sprint9/`.

Itens ja implementados no Sprint 9:

- detalhe da empresa para admin global controlar admins da empresa;
- deep link nativo `techreport://convite`;
- exception handler global;
- reenviar confirmacao de e-mail;
- correcao da configuracao Supabase sumindo apos `flutter run`;
- loading/desabilitar botao no logout remoto;
- regra final do PIN local: opcional, minimo 4 e maximo 8 digitos;
- PIN salvo como hash/verificador com salt;
- criptografia do banco local inteiro com Drift + `sqlite3` 3.x +
  SQLite3MultipleCiphers (`sqlite3mc`);
- backup local completo em formato proprio, substituindo export JSON isolado de
  RAT como fluxo principal;
- assinatura local em BLOB no SQLite/Drift, em tabela separada da RAT;
- sync remoto de assinatura via Supabase Storage privado + tabela de metadados
  com RLS/policies (migration 0015);
- edicao do nome exibido no perfil persistida no Supabase (migration 0016);
- tema configuravel em 3 variantes com light/dark respeitando o sistema;
- previa do PDF e remodelacao do PDF;
- polimento das telas principais e filtros/busca na lista de RAT.

Em acompanhamento/backlog do Sprint 9:

- revisao ampla de acentuacao PT-BR;
- testes automatizados de auth/sync/convites.

Decisoes fechadas:

- nao planejar migracao de banco local antigo nesta fase; ao aplicar
  criptografia em desenvolvimento, limpar dados/cache do app;
- iOS nao e alvo atual;
- plano B para criptografia: `encrypted_drift + sqflite_sqlcipher` se
  `sqlite3mc` falhar no Android;
- PDF nao deve ser salvo como arquivo permanente nem entrar no backup;
- assinatura deve entrar no backup local e no sync remoto.

Ficam para Sprint 11/futuro:

- reset/recuperacao de PIN esquecido;
- migracao de banco legado fica fora do plano atual, pois o app ainda nao foi
  lancado; reabrir somente se houver usuarios reais com dados a preservar;
- suporte avancado para limpeza segura de dados locais.

## Testes Recentes Documentados

- Tecnico comum ve apenas proprios RATs;
- tecnicos da mesma empresa nao veem RATs uns dos outros;
- gerente ve RATs da propria empresa;
- upload corrigido com client Supabase autenticado;
- retry de sync failed sem reeditar RAT;
- banco local nomeado `tech_report_local.sqlite`;
- admin global cria/ativa/inativa empresa e convida admin;
- admin da empresa convida admin/gerente/tecnico;
- gerente convida e gerencia tecnico;
- convite com codigo/link/share funciona;
- aceite de convite com conta criada pelo app e conta existente funciona;
- tecnico inativo recebe mensagem amigavel;
- regressao `_dependents.isEmpty` passou.
- modo local com PIN opcional passou;
- criar/trocar PIN em tela propria passou;
- bloquear/desbloquear e trocar modo com PIN configurado passou.

**Pendencia:** executar a sprint de testes automatizados descrita em
`documentacao/spec/11-sprint-testes-automatizados.md`.

## Documentacao

- Spec SDD: [spec/README.md](./spec/README.md)
- Execucao: [execucao-local.md](./execucao-local.md)
- Sprint 8 Final: `docs/sprint8-final/README.md`
- Validacao Sprint 8.5: `docs/sprint8.5/validacao.md`
- Sprint 9: `docs/sprint9/README.md`

## Nota Sprint 8.5

O guia operacional atualizado de equipe, convites e provisionamento pelo app
esta em `docs/sprint8.5/spec-driven.md`.

**Status validado:** implementacao, migrations e validacao manual principal
concluidas em 2026-06-04. Testes automatizados/RLS ampliados seguem como
pendencia de Sprint 9+.

Decisoes fechadas:

- ciclo de vida de usuarios deve ocorrer pelo app, sem Supabase Dashboard no uso
  normal;
- popup de convite deve virar tela;
- convite deve gerar codigo/link copiavel e compartilhavel;
- convidado deve criar conta pelo app somente com convite valido;
- usuario em `auth.users` sem linha em `public.tecnicos` nao e membro da
  empresa e nao deve acessar modo empresa;
- convite cancelado antes da confirmacao de e-mail nao cria membro fantasma;
- admin global gerencia empresas e convida admins empresa;
- admin da empresa convida `admin_empresa`, `gerente` e `tecnico`;
- gerente ve equipe em modo limitado e pode convidar/ativar/inativar/exigir
  troca de senha apenas de `tecnico`;
- tecnico nao gerencia equipe.

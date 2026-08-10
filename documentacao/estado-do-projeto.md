# Estado Do Projeto

O TechReport esta em desenvolvimento ativo e em preparacao de release.

**Sprint atual:** **Fase 20 - preparacao de release**.

**Ultima atualizacao desta pagina:** 2026-08-10.

## Estado Da Release

- gate automatizado concluido: 357 testes aprovados;
- `flutter analyze` sem erros, com 29 avisos/informacoes nao bloqueantes;
- APK release gerado com 71.243.359 bytes;
- SHA-256: `4BC5D2670BB004A5F1EF08A3773A7B81A6069A51E7F46D4FDA0CB0CDAD9F14B1`;
- bibliotecas SQLite3MultipleCiphers confirmadas nas tres arquiteturas do APK;
- QA manual em aparelho fisico ainda pendente;
- release candidate ainda nao aprovada.

O roteiro versionado de validacao esta em
[`spec/12-qa-android-fisico.md`](./spec/12-qa-android-fisico.md). A versao somente
sera classificada como release candidate depois da execucao e aprovacao desse
roteiro sem bloqueadores criticos.

## Ja Existe

### Base e modo local

- base Flutter multi-plataforma;
- modo local com onboarding de perfil sem PIN, biometria ou tela de desbloqueio;
- banco local criptografado via SQLite3MultipleCiphers (`sqlite3mc`);
- CRUD de RAT local;
- captura de assinatura local persistida em BLOB no SQLite;
- compartilhamento textual e PDF, com previa do PDF;
- backup local completo versionado (fluxo principal) e export/import JSON legado;
- tema configuravel em 3 variantes (cobalt, volt, burgundy) com light/dark
  respeitando o sistema.

- area de administracao local para perfil, RATs, lixeira, tema, backup e
  informacoes seguras dos dados;
- lixeira local com restauracao e backup distinguindo RATs ativas/excluidas.

### Modo empresa

- escolha entre modo local e modo empresa;
- configuracao de servidor remoto (URL + chave publica);
- login remoto com Supabase Auth;
- sessao remota sem tokens puros no dominio;
- schema Supabase: empresas, tecnicos, rats, app_admins, convites, anexos de
  assinatura e auditoria (migrations 0001-0016 e 0018-0027; 0017 e uma lacuna
  historica intencional);
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
- deep link nativo `techreport://convite`, interface de reenvio de confirmacao
  com fallback amigavel e exception handler global;
- tema Metric Slate e widgets compartilhados (cobertura parcial).
- matriz final de RAT: tecnico opera somente as proprias; gerente e
  admin_empresa operam RATs da mesma empresa; app_admin nao acessa RAT;
- lixeira pessoal/empresarial com restauracao estreita;
- auditoria server-side por campo, com tela de historico e escopo por papel;
- invariante impedindo dupla identidade ativa app_admin/empresa.

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
| Testes automatizados especificos de auth/sync/convites | Feito |

Detalhes: [spec/10-pendencias-e-perguntas-abertas.md](./spec/10-pendencias-e-perguntas-abertas.md).

## Marcos Fechados

| Marco | Data | Resultado resumido |
| --- | --- | --- |
| Sprint 5 | 2026-05-12 | Sync MVP de RAT, RLS tecnico/gerente validada |
| Sprint 8.5 | 2026-06-04 | Equipe, convites, criacao de conta pelo app e permissoes validadas manualmente |
| Sprint 8 Final | 2026-06-04 | Modo local validado: PIN, bloqueio/desbloqueio e troca de modo |
| Fase 20.2 | 2026-08-10 | Permissoes, auditoria, lixeira, restore e modo local sem PIN validados |

Sprints 6 a 8 entregaram funcionalidades listadas acima. O Sprint 9 foi aberto
para aplicar decisoes e ajustes encontrados no fechamento, antes da sprint de
QA/build/release candidate.

## Proximos Marcos

```text
Fase 20.2          -> concluida e validada automaticamente
UAT empresa nova   -> admin_empresa, gerente, tecnico, RAT, auditoria e lixeira
QA Android         -> aparelho fisico e decisao de release candidate
```

Fonte do replanejamento: `docs/decisions/plano-pos-sprint5-prompt2.md` e
validacao manual de Sprint 8.5.

## Ainda Fora Do Escopo Implementado

- upload remoto de anexos genericos (alem da assinatura);
- area gerencial dedicada com filtros avancados;
- RBAC avancado;
- provisionamento automatico de instancia Supabase;
- exibicao/edicao do nome da empresa pelo proprio usuario;
- migracao de banco local antigo para usuarios reais; sem aplicacao nesta fase,
  pois ainda nao ha usuarios reais com dados a preservar;
- aprovacao da release candidate apos QA manual em aparelho fisico.

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
- regra historica do PIN local e armazenamento com hash/salt, posteriormente
  substituidos pelo fluxo sem PIN da fase 20.2;
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

Ficam para fase futura:

- migracao de banco legado fica fora do plano atual, pois o app ainda nao foi
  lancado; reabrir somente se houver usuarios reais com dados a preservar;
- suporte avancado para limpeza segura de dados locais.

## Testes Recentes Documentados

- Tecnico comum ve apenas proprios RATs;
- tecnicos da mesma empresa nao veem RATs uns dos outros;
- gerente ve RATs da propria empresa;
- upload corrigido com client Supabase autenticado;
- retry de sync failed sem reeditar RAT;
- banco local nomeado `tech_report_local.db`;
- admin global cria/ativa/inativa empresa e convida admin;
- admin da empresa convida admin/gerente/tecnico;
- gerente convida e gerencia tecnico;
- convite com codigo/link/share funciona;
- aceite de convite com conta criada pelo app e conta existente funciona;
- tecnico inativo recebe mensagem amigavel;
- regressao `_dependents.isEmpty` passou.
- bootstrap local sem PIN/bloqueio passou;
- banco criptografado falha de forma segura quando a chave esta ausente ou
  incorreta;
- permissoes, auditoria, lixeira e restauracao passaram em testes Flutter e
  pgTAP no Supabase self-hosted.

**Estado:** a suite automatizada descrita em
`documentacao/spec/11-sprint-testes-automatizados.md` foi ampliada e passou com
357 testes. Permanecem o UAT de empresa nova e o QA em aparelho fisico.

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

## Decisoes De Produto - 2026-08-09

- todo membro da empresa pode criar RAT propria;
- tecnico visualiza somente RATs proprias;
- gerente/admin_empresa visualizam e corrigem RATs da mesma empresa, mantendo
  criador e dono;
- toda alteracao remota deve gerar auditoria server-side por campo;
- tecnico ve auditoria das proprias RATs; gerente/admin_empresa veem auditoria
  da empresa;
- tecnico aplica soft delete, consulta lixeira e restaura somente RAT propria;
  gerente/admin_empresa podem excluir, consultar e restaurar na empresa;
- restauracao preserva proprietario, status, assinatura e demais dados e gera
  auditoria server-side;
- app_admin nao acessa RAT e nao pode acumular perfil ativo de empresa;
- modo offline deixa de exigir PIN/biometria, mas mantem SQLite criptografado;
- migrations aplicadas nao serao reescritas depois do reset de desenvolvimento.

Detalhes: [spec/13-permissoes-auditoria-e-modo-offline.md](./spec/13-permissoes-auditoria-e-modo-offline.md).

# Estado Do Projeto

O TechReport esta em desenvolvimento ativo.

## Ja Existe

- base Flutter;
- modo local em evolucao;
- fluxo local-first;
- estrutura inicial de RAT;
- captura de assinatura;
- compartilhamento local/PDF;
- escolha entre modo local e modo empresa;
- configuracao de servidor remoto;
- login remoto com Supabase;
- sessao remota sem tokens puros no dominio;
- schema Supabase inicial para empresas e tecnicos;
- base inicial de modo empresa;
- tabela remota `public.rats`;
- fila local de sync para RAT;
- upload de RAT company para Supabase;
- download incremental de RATs remotos;
- status simples de sync na lista;
- isolamento local da lista por `empresaId` e `tecnicoId`;
- suporte a papel `gerente` na sessao remota;
- gerente consegue visualizar RATs da propria empresa;
- tecnico comum nao ve RATs de outro tecnico;
- tecnico de outra empresa nao ve RATs fora da propria empresa;
- retry manual de itens de sync com falha;
- soft delete local/remoto de RAT pelo tecnico dono.

## Ultimo Marco Fechado

Sprint 5 foi fechada funcionalmente em 2026-05-12.

Resultado:

- sync MVP de RAT existe;
- permissoes basicas foram validadas;
- RLS de `public.rats` foi testada para tecnico comum e gerente;
- gerente tem leitura ampliada da propria empresa;
- tecnico comum segue limitado aos proprios RATs.

## Sprint Atual Recomendada

Sprint 6 - Conformidade Do Produto Base.

Fonte:

```text
docs/sprint6/README.md
docs/sprint6/passos.md
docs/decisions/plano-pos-sprint5-prompt2.md
```

Objetivo:

- fechar RAT completo;
- alinhar schema local/remoto;
- atualizar PDF;
- atualizar payload de sync;
- aplicar Metric Slate nas telas tocadas;
- preparar a base para admin, UX final e release candidate.

## Ainda Fora Do Escopo Implementado

- RAT completo com todos os campos do `docs/prompt.md`;
- PDF final com layout minimo de produto;
- `app_admin`;
- `admin_empresa`;
- troca de senha obrigatoria para admin inicial;
- administracao completa de usuarios da empresa;
- tela de conta/sessao;
- confirmacao de logout com pendencias;
- centro de sincronizacao completo;
- sync remoto de assinatura;
- upload remoto de anexos;
- tela gerencial dedicada com filtros e operacoes avancadas;
- edicao gerencial de RAT sem trocar dono original;
- auditoria de ultimo usuario/tecnico que modificou a RAT;
- pesquisa/filtros avancados da lista de RATs;
- visualizacao e restauracao de RATs deletados;
- RBAC avancado;
- provisionamento automatico de instancia Supabase;
- criptografia do SQLite/local assets;
- build Android/release candidate.

## Testes Recentes

- Tecnico A, Tecnico C e Tecnico B foram testados com empresas/usuarios
  diferentes.
- Tecnico comum ve apenas os proprios RATs.
- Tecnicos da mesma empresa nao veem RATs uns dos outros.
- Gerente da Empresa A ve RATs da Empresa A e nao ve RATs da Empresa B.
- Upload inicialmente falhava por client Supabase sem sessao Auth; corrigido
  usando client autenticado para sync.
- RATs com sync `failed` agora podem ser reenviados pelo botao sincronizar sem
  precisar editar e salvar novamente.
- Nome do banco local foi ajustado para `tech_report_local.sqlite`.

## Proximos Marcos

```text
Sprint 6 -> RAT completo, PDF, schema e base Metric Slate
Sprint 7 -> app_admin, admin_empresa e administracao minima
Sprint 8 -> conta, logout com pendencias, sync center e UX Metric Slate
Sprint 9 -> QA, build Android e release candidate
```


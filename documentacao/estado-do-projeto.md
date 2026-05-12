# Estado Do Projeto

O TechReport esta em desenvolvimento ativo.

## Ja Existe

- base Flutter;
- modo local em evolucao;
- fluxo local-first;
- estrutura inicial de RAT;
- captura de assinatura;
- compartilhamento local;
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

## Em Andamento

- fechamento da Sprint 5;
- validacao manual final de `public.rats`;
- registro dos testes em `docs/sprint5/notas-validacao-rls-rats.md`;
- validacao de delete fisico bloqueado por RLS;
- validacao de soft delete remoto pelo dono;
- revisao do comportamento de gerente como leitura ampliada, sem edicao de RAT
  alheio no MVP.

## Ainda Fora Do Escopo Atual

- resolucao de conflitos;
- upload remoto de anexos;
- sync remoto de assinatura;
- administracao completa de usuarios da empresa;
- tela gerencial dedicada com filtros e operacoes avancadas;
- edicao gerencial de RAT sem trocar dono original;
- auditoria de ultimo usuario/tecnico que modificou a RAT;
- pesquisa/filtros avancados da lista de RATs;
- visualizacao e restauracao de RATs deletados;
- RBAC avancado;
- provisionamento automatico de instancia Supabase;
- criptografia do SQLite/local assets.

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

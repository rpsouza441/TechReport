# Spec QA Android fisico

> Fonte: rodada manual de QA em Android fisico concluida em 2026-06-10.
> Objetivo: transformar os relatos em requisitos rastreaveis antes de corrigir
> codigo.

## Estado

Status: especificacao inicial.

Antes de implementar, cada item deve ter:

- comportamento esperado confirmado;
- impacto em seguranca/permissoes revisado;
- criterio de aceite manual;
- quando aplicavel, teste automatizado previsto.

## QA-01 — Fundo com hierarquia visual sutil

**Problema:** telas com fundo flat demais perdem hierarquia entre header e
conteudo.

**Comportamento esperado:** o background deve manter base limpa e flat, mas com
split sutil: topo levemente mais concentrado, conteudo mais aberto e transicao
suave no meio da tela. A separacao entre header e conteudo deve parecer organica,
com degrade discreto e leve curva/onda, sem linha rigida ou bloco duro.

**Criterios de aceite:**

- nao usar divisao dura entre duas cores;
- manter tons da mesma paleta ativa;
- efeito perceptivel, mas discreto;
- nao reduzir legibilidade nem contrastes.

## QA-02 — Meu perfil local quebra ao abrir

**Problema:** ao acessar Meu perfil no modo local, ocorre tela vermelha:
`type 'LocalProfileScreen' is not a subtype of type '_LocalProfileScreenState'`.

**Comportamento esperado:** Meu perfil local abre sem erro, permite ver dados e
acionar edicao pelo AppBar.

**Criterios de aceite:**

- abrir Meu perfil local em Android fisico sem excecao;
- botao editar aparece quando perfil nao esta carregando/editando;
- salvar/cancelar continuam funcionando.

## QA-03 — PDF: area visual da assinatura sugere espaco errado

**Problema:** a borda da area de assinatura no PDF e larga demais e pode sugerir
que havia mais espaco para coletar assinatura, apesar da assinatura ficar
alinhada corretamente a esquerda.

**Comportamento esperado:** manter assinatura alinhada a esquerda, mas ajustar a
representacao visual para nao parecer uma area de captura maior do que a real.

**Criterios de aceite:**

- assinatura continua visivel e alinhada;
- borda/linha nao induz falso espaco de assinatura;
- layout do PDF permanece limpo.

## QA-04 — Meu perfil sempre a direita

**Problema:** em algumas telas, principalmente admin, Meu perfil aparece antes
de outras areas.

**Comportamento esperado:** em todas as navegacoes por abas, RATs fica no maximo
a esquerda quando existir, e Meu perfil fica sempre no maximo a direita.

**Criterios de aceite:**

- tecnico empresa: RATs a esquerda, Meu perfil a direita;
- gerente/admin empresa: RATs a esquerda, areas admin no meio, Meu perfil a
  direita;
- app admin: areas administrativas antes de Meu perfil.

## QA-05 — Atualizacao de nome da empresa no admin

**Problema:** atualizar nome da empresa funciona de forma inconsistente. Dentro
da pagina da empresa, pull-to-refresh nao atualiza o nome; na pagina principal,
o nome so atualiza ao puxar, sem feedback claro ou botao explicito.

**Comportamento esperado:** telas admin devem ter acao explicita de atualizar,
pull-to-refresh quando houver lista/scroll, e feedback de carregamento.

**Criterios de aceite:**

- pagina principal e detalhe da empresa refletem nome atualizado no Supabase;
- existe botao/icone de atualizar quando a atualizacao nao e obvia;
- durante atualizacao, aparece barra fina animada no topo;
- se houver botao atualizar, o icone gira ou fica em estado ocupado para evitar
  cliques repetidos;
- quando houver alteracao pendente de sincronizacao, a UI informa esse estado.

## QA-06 — Admin empresa pode atualizar o proprio nome da empresa

**Problema:** admin da empresa nao tem opcao para atualizar o nome da propria
empresa.

**Comportamento esperado:** admin empresa deve poder atualizar/sincronizar o
nome da empresa dele, respeitando permissoes.

**Pergunta de seguranca:** gerente tambem pode alterar nome da empresa, ou
somente admin empresa?

## QA-07 — Padrao global de loading

**Problema:** carregamentos usam padroes diferentes.

**Comportamento esperado:** sempre que houver carregamento de tela ou acao
importante, usar barra fina animada no topo. Quando a acao partir de um botao,
o botao tambem deve indicar ocupado quando fizer sentido.

**Criterios de aceite:**

- refresh/sync usa barra fina no topo;
- botoes de atualizar/sair/salvar que disparam async evitam duplo clique;
- padrao e consistente entre perfis.

## QA-08 — Tela RAT precisa de pull-to-refresh

**Problema:** tela RAT tem botao atualizar em alguns fluxos, mas nao tem gesto
de puxar para baixo.

**Comportamento esperado:** lista de RATs deve aceitar pull-to-refresh e manter
botao explicito quando aplicavel.

**Criterios de aceite:**

- puxar para baixo atualiza lista local/remota conforme perfil;
- botao atualizar continua disponivel onde ja existir;
- feedback de loading segue QA-07.

## QA-09 — Avisos bloqueiam interacao e nao podem ser dispensados

**Problema:** popups/avisos, especialmente ao editar RAT, salvar assinatura ou
clicar em previa, impedem clicar em botoes ate sumirem.

**Comportamento esperado:** avisos transientes devem poder ser dispensados ou
nao bloquear a acao seguinte.

**Criterios de aceite:**

- mensagens tem botao/icone de fechar ou sao facilmente dispensaveis;
- aviso nao cobre fluxo principal de salvar/prever PDF de forma prejudicial;
- comportamento e consistente.

## QA-10 — Convite por link no WhatsApp

**Problema:** `techreport://convite?codigo=36BF385B` nao virou link clicavel no
WhatsApp.

**Hipotese:** WhatsApp pode nao autolinkar esquemas customizados. Link HTTPS com
Android App Links tende a ser necessario para comportamento confiavel.

**Comportamento esperado:** convite deve ser enviado em formato clicavel e abrir
o app quando instalado; quando nao instalado, deve permitir orientacao ou
fallback.

**Perguntas:**

- qual dominio HTTPS sera usado para app links?
- o fallback web deve apenas instruir instalacao ou tambem permitir aceitar
  convite?
- o mesmo padrao deve existir para cadastro/configuracao Supabase?

## QA-11 — Acoes de usuarios sem menu de tres pontos

**Problema:** na tela admin empresa, acoes como ativar/desativar e trocar senha
ficam escondidas nos tres pontos, enquanto outra tela mostra botoes diretos no
card.

**Comportamento esperado:** acoes principais devem aparecer diretamente no card
da pessoa: ativar/desativar e trocar senha.

**Criterios de aceite:**

- card mostra estado ativo/inativo;
- acao primaria alterna ativo/inativo;
- trocar senha fica visivel;
- menu de tres pontos nao e necessario para acoes principais.

## QA-12 — PDF da lista nao mostra assinatura

**Problema:** ao gerar PDF pelo botao PDF na lista de RATs, assinatura nao
aparece. Pela previa dentro da edicao da RAT, aparece.

**Comportamento esperado:** PDF gerado pela lista e PDF gerado pela tela de
edicao devem usar a mesma fonte de dados e exibir assinatura quando existir.

**Criterios de aceite:**

- RAT assinada mostra assinatura no PDF da lista;
- RAT assinada mostra assinatura na previa da edicao;
- nao gera tela vermelha em RAT sem assinatura.

## QA-13 — Indicador de assinatura na lista de RATs

**Problema:** a lista so mostra icone de assinatura quando existe assinatura; nao
ha indicacao clara quando falta.

**Comportamento esperado:** card da RAT deve indicar estado da assinatura.

**Criterios de aceite:**

- assinado: icone de assinatura presente/positivo;
- nao assinado: icone de assinatura ausente/cortada;
- ao tocar no indicador de assinatura ausente, abrir fluxo de assinatura quando
  permitido;
- ao concluir assinatura, voltar para edicao da RAT sem tela vermelha.

## QA-14 — Escopo de RATs por perfil

**Problema:** admin empresa sincroniza/visualiza somente as proprias RATs, mas
deveria ver todas da empresa.

**Comportamento esperado:**

- tecnico ve e sincroniza apenas as proprias RATs/assinaturas;
- admin empresa ve e sincroniza todas as RATs da empresa;
- gerente tem a mesma visao de RATs da empresa que admin empresa.

**Criterios de aceite:**

- admin empresa baixa RAT criada por tecnico da mesma empresa;
- gerente baixa RAT criada por tecnico da mesma empresa;
- tecnico nao baixa RAT de outro tecnico;
- RLS/Supabase confirma a regra, nao apenas a UI.

## QA-15 — Edicao gerencial de RAT

**Problema:** hoje somente o dono pode editar RAT.

**Comportamento esperado:** admin empresa e gerente podem alterar RATs da empresa.
O banco deve registrar quem foi o ultimo usuario que alterou.

**Criterios de aceite:**

- tecnico edita apenas RAT propria;
- admin empresa e gerente editam RATs da empresa;
- registro local/remoto guarda ultimo alterador;
- tela de edicao pode mostrar `Ultima alteracao por: email`;
- essa informacao nao aparece no PDF.

**Impacto em modelo:** requer campo(s) para ultimo alterador local/remoto e
migracao.

## QA-16 — Previa/PDF para nao dono

**Problema:** usuario que nao e dono da RAT nao consegue clicar em previa/PDF
dentro da edicao, embora previa nao devesse salvar alteracoes.

**Comportamento esperado:** quem pode visualizar a RAT pode gerar previa/PDF,
mesmo sem permissao de edicao. Gerar previa nao deve salvar automaticamente.

**Criterios de aceite:**

- gerente/admin conseguem abrir previa de RAT de outro tecnico;
- tecnico nao visualiza RAT de outro tecnico;
- previa nao altera nem enfileira sync quando em modo somente leitura.

## QA-17 — Central de sincronizacao com textos amigaveis

**Problema:** mensagens como `RAT · upsert`, `ASSINATURA · upsert` e
`Tentativas: 0` sao tecnicas e pouco amigaveis.

**Comportamento esperado:** central deve explicar em linguagem de usuario o que
foi enviado, o que esta pendente e o que falhou.

**Exemplos desejados:**

- `Relatorio tecnico enviado`;
- `Assinatura enviada`;
- `Relatorio aguardando envio`;
- `Assinatura com erro de envio`.

**Criterios de aceite:**

- nao expor nomes de operacao tecnica como `upsert`;
- status pendente, erro e enviado sao claros;
- horario aparece como apoio, nao como unica explicacao.

## QA-18 — Status de sync da RAT inconsistente

**Problema:** card da RAT mostra `Pendente`, mas central de sincronizacao mostra
`Pendentes: 0`. Fica dificil entender o que foi enviado e o que nao foi.

**Comportamento esperado:** chip da lista e central devem representar a mesma
verdade de sincronizacao.

**Criterios de aceite:**

- se fila esta zerada e upload remoto concluiu, RAT nao permanece pendente;
- quando houver falha, card e central mostram falha de modo consistente;
- lista mostra ultimo envio/tentativa/erro quando necessario.

## QA-19 — Padronizacao de telas por modulos

**Problema:** perfis diferentes exibem comportamentos parecidos de forma
inconsistente, por exemplo aviso ao sair.

**Comportamento esperado:** fluxos compartilhados devem ser componentes/modulos
reutilizaveis, com permissoes controlando acoes disponiveis.

**Restricao de seguranca:** reutilizar UI nao pode relaxar autorizacao. Regras
criticas devem permanecer no dominio/backend/RLS, nao apenas na tela.

**Criterios de aceite:**

- logout/saida segue padrao consistente entre perfis;
- acoes comuns usam componentes compartilhados;
- permissoes continuam testadas por papel.

## QA-20 — Revisar botao de sair por perfil

**Problema:** tecnico e gerente mostram confirmacao ao sair, mas e necessario
revisar todos os perfis.

**Comportamento esperado:** todo perfil com saida de sessao deve confirmar antes
de sair; se houver pendencia de sync, deve oferecer sincronizar antes, sair mesmo
assim ou cancelar.

**Criterios de aceite:**

- tecnico empresa confirma saida;
- gerente confirma saida;
- admin empresa confirma saida;
- app admin confirma saida;
- comportamento com pendencias segue regra de sync.

## QA-21 — Nome do tecnico nao persiste

**Problema:** tecnico atualiza o proprio nome, mas ao sair e voltar o nome antigo
retorna.

**Comportamento esperado:** atualizacao de nome do tecnico deve persistir no
Supabase e na sessao/local cache, com feedback de pendente/sincronizando quando
necessario.

**Criterios de aceite:**

- alterar nome, sair e entrar novamente mantem nome novo;
- tela mostra loading/sucesso/erro;
- falha remota nao parece sucesso.

## Priorizacao sugerida

P0:

- QA-02 Meu perfil local quebra;
- QA-12 PDF da lista sem assinatura;
- QA-14 escopo de RATs por perfil;
- QA-18 status pendente inconsistente;
- QA-21 nome do tecnico nao persiste.

P1:

- QA-04 Meu perfil a direita;
- QA-05/QA-06 nome da empresa e feedback;
- QA-08 pull-to-refresh em RAT;
- QA-09 avisos dispensaveis;
- QA-15/QA-16 edicao e previa por admin/gerente.

P2:

- QA-01 background;
- QA-03 PDF assinatura visual;
- QA-07 loading global;
- QA-10 app links;
- QA-11 acoes sem tres pontos;
- QA-13 indicador de assinatura;
- QA-17 textos da central;
- QA-19/QA-20 padronizacao/logout.

## Perguntas abertas para fechar antes da implementacao

1. Gerente pode alterar o nome da empresa ou apenas admin empresa?
2. Admin/gerente podem substituir assinatura de RAT de outro tecnico, ou apenas
   editar campos textuais?
3. Na edicao gerencial, quais campos devem ficar bloqueados por seguranca ou
   auditoria?
4. Qual dominio HTTPS sera usado para Android App Links?
5. O link de cadastro/configuracao Supabase deve abrir uma tela web, o app, ou
   ambos?

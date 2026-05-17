# Nota Pos-Sprint - Loading Infinito No Bootstrap

## Contexto

Depois de concluir a Sprint 6, o app ficou preso na tela inicial de loading:

```text
Scaffold
-> CircularProgressIndicator
-> nunca avanca para escolha de modo, login ou home
```

Isso acontecia porque `AppBootstrapViewModel.bootstrap()` podia lançar erro ou
ficar aguardando uma operacao sem atualizar `status`. Como a UI mostrava
`AppBootstrapStatus.loading`, o erro real ficava invisivel.

## Sintoma

Tela observada:

```text
fundo claro
spinner Metric Slate
sem mensagem de erro
sem botao de acao
```

Fluxo mental:

```text
bootstrap inicia
-> status = loading
-> alguma etapa falha/trava
-> status nao muda
-> usuario ve loading infinito
```

## Causa Real Encontrada

Ao adicionar tela de erro no bootstrap, o erro apareceu:

```text
AuthApiException(
  message: Invalid Refresh Token: Already Used,
  statusCode: 400,
  code: refresh_token_already_used
)
```

Significado:

```text
app tinha refresh token remoto salvo
-> Supabase ja considerava esse token usado/invalido
-> restoreSession tentou usar esse token
-> Supabase retornou erro 400
-> excecao subiu ate o bootstrap
-> antes: loading infinito
```

## Solucao 1 - Bootstrap Com Paraquedas

Arquivos:

```text
lib/app/navigation/app_bootstrap_view_model.dart
lib/app/navigation/tech_report_app.dart
```

Foi criado um novo status:

```dart
failed
```

O bootstrap passou a:

```text
limpar erro anterior
-> executar bootstrap local com timeout
-> executar bootstrap remoto/company com timeout
-> se der certo, navegar normalmente
-> se der erro/timeout, status = failed
```

Na UI, `AppBootstrapStatus.failed` mostra:

```text
Falha ao iniciar
[mensagem real do erro]
Tentar novamente
Voltar para escolha de modo
```

Objetivo:

```text
nunca esconder erro de bootstrap atras de spinner infinito
```

## Solucao 2 - Refresh Token Invalido Vira Login

Arquivo:

```text
lib/features/company_auth/data/repositories/supabase_auth_repository.dart
```

Antes:

```text
restoreSession
-> client.auth.setSession(refreshToken)
-> AuthApiException sobe
-> bootstrap quebra
```

Depois:

```text
restoreSession
-> tenta client.auth.setSession(refreshToken)
-> se Supabase devolver AuthApiException
-> apaga sessao remota local
-> apaga tokens locais
-> retorna null
-> bootstrap envia usuario para login remoto
```

O mesmo tratamento foi aplicado em `refreshSession()`.

Fluxo esperado:

```text
token valido
-> restaura sessao
-> entra no modo empresa

token invalido/usado/expirado
-> limpa credenciais remotas locais
-> vai para login
```

## Solucao 3 - Migration Drift Mais Tolerante

Arquivo:

```text
lib/shared/infra/database/tech_report_local_database.dart
```

Suspeita inicial:

```text
tentativa anterior de migration
-> banco parcialmente atualizado
-> alguma coluna ja existe
-> proxima execucao tenta addColumn de novo
-> erro local
-> bootstrap nao avanca
```

Para evitar isso, a migration passou a verificar se a coluna existe antes de
adicionar:

```text
PRAGMA table_info(rats)
-> procura nome da coluna
-> se ja existe, pula
-> se nao existe, addColumn
```

Tambem foi ajustado o recorte:

```text
from >= 2 && from < 5
from >= 2 && from < 6
```

Motivo:

```text
se rats acabou de ser criada no upgrade from < 2,
ela ja nasce com schema atual.
Nao deve receber addColumn duplicado.
```

## Comportamento Esperado Agora

```text
app inicia normal
-> nao mostra tela de erro

refresh token remoto invalido
-> limpa tokens
-> abre login remoto

erro inesperado no bootstrap
-> mostra tela Falha ao iniciar
-> usuario pode tentar novamente
-> usuario pode voltar para escolha de modo
```

## Importante

A tela de erro ainda existe de proposito. Ela nao e parte do fluxo feliz; ela e
um mecanismo de diagnostico e recuperacao.

Ela so deve aparecer quando:

```text
bootstrap local falha
bootstrap remoto falha
alguma etapa demora mais que o timeout
```

Se ela aparecer, a mensagem exibida deve ser usada para corrigir a causa real,
em vez de limpar cache automaticamente.

## Verificacao Feita

```text
flutter analyze sem issues
app saiu do loading infinito
erro real ficou visivel
login remoto apareceu apos limpar token invalido
RAT abriu depois de novo login
```

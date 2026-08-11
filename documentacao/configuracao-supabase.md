# Configuracao Supabase

Este guia descreve a preparacao minima de uma instancia Supabase para o modo
empresa do TechReport.

## Responsabilidades

### Operador Da Instancia

O operador ou administrador da instancia Supabase deve:

- criar ou manter a instancia Supabase;
- configurar Auth;
- aplicar migrations SQL do TechReport;
- habilitar RLS;
- configurar policies;
- criar dados iniciais de empresa e tecnico;
- fornecer ao app apenas URL publica e chave publica.

### App TechReport

O app deve:

- receber a URL publica do Supabase;
- receber a chave publica do projeto;
- autenticar usuario com email e senha;
- salvar tokens em storage seguro;
- consultar apenas tabelas permitidas por RLS;
- nunca aplicar migrations.

## Credenciais

O app pode receber:

```text
supabaseUrl
supabasePublicKey
```

O app nunca deve receber:

```text
SERVICE_ROLE_KEY
senha do Postgres
string de conexao direta ao banco
credenciais administrativas
```

## Quem Envia O E-mail De Confirmacao

O aplicativo nao possui servidor SMTP e nao envia o e-mail diretamente. No
cadastro por convite, o fluxo e:

```text
TechReport valida o convite
-> TechReport chama Supabase Auth signUp
-> Supabase Auth cria auth.users
-> Supabase Auth envia a confirmacao pelo SMTP da instancia
-> usuario confirma o e-mail
-> usuario volta ao app e entra por "Ja tenho conta"
-> TechReport aceita o convite e vincula o usuario a empresa
```

Portanto:

- o remetente, o servidor SMTP e o link de confirmacao pertencem a configuracao
  do Supabase Auth;
- uma resposta `DNS type MX ... NXDOMAIN` significa que o dominio do
  destinatario nao existe; ela vem do servidor de e-mail, nao do app;
- testes de entrega devem usar um endereco real. Contas ficticias como
  `usuario@empresa-inexistente.test` nao recebem mensagens;
- o app nunca recebe `SMTP_PASS` nem qualquer credencial de envio.

## URLs Do Auth Em Supabase Self-hosted

As URLs usadas no e-mail sao configuradas no ambiente do stack Docker, e nao no
Flutter. No Compose oficial, as variaveis de origem normalmente sao mapeadas
assim:

| Variavel do stack | Variavel efetiva no Auth | Finalidade |
| --- | --- | --- |
| `SUPABASE_PUBLIC_URL` | usada por outros servicos | URL publica do gateway Supabase/Kong |
| `API_EXTERNAL_URL` | `API_EXTERNAL_URL` | base publica usada nos links e callbacks do Auth |
| `SITE_URL` | `GOTRUE_SITE_URL` | destino padrao depois da confirmacao |
| `ADDITIONAL_REDIRECT_URLS` | `GOTRUE_URI_ALLOW_LIST` | destinos adicionais aceitos em `redirect_to` |

Nenhuma dessas URLs pode usar `localhost` quando o e-mail sera aberto em outro
computador ou celular: nesse dispositivo, `localhost` aponta para ele proprio.

### Ambiente de desenvolvimento atual

Para o stack atual do TechReport, exposto pelo Kong em
`192.168.22.245:18000`, use no ambiente do stack:

```dotenv
SUPABASE_PUBLIC_URL=http://192.168.22.245:18000
API_EXTERNAL_URL=http://192.168.22.245:18000
SITE_URL=http://192.168.22.245:18000
ADDITIONAL_REDIRECT_URLS=
```

Neste stack, `MAILER_URLPATHS_CONFIRMATION` ja vale
`/auth/v1/verify`; por isso `API_EXTERNAL_URL` permanece somente com a base. A
configuracao oficial do Supabase mudou em julho de 2026 e stacks novos podem
esperar `API_EXTERNAL_URL` terminado em `/auth/v1`. Nao acrescente esse trecho
isoladamente: atualize `docker-compose.yml` e o arquivo de ambiente da mesma
versao para evitar caminho duplicado ou issuer divergente.

O `SITE_URL` acima apenas fornece um destino acessivel depois que o Auth ja
confirmou a conta. O TechReport atual nao consome automaticamente o parametro
PKCE `?code=...` dessa pagina; o usuario deve voltar ao app e escolher
`Ja tenho conta`. Em producao, prefira uma pagina HTTPS propria de confirmacao.

Referencias oficiais:

- [Supabase self-hosted com Docker](https://supabase.com/docs/guides/self-hosting/docker)
- [Configuracao do Auth self-hosted](https://supabase.com/docs/guides/self-hosting/auth/config)
- [Mudanca de `API_EXTERNAL_URL` em 2026](https://supabase.com/changelog/47093-self-hosted-supabase-api-external-url-to-include-auth-v1)

### Onde alterar

Altere as variaveis no mesmo local que criou o stack:

- se existe `.env` ao lado do `docker-compose.yml`, edite esse arquivo;
- se o stack foi criado por um portal web, edite o ambiente do stack no portal
  e faca o redeploy/recreate do servico Auth;
- nao execute `docker compose up` pelo terminal com um ambiente parcial, pois
  isso pode substituir outras configuracoes e secrets do stack.

Depois do redeploy, confirme os valores efetivos no terminal do servidor, sem
exibir senhas:

```bash
sudo docker inspect supabase-auth \
  --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep -E '^(GOTRUE_SITE_URL|GOTRUE_URI_ALLOW_LIST|API_EXTERNAL_URL|GOTRUE_EXTERNAL_EMAIL_ENABLED|GOTRUE_MAILER_AUTOCONFIRM)='
```

Para exigir confirmacao por e-mail, o esperado e:

```text
GOTRUE_EXTERNAL_EMAIL_ENABLED=true
GOTRUE_MAILER_AUTOCONFIRM=false
```

Crie entao um novo convite usando um e-mail real e confira:

1. o link de verificacao aponta para o host publico, nunca para `localhost`;
2. abrir o link confirma o usuario em `Authentication > Users`;
3. o redirecionamento final usa `SITE_URL`;
4. ao voltar ao TechReport e usar `Ja tenho conta`, o convite e aceito.

## Fluxo Recomendado

1. Criar ou subir a instancia Supabase.
2. Configurar as URLs publicas, Auth email/senha e SMTP.
3. Aplicar as migrations do TechReport em `supabase/migrations/`.
4. Habilitar RLS e policies.
5. Fazer o bootstrap unico do admin global.
6. Configurar o app com URL publica e chave publica.
7. O admin global cria a empresa e o convite pelo app.
8. O convidado cria a conta pelo app e confirma o e-mail.
9. O convidado volta ao app, entra e aceita o convite.

## Aplicando Migrations

As migrations ficam em:

```text
supabase/migrations/
```

Para uma instancia nova, aplique os arquivos SQL em ordem crescente.

### Pelo Supabase SQL Editor

1. Abra o Supabase Studio.
2. Acesse SQL Editor.
3. Abra a primeira migration do repositorio.
4. Copie o conteudo completo.
5. Execute no SQL Editor.
6. Repita para as proximas migrations, mantendo a ordem.

### Pela Supabase CLI

Use a CLI quando a instancia for administrada com fluxo versionado.

Fluxo conceitual:

```text
supabase link
supabase db push
```

Antes de aplicar em producao, revise as migrations e valide em ambiente de
teste.

## Modelo Atual De Autenticacao

O caminho recomendado e:

```text
Supabase Auth autentica email/senha
-> app recebe user.id
-> app consulta public.tecnicos
-> public.tecnicos informa empresa_id e tecnico_id
-> app monta a sessao remota do TechReport
```

Com isso, `auth.users` cuida da autenticacao, enquanto as tabelas de negocio do
TechReport dizem a qual empresa e tecnico aquele usuario pertence.

## Criando Usuario Auth Por Convite

Usuarios comuns, gerentes e admins de empresa nao devem depender do painel do
Supabase. O admin autorizado cria o convite no TechReport e o convidado usa
`Entrar com convite > Criar conta`. O proprio `signUp` do app cria o registro em
`auth.users`; depois da confirmacao e do primeiro login, o app consome o convite
e cria ou ativa o vinculo em `public.tecnicos`.

Criar manualmente em `Authentication > Users` fica restrito a recuperacao
administrativa ou ao bootstrap do primeiro admin global. Nao e o fluxo normal
de onboarding de uma empresa.

## Vinculando Empresa E Tecnico

O fluxo por convite faz o vinculo automaticamente. Para bootstrap, diagnostico
ou desenvolvimento controlado, existe o arquivo:

```text
supabase/seed.example.sql
```

Antes de executar, troque:

```text
<EMAIL_DO_USUARIO>
<NOME_DA_EMPRESA>
<NOME_DO_TECNICO>
```

por valores reais da instancia.

Esse seed cria ou atualiza a empresa e vincula o usuario Auth existente a um
tecnico da empresa.

Depois de executar, use a query de checagem comentada no proprio arquivo para
confirmar que existem `auth_user_id`, `empresa_id` e `tecnico_id`.

## Admin Inicial

A Sprint 7 adiciona o papel `app_admin`, que administra o TechReport pelo
proprio app Flutter. Esse papel nao usa `SERVICE_ROLE_KEY` no app.

Para criar o primeiro admin da instancia:

1. Abra o Supabase Studio.
2. Acesse Authentication > Users.
3. Crie o usuario admin inicial com email e senha provisoria.
4. Confirme que o email aparece em `auth.users`.
5. Abra `supabase/seed.example.sql`.
6. No bloco `Admin inicial TechReport`, troque:

```text
<EMAIL_ADMIN_INICIAL>
<NOME_ADMIN_INICIAL>
```

por valores reais da instancia.

7. Execute apenas o bloco do admin inicial no SQL Editor.
8. Confirme que uma linha foi criada ou atualizada em `public.app_admins`.
9. Entre pelo app com esse email e senha.
10. Troque a senha se `must_change_password = true`.

Fluxo esperado:

```text
Supabase Auth autentica email/senha
-> public.app_admins confirma user_id ativo
-> app habilita area admin global
-> RLS continua autorizando cada acao
```

Nunca coloque no app Flutter:

```text
SERVICE_ROLE_KEY
senha real versionada
credenciais administrativas do banco
```

O seed do admin inicial deve ficar com placeholders no repositorio. Emails,
senhas e dados reais pertencem somente ao ambiente da instancia.

## Observacao Sobre Migrations

As migrations SQL devem ser versionadas no repositorio e aplicadas fora do app,
por Supabase CLI, SQL Editor ou pipeline de deploy.

O Flutter nao deve executar SQL de schema em producao.

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

## Fluxo Recomendado

1. Criar ou subir a instancia Supabase.
2. Configurar Auth com email/senha.
3. Aplicar as migrations do TechReport em `supabase/migrations/`.
4. Habilitar RLS e policies.
5. Criar usuario em Authentication.
6. Criar empresa inicial.
7. Vincular o usuario Auth a um tecnico da empresa.
8. Configurar o app com URL publica e chave publica.
9. Fazer login pelo app.

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

## Criando Usuario Auth

Crie o usuario remoto pelo painel do Supabase:

1. Abra Authentication.
2. Acesse Users.
3. Crie um usuario com email e senha.
4. Confirme que o email do usuario aparece em `auth.users`.

O usuario criado no Auth ainda nao pertence a nenhuma empresa do TechReport. O
vinculo acontece na tabela `public.tecnicos`.

## Vinculando Empresa E Tecnico

Para desenvolvimento, use o arquivo:

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

## Observacao Sobre Migrations

As migrations SQL devem ser versionadas no repositorio e aplicadas fora do app,
por Supabase CLI, SQL Editor ou pipeline de deploy.

O Flutter nao deve executar SQL de schema em producao.

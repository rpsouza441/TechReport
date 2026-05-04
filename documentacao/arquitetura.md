# Arquitetura

TechReport usa uma organizacao por camadas e funcionalidades.

## Camadas

### Presentation

Contem telas, widgets e view models.

Responsabilidades:

- exibir estado para o usuario;
- coletar entradas;
- chamar use cases;
- nao conhecer detalhes de Supabase, Drift, AuthResponse ou tokens puros.

### Domain

Contem entidades, contratos de repositorio e casos de uso.

Responsabilidades:

- representar regras do produto;
- definir fronteiras entre UI, persistencia local e servicos remotos;
- evitar dependencia direta de SDKs externos.

### Data/Infra

Contem implementacoes concretas.

Responsabilidades:

- persistir dados locais;
- inicializar clientes remotos;
- chamar Supabase quando necessario;
- guardar tokens em storage seguro;
- mapear respostas externas para entidades do dominio.

## Persistencia

O app usa persistencia local para manter o funcionamento offline e proteger a
experiencia local-first.

O backend remoto, quando configurado, e responsabilidade da empresa ou operador
da instancia. O app nao aplica migrations e nao cria schema remoto em tempo de
execucao.

## Sessao Remota

A sessao remota do TechReport nao e a mesma coisa que a `Session` do Supabase.

No dominio, ela guarda apenas referencias e identificadores necessarios, como:

- empresa;
- usuario remoto;
- tecnico;
- endpoint ativo;
- referencias para access token e refresh token;
- datas de validade e restauracao.

Access token e refresh token puros devem ficar apenas na camada data/infra, em
storage seguro.

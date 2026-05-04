# Visao Geral

TechReport e um aplicativo Flutter para criar relatorios de atendimento
tecnico.

O projeto foi reconstruido com foco em:

- uso local-first;
- registro de RATs no dispositivo;
- captura de assinatura;
- compartilhamento de relatorios;
- preparacao para modo empresa com autenticacao remota e sincronizacao futura.

## Modos De Uso

### Modo Local

O modo local permite usar o app sem servidor, sem Supabase e sem internet.

Neste modo, os dados ficam no dispositivo e o usuario pode criar, editar,
assinar e compartilhar relatorios localmente.

### Modo Empresa

O modo empresa adiciona uma instancia remota, inicialmente usando Supabase.

Neste modo, a empresa configura um servidor, o usuario entra com email e senha
remotos e o app prepara uma sessao para recursos corporativos futuros, como
sincronizacao, usuarios da empresa e permissoes.

Na etapa atual, o modo empresa cobre a base de configuracao e autenticacao. A
sincronizacao completa de RATs fica para uma etapa posterior.

## Principios

- O modo local deve continuar funcionando sem backend.
- O app nao deve conter credenciais administrativas.
- Tokens puros nao devem aparecer em telas, logs ou entidades de dominio.
- O schema remoto deve ser preparado fora do app.
- O app Flutter usa apenas configuracao publica do servidor e APIs permitidas
  pelas policies do backend.

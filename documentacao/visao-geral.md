# Visao Geral

TechReport e um aplicativo Flutter para criar Relatorios de Atendimento Tecnico
`RAT`.

O projeto esta sendo reconstruido com foco em:

- uso local-first;
- registro de RATs no dispositivo;
- captura de assinatura;
- compartilhamento de relatorios;
- modo empresa com Supabase;
- isolamento por empresa;
- sincronizacao progressiva.

## Modos De Uso

### Modo Local

O modo local permite usar o app sem servidor, sem Supabase e sem internet.

Neste modo, os dados ficam no dispositivo e o usuario pode criar, editar,
assinar e compartilhar relatorios localmente.

### Modo Empresa

O modo empresa usa Supabase como backend remoto do MVP.

Neste modo, a empresa configura uma instancia Supabase, o usuario entra com
email e senha remotos e o app sincroniza RATs de forma local-first conforme a
sessao e as permissoes remotas.

Na etapa atual, o modo empresa ja cobre configuracao, login remoto, sessao
remota, sync basico de RAT e isolamento por RLS para tecnico comum e gerente.

## Principios

- O modo local deve continuar funcionando sem backend.
- O app nao deve conter credenciais administrativas.
- Tokens puros nao devem aparecer em telas, logs ou entidades de dominio.
- O schema remoto deve ser preparado fora do app.
- O app Flutter usa apenas configuracao publica do servidor e APIs permitidas
  pelas policies do backend.
- Supabase e o backend remoto oficial do MVP.
- Backend proprio fica apenas como possibilidade futura.


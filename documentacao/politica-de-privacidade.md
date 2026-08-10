# Política de Privacidade - TechReport

**Versão preliminar para revisão antes da publicação.**

**Última atualização técnica:** 2026-08-10.

## Visão geral

O TechReport registra relatórios de assistência técnica (RATs), incluindo dados do atendimento, identificação informada do cliente e assinatura coletada no dispositivo.

## Modos de operação

No modo local, os dados permanecem no aparelho e são armazenados em banco criptografado. O usuário controla exportações, backups e compartilhamentos.

No modo empresa, a organização configura sua própria instância Supabase. RATs, usuários e assinaturas podem ser sincronizados com essa instância conforme as permissões da empresa. O projeto TechReport não fornece um servidor Supabase compartilhado por padrão.

## Dados tratados

- informações da RAT e do atendimento;
- nomes informados de cliente, responsáveis e técnicos;
- assinatura coletada;
- identificadores técnicos necessários para autenticação e sincronização;
- configuração pública do servidor informada pelo usuário.

## Finalidades

Os dados são usados para criar, armazenar, assinar, gerar PDF, compartilhar e, quando configurado, sincronizar RATs entre membros autorizados da empresa.

## Armazenamento e segurança

O banco local usa criptografia e a chave é mantida no armazenamento seguro da plataforma. Tokens de sessão também usam armazenamento seguro. Arquivos exportados ou compartilhados saem da proteção interna do aplicativo e passam a ser responsabilidade do usuário e do destino escolhido.

## Compartilhamento

O TechReport não vende dados pessoais. O compartilhamento ocorre por ação do usuário, geração de PDF ou sincronização com a instância Supabase configurada pela organização.

## Retenção e exclusão

No modo local, o usuário controla os dados do aparelho. Limpar os dados ou desinstalar o aplicativo pode tornar o banco inacessível. No modo empresa, retenção e exclusão também dependem das regras da instância Supabase da organização.

## Direitos e contato

Solicitações relacionadas a dados sincronizados devem ser direcionadas à organização responsável pela instância Supabase. Antes da publicação, este documento deve receber o canal oficial de contato do responsável pelo aplicativo.

## Alterações

Esta política pode ser atualizada quando recursos, integrações ou requisitos legais mudarem. A data e a versão publicadas devem acompanhar cada atualização.

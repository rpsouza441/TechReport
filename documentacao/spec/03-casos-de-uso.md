# 03 — Casos de Uso

> **Proposito:** descrever interacoes usuario-sistema em nivel de caso de uso,
> com criterios de aceite verificaveis.
>
> **Fontes:** fluxos em `lib/app/navigation/`, telas em `lib/features/`,
> materiais `docs/flows/` (consulta interna).

## Atores

| Ator | Descricao |
| --- | --- |
| **Tecnico local** | Usuario do modo local, sem conta remota |
| **Tecnico empresa** | Usuario autenticado vinculado a `public.tecnicos` |
| **Gerente** | Tecnico com papel `gerente`; leitura ampliada de RATs da empresa e equipe limitada |
| **Admin empresa** | Papel `admin_empresa`; administracao da equipe e convites |
| **App admin** | Administrador global em `public.app_admins` |
| **Operador Supabase** | Aplica migrations e seed fora do app (nao e ator da UI) |

## UC-01 — Configurar uso local

**Ator:** Tecnico local  
**Pre-condicao:** App instalado; modo local escolhido  
**Fluxo principal:**

1. Usuario conclui onboarding (nome, email, PIN).
2. Sistema desbloqueia home local.
3. Usuario cria RATs, assina e compartilha.

**Pos-condicao:** Dados persistidos em SQLite (`tech_report_local.sqlite`).

**Status:** Implementado.

## UC-02 — Bloquear e desbloquear sessao local

**Ator:** Tecnico local  
**Fluxo:** usuario bloqueia app → informa PIN → retoma home local.

**Status:** Implementado (`LocalUnlockScreen`).

## UC-03 — Exportar e importar backup local

**Ator:** Tecnico local  
**Fluxo:** export JSON via share → import via file picker → preview → aplicar.

**Status:** Implementado.

**Confirmado Sprint 8.2:** backup inclui `responsavelDocumento`.

## UC-04 — Entrar no modo empresa

**Ator:** Tecnico empresa  
**Fluxo principal:**

1. Escolhe modo empresa.
2. Informa URL e chave publica Supabase.
3. Autentica com email/senha.
4. Sistema monta `SessaoRemota` a partir de Auth + `public.tecnicos`.
5. Abre shell empresa com lista de RATs.

**Status:** Implementado.

**Regra:** se `must_change_password`, usuario deve trocar senha antes de
continuar (confirmado em `CompanyHomeScreen`).

## UC-05 — Criar e sincronizar RAT empresa

**Ator:** Tecnico empresa  
**Fluxo principal:**

1. Usuario cria/edita RAT (persistencia local imediata).
2. Sistema enfileira operacao em `sync_queue_items`.
3. Processamento envia payload para `public.rats`.
4. Lista exibe status de sync.

**Fluxos alternativos:**

- falha de rede → item fica `failed`; usuario pode retry manual;
- gerente baixa RATs de outros tecnicos da mesma empresa via download
  incremental.

**Status:** Implementado.

## UC-06 — Assinar RAT

**Ator:** Tecnico (local ou empresa)  
**Fluxo:** abrir captura de assinatura → salvar asset local → vincular a RAT.

**Status:** Implementado (local). Sync remoto de assinatura: **Pendente**.

## UC-07 — Compartilhar RAT (texto e PDF)

**Ator:** Tecnico  
**Fluxo:** gerar PDF ou texto → share via SO.

**Restricao Sprint 8:** PDF/share deve respeitar escopo da sessao (nao expor RAT
fora do permitido).

**Status:** Implementado com escopo em modo empresa (**Confirmado** em view
models de lista).

## UC-08 — Gerenciar conta remota

**Ator:** Usuario autenticado  
**Fluxo:** visualizar perfil, empresa, papel → trocar senha.

**Status:** Implementado (`CompanyHomeScreen`).

## UC-09 — Sair com pendencias de sync

**Ator:** Tecnico empresa  
**Fluxo:**

1. Usuario solicita logout.
2. Se fila tem pendencias, dialogo oferece: sincronizar antes, sair mesmo assim,
   cancelar.
3. Sistema encerra sessao remota sem apagar SQLite local.

**Status:** Implementado (`CompanyShell._signOut`).

## UC-10 — Observar central de sincronizacao

**Ator:** Tecnico empresa  
**Fluxo:** abrir sync center → ver itens pendentes/falhos → retry ou refresh.

**Status:** Implementado (`SyncCenterScreen`).

## UC-11 — Administrar instancia (app admin)

**Ator:** App admin  
**Fluxo:** login como admin global → area Admin → listar empresas/tecnicos.

**Status:** Implementado em nivel operacional inicial; precisa de QA/RLS e
testes automatizados.

## UC-12 — Informar documento do responsavel (Sprint 8.2)

**Ator:** Tecnico  
**Fluxo confirmado:**

1. No formulario RAT, campo opcional "Documento do responsavel".
2. Valor vazio persiste como `null`.
3. Valor informado aparece em PDF, share, backup e sync remoto.

**Status:** Implementado no codigo; precisa de cobertura automatizada
especifica e QA manual.

**Criterio de aceite (Sprint 8.2):**

- nao bloqueia criacao, edicao, assinatura ou sync;
- nao substitui `responsavelRecebimento`;
- ausencia exibe "Nao informado" em relatorios.

## UC-13 — Aceitar convite e criar conta empresa

**Ator:** Convidado de empresa

**Pre-condicao:** existe convite pendente para o e-mail informado.

**Fluxo principal com conta nova:**

1. Convidado abre `Aceitar convite`.
2. Seleciona `Criar conta`.
3. Informa e-mail, senha, confirmacao de senha e codigo.
4. Sistema valida convite pendente para o e-mail.
5. Sistema cria conta no Supabase Auth.
6. Se o Auth exigir confirmacao, sistema salva somente e-mail+codigo em storage
   seguro e mostra tela `Conta criada`.
7. Depois da confirmacao, usuario faz login normal.
8. Sistema aceita automaticamente o convite pendente salvo.
9. Sistema cria linha em `public.tecnicos` e abre modo empresa.

**Fluxo alternativo com conta existente:**

1. Convidado abre `Aceitar convite`.
2. Seleciona `Ja tenho conta`.
3. Informa e-mail, senha e codigo.
4. Sistema autentica e chama `accept_tecnico_convite`.
5. Sistema cria/retorna vinculo em `public.tecnicos`.

**Excecao validada:** se o convite foi excluido/cancelado antes de concluir o
aceite, a conta pode existir em `auth.users`, mas nao entra na equipe. Login
normal deve mostrar conta autenticada sem vinculo TechReport e limpar sessao
local.

**Status:** Implementado em nivel operacional inicial; precisa de cobertura
automatizada e QA/RLS.

# 01 — Requisitos Funcionais

> **Proposito:** listar capacidades que o produto deve oferecer, com status de
> implementacao quando verificavel no repositorio.
>
> **Fontes:** codigo em `lib/features/`, migrations `supabase/migrations/`,
> `docs/prompt.md`, sprints internas 5–8.

Legenda de status: **Implementado** | **Parcial** | **Pendente**

## RF-01 — Escolha e persistencia de modo

| ID | Requisito | Status |
| --- | --- | --- |
| RF-01.1 | Usuario escolhe entre modo local e modo empresa | Implementado |
| RF-01.2 | Modo escolhido persiste entre sessoes | Implementado |
| RF-01.3 | Usuario pode voltar a escolha de modo | Implementado |

**Confirmado:** `select_app_mode`, `AppModeChoiceScreen`, bootstrap em
`tech_report_app.dart`.

## RF-02 — Modo local

| ID | Requisito | Status |
| --- | --- | --- |
| RF-02.1 | Onboarding inicial do tecnico local | Implementado |
| RF-02.2 | Remover PIN, biometria e bloqueio do modo local | Implementado |
| RF-02.3 | CRUD de RAT local | Implementado |
| RF-02.4 | Assinatura em RAT local | Implementado |
| RF-02.5 | Compartilhamento textual e PDF da RAT | Implementado |
| RF-02.6 | Exportacao e importacao de backup local (JSON) | Implementado |
| RF-02.7 | Troca para modo empresa sem apagar dados locais | Implementado |
| RF-02.8 | Area local para perfil, RATs, lixeira, tema, backup e dados | Implementado |

**Confirmado:** modulos `local_auth`, `rat`, `signature`.

## RF-03 — Modo empresa — autenticacao e sessao

| ID | Requisito | Status |
| --- | --- | --- |
| RF-03.1 | Configurar URL e chave publica Supabase | Implementado |
| RF-03.2 | Login remoto email/senha | Implementado |
| RF-03.3 | Sessao remota com empresa, tecnico e papeis | Implementado |
| RF-03.4 | Restauracao de sessao e tokens em storage seguro | Implementado |
| RF-03.5 | Tela de conta / perfil remoto | Implementado |
| RF-03.6 | Troca de senha do usuario autenticado | Implementado |
| RF-03.7 | Troca de senha obrigatoria quando `must_change_password` | Implementado |
| RF-03.8 | Bloquear Auth autenticado sem vinculo TechReport | Implementado |

**Confirmado:** `company_auth`, entidade `SessaoRemota`, `CompanyHomeScreen`.
Login Supabase sem linha em `public.tecnicos` nem perfil `app_admin` nao abre
modo empresa; o app limpa sessao/tokens locais e mostra mensagem de conta nao
vinculada.

## RF-04 — RAT

| ID | Requisito | Status |
| --- | --- | --- |
| RF-04.1 | Criar, editar, listar e excluir (soft delete) RAT | Implementado |
| RF-04.2 | Campos estendidos: visita, horarios, equipamento, responsavel | Implementado |
| RF-04.3 | Status: rascunho, finalizado, enviado, arquivado | Implementado |
| RF-04.4 | Campo opcional documento do responsavel (`responsavelDocumento`) | Implementado |
| RF-04.5 | Assinatura vinculada a RAT | Implementado |
| RF-04.6 | PDF e share com dados da RAT | Implementado |
| RF-04.7 | Pesquisa/filtros por texto e status na lista | Implementado |
| RF-04.8 | Auditoria imutavel por campo em alteracoes remotas | Implementado |
| RF-04.9 | Lixeira pessoal do tecnico e lixeira da empresa para gerente/admin, com restauracao | Implementado |

**RF-04.4 — detalhe Sprint 8.2:**

- **Implementado:** dominio, Drift, DTO, sync enqueue, leitura remota,
  formulario, PDF, share textual, export/import e migration SQL remota
  `0008_responsavel_documento.sql`.

## RF-05 — Sincronizacao (modo empresa)

| ID | Requisito | Status |
| --- | --- | --- |
| RF-05.1 | Fila local de sync para RAT | Implementado |
| RF-05.2 | Upload de RAT para Supabase | Implementado |
| RF-05.3 | Download incremental de RATs remotos | Implementado |
| RF-05.4 | Status de sync na lista (localOnly, pending, synced, error) | Implementado |
| RF-05.5 | Retry manual de itens com falha | Implementado |
| RF-05.6 | Central de sincronizacao observavel | Implementado |
| RF-05.7 | Logout com aviso quando ha pendencias | Implementado |
| RF-05.8 | Sync remoto de assinatura | Implementado |

**Confirmado:** `sync/`, `SyncCenterScreen`, dialogo em `company_shell.dart`.

## RF-06 — Papeis e administracao

| ID | Requisito | Status |
| --- | --- | --- |
| RF-06.1 | Papeis empresa: `tecnico`, `gerente`, `admin_empresa` | Implementado |
| RF-06.2 | Papel global `app_admin` | Implementado |
| RF-06.3 | Tecnico ve apenas proprios RATs | Implementado |
| RF-06.4 | Gerente ve RATs da propria empresa | Implementado |
| RF-06.5 | Area admin global (`app_admin`) | Implementado |
| RF-06.6 | Area equipe (`admin_empresa`) — listagens e convites | Implementado |
| RF-06.7 | Fluxo de convite/cadastro de tecnico por app | Implementado |
| RF-06.8 | Gerente gerencia tecnicos em equipe limitada | Implementado |
| RF-06.9 | Todo membro da empresa pode criar RAT propria | Implementado |
| RF-06.10 | Tecnico visualiza somente RATs proprias | Implementado |
| RF-06.11 | Gerente/admin_empresa visualizam e corrigem RATs da mesma empresa sem trocar o dono | Implementado |
| RF-06.12 | Tecnico ve auditoria propria; gerente/admin ve auditoria da empresa | Implementado |
| RF-06.13 | Tecnico exclui/restaura RAT propria; gerente/admin excluem/restauram na empresa | Implementado |
| RF-06.14 | app_admin nao acessa RAT e nao acumula perfil de empresa | Implementado |

**Confirmado:** migration `0006_admin_roles_base.sql`, telas em
`company_admin/`.

**Confirmado:** Sprint 8.5 possui migrations `0009` a `0014`, RPCs, telas e
use cases para equipe/convites. Foi validado que conta criada em `auth.users`
sem convite pendente nao vira membro automaticamente. A matriz final foi
validada pelas migrations `0025`-`0027`, por 67 testes pgTAP no Supabase
self-hosted e pela suite Flutter.

As regras de papeis consolidadas em 2026-08-09 estao detalhadas em
[13-permissoes-auditoria-e-modo-offline.md](./13-permissoes-auditoria-e-modo-offline.md).

## RF-07 — Interface e idioma

| ID | Requisito | Status |
| --- | --- | --- |
| RF-07.1 | UI em portugues do Brasil | Parcial |
| RF-07.2 | Tema Metric Slate nas telas principais | Parcial |
| RF-07.3 | Componentes compartilhados de estado (vazio, erro, loading) | Parcial |

**Confirmado:** Sprint 8.2 inclui revisao de acentuacao; algumas telas ja
corrigidas (ex.: `SyncCenterScreen`), outras ainda com texto sem acento.

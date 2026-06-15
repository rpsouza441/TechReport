# Requirements — Milestone v9.6

**Sync Queue Bug Fixes**

---

## REQ-01: RAT fica pendente apos falha offline

**Problem:** Quando o usuario salva uma RAT sem rede, ela fica "pendente" na fila de sincronizacao. Apos restart do app ou recovery de rede, a RAT continua pendente e nao e processada automaticamente.

**Acceptance criteria:**
- [x] Apos restart do app, itens pendentes sao processados automaticamente
- [x] RAT que falhou offline e syncada quando rede retorna
- [x] Status da RAT e atualizado corretamente apos sucesso

**Source:** Bug discovered during offline testing

**Fixes applied:**
- `company_shell.dart`: Added `addPostFrameCallback((_) => _syncNow())` no initState
- `drift_sync_queue_repository.dart`: tryMarkProcessing agora aceita status failed
- `drift_sync_queue_repository.dart`: enqueue nao sobrescreve status failed

---

## REQ-02: Botao retry nao funciona

**Problem:** O botao "tentar novamente" na tela de fila de sincronizacao nao dispara a operacao de sync. O usuario clica e nada acontece.

**Acceptance criteria:**
- [x] Clicar em "tentar novamente" inicia o processo de sync
- [x] Loading indicator aparece durante a tentativa
- [x] Status e atualizado apos sucesso ou falha

**Source:** Bug discovered during offline testing

**Fixes applied:**
- `drift_sync_queue_repository.dart`: listPending com includeFailed=true agora ignora nextAttemptAt
- `drift_sync_queue_repository.dart`: tryMarkProcessing aceita status failed
- `sync_center_view_model.dart`: Added onSyncComplete callback para recarregar lista RATs

---

## REQ-03: Fila nao identifica operacao

**Problem:** A fila de sincronizacao mostra apenas "RAT tentativas" ou "assinatura" sem identificar qual RAT ou assinatura especifico esta sendo trabalhado.

**Acceptance criteria:**
- [x] Fila mostra identificacao do RAT (numero ou cliente)
- [x] Fila mostra data/hora da tentativa
- [x] Fila mostra tipo de operacao (criar, atualizar, excluir)

**Source:** Bug discovered during offline testing

**Fixes applied:**
- `sync_center_view_model.dart`: Added getRatInfo() que extrai numero/cliente do payload JSON
- `sync_center_screen.dart`: Updated _itemTitle para mostrar "RAT #numero - Cliente"

---

## Dependencies

- REQ-01 depende de investigar o codigo de sync coordinator ✅
- REQ-02 depende de identificar onde o retry estava quebrado ✅
- REQ-03 e melhoria de UX implementada junto com REQ-01/02 ✅

---

## Out of Scope

- Mudancas na estrutura do banco de dados
- Novas funcionalidades de sync
- Modificacoes em outras partes do app

---

## Verification Status

**Testado:**
- ✅ RAT salva offline fica pendente
- ✅ Ao abrir app com rede, sync automático ocorre
- ✅ "Tentar novamente" processa itens falhados
- ✅ Fila mostra ID da RAT (ex: "RAT #0001 - Cliente")
- ✅ Lista RATs atualiza após retry (via onSyncComplete callback)

**Aguardando teste final:**
- ⏳ Teste completo do fluxo: offline → salvar → fechar → abrir com rede → verificar sync

---

*Requirements updated: 2026-06-15*

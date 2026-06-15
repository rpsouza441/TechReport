# Requirements — Milestone v9.6

**Sync Queue Bug Fixes**

---

## REQ-01: RAT fica pendente apos falha offline

**Problem:** Quando o usuario salva uma RAT sem rede, ela fica "pendente" na fila de sincronizacao. Apos restart do app ou recovery de rede, a RAT continua pendente e nao e processada automaticamente.

**Acceptance criteria:**
- [ ] Apos restart do app, itens pendentes sao processados automaticamente
- [ ] RAT que falhou offline e syncada quando rede retorna
- [ ] Status da RAT e atualizado corretamente apos sucesso

**Source:** Bug discovered during offline testing

---

## REQ-02: Botao retry nao funciona

**Problem:** O botao "tentar novamente" na tela de fila de sincronizacao nao dispara a operacao de sync. O usuario clica e nada acontece.

**Acceptance criteria:**
- [ ] Clicar em "tentar novamente" inicia o processo de sync
- [ ] Loading indicator aparece durante a tentativa
- [ ] Status e atualizado apos sucesso ou falha

**Source:** Bug discovered during offline testing

---

## REQ-03: Fila nao identifica operacao

**Problem:** A fila de sincronizacao mostra apenas "RAT tentativas" ou "assinatura" sem identificar qual RAT ou assinatura especifico esta sendo trabalhado.

**Acceptance criteria:**
- [ ] Fila mostra identificacao do RAT (numero ou cliente)
- [ ] Fila mostra data/hora da tentativa
- [ ] Fila mostra tipo de operacao (criar, atualizar, excluir)

**Source:** Bug discovered during offline testing

---

## Dependencies

- REQ-01 depende de investigar o codigo de sync coordinator
- REQ-02 depende de identificar onde o retry esta quebrado
- REQ-03 e melhoria de UX que pode ser implementada junto com REQ-01/02

---

## Out of Scope

- Mudancas na estrutura do banco de dados
- Novas funcionalidades de sync
- Modificacoes em outras partes do app

---

*Requirements are subject to change during planning and execution.*

# Requirements — Phase 9.10

**Security Improvements**

---

## SEC-01: Implicit auth flow em Supabase client

**Problem:** `AuthFlowType.implicit` é menos seguro que PKCE.

**Files:**
- `lib/features/company_auth/data/services/supabase_client_factory.dart:63`

**Acceptance criteria:**
- [ ] Verificar se SDK suporta `AuthFlowType.pkce`
- [ ] Migrar para PKCE se disponível
- [ ] Testar fluxo de auth após mudança

**Source:** CONCERNS.md - Security Considerations

---

## SEC-02: PIN com baixa contagem de iterações

**Problem:** PBKDF2 com 10,000 iterações está abaixo das recomendações OWASP.

**Files:**
- `lib/shared/infra/security/local_pin_secret_store.dart:14`

**Acceptance criteria:**
- [ ] Aumentar para pelo menos 100,000 iterações
- [ ] Manter compatibilidade com PINs existentes
- [ ] Documentar mudança

**Source:** CONCERNS.md - Security Considerations

---

## SEC-03: Backup export sem criptografia

**Problem:** Backup ZIP contém dados em texto plano.

**Files:**
- `lib/features/local_auth/data/services/local_backup_service.dart`

**Acceptance criteria:**
- [ ] Adicionar criptografia AES-256 para backup
- [ ] Permitir senha para proteger backup
- [ ] Manter compatibilidade com backups legados

**Source:** CONCERNS.md - Security Considerations

---

## SEC-04: Secret keys com FlutterSecureStorage defaults

**Problem:** `FlutterSecureStorage` sem configuração explícita de plataforma.

**Files:**
- `lib/features/company_auth/data/services/flutter_secure_token_store.dart:6`

**Acceptance criteria:**
- [ ] Configurar `iOptions` e `aOptions` explicitamente
- [ ] Usar `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- [ ] Testar em Android e iOS

**Source:** CONCERNS.md - Security Considerations

---

## Out of Scope

- Implementação de Argon2id (futuro)
- Integração com hardware security modules
- Certificados SSL customizados

---

*Requirements created: 2026-06-15*

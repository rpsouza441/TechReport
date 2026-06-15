# TechReport — Requirements

**Based on:** Existing specs in `documentacao/spec/` and Sprint documentation
**Last updated:** 2026-06-15

---

## Core Requirements

### R-01: RAT Creation
**Priority:** Critical
- Create RAT with client info, equipment, service description
- Capture service date and completion status
- Support optional responsible document field
- Auto-generate unique RAT number

### R-02: Digital Signature
**Priority:** Critical
- Capture handwritten signature on touch screen
- Store signature as image (PNG/JPEG)
- Associate signature with specific RAT
- Support "signature pending" state until captured

### R-03: PDF Generation
**Priority:** Critical
- Generate PDF with RAT details and signature
- Include company/technician identification
- Support preview before export
- Share via native share sheet

### R-04: Local Storage
**Priority:** Critical
- Store all RATs in encrypted SQLite database
- Support PIN code protection (4-6 digits)
- Optional biometric authentication
- Backup and restore functionality

### R-05: Cloud Sync (Remote Mode)
**Priority:** High
- Sync RATs to Supabase backend
- Handle offline-first scenarios
- Conflict resolution for concurrent edits
- Session management with secure token storage

### R-06: Team Management (Remote Mode)
**Priority:** High
- Invite technicians via email
- Role-based permissions (admin, manager, technician)
- View team members and their RATs
- Revoke access when needed

---

## Non-Functional Requirements

### NFR-01: Security
- PIN stored with PBKDF2 (minimum 100K iterations)
- Database encrypted at rest
- Secure token storage for session
- No plaintext sensitive data in logs

### NFR-02: Offline-First
- App must be fully functional without network
- Local mode works without Supabase
- Sync queued when offline, processed when online

### NFR-03: Performance
- App launch under 3 seconds
- RAT list scrolls smoothly with 100+ items
- PDF generation under 5 seconds

### NFR-04: Accessibility
- Screen reader support for key actions
- Color contrast meeting WCAG AA
- Touch targets minimum 48x48dp

---

## Requirements NOT in Scope

- Multi-language support (PT-BR only for now)
- Web interface
- Desktop application
- Direct API integration with third-party services
- Automated invoicing

---

## Acceptance Criteria

### AC-01: RAT Lifecycle
- [ ] Technician can create new RAT
- [ ] Technician can add client and equipment details
- [ ] Technician can capture signature on screen
- [ ] Technician can generate and share PDF
- [ ] RAT is saved locally with encryption

### AC-02: Local Mode
- [ ] App works without network
- [ ] PIN protection prevents unauthorized access
- [ ] Biometric unlock works when enabled
- [ ] Backup can be exported and restored

### AC-03: Remote Mode
- [ ] RATs sync to Supabase when online
- [ ] Team members can see shared RATs
- [ ] Admin can manage team invites
- [ ] Permissions are enforced correctly

### AC-04: Security
- [ ] PIN cannot be brute-forced (rate limiting)
- [ ] Database files are encrypted
- [ ] Session tokens are stored securely
- [ ] No sensitive data in logs

---

## Traceability

| Requirement | Sprint | Status |
|-------------|--------|--------|
| R-01: RAT Creation | Sprint 5 | ✅ Complete |
| R-02: Digital Signature | Sprint 5 | ✅ Complete |
| R-03: PDF Generation | Sprint 5 | ✅ Complete |
| R-04: Local Storage | Sprint 9 | ✅ Complete |
| R-05: Cloud Sync | Sprint 5-8 | ✅ Complete |
| R-06: Team Management | Sprint 8.5 | ✅ Complete |
| NFR-01: Security | Sprint 9 | 🔄 In Progress |
| NFR-04: Accessibility | Sprint 9 | 🔄 In Progress |

---

*This document summarizes functional and non-functional requirements. See `documentacao/spec/` for detailed specifications.*

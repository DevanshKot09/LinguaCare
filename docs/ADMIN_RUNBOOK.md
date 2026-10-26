# Admin Runbook – Specialist Verification & Role Testing

## Overview
Specialists (Speech-Language Pathologists) register with their professional credentials (profession, licence number, licensing body, workplace). By default, `profiles.verified` is set to `false`, locking clinical features until manual verification.

---

## Role Testing Best Practices
- Role testing should be conducted using **separate accounts** (e.g. Gmail aliases such as `<redacted>`, `<redacted>`, `<redacted>`, `<redacted>`).
- Do NOT weaken role guards in release or debug; role guards (such as ensuring a signed-in Teacher is directed to `/teacher`) are correct and enforced.

---

## Specialist Verification Procedure
1. **Verify Credentials:**
   - Log in to the regional Speech-Language Pathology regulatory board or licensing registry.
   - Verify the specialist's licence number, licensing body, and active professional standing.

2. **Run SQL Update in Supabase SQL Editor:**
   Execute the following query to approve the specialist in the dev project. Replace `<target_uid>` with the specialist's Firebase UID from the `profiles` table:
   ```sql
   -- 1. Approve specialist
   update profiles
   set verified = true
   where uid = '<target_uid>' and role = 'specialist';

   -- 2. Log manual verification in access_audit
   insert into access_audit (actor_uid, action, table_name, record_id)
   values ('<admin_uid>', 'VERIFY_SPECIALIST', 'profiles', '<target_uid>');
   ```

3. **Audit & Compliance:**
   - Every verification action is audit-logged in `access_audit`.
   - Never share database admin keys or credentials.

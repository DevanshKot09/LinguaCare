-- Migration 000029: Allow profiles update policy to permit verified status changes via specialist licence trigger

DROP POLICY IF EXISTS profiles_update_owner ON profiles;
CREATE POLICY profiles_update_owner ON profiles
  FOR UPDATE USING (uid = auth.jwt()->>'sub' OR auth.jwt()->>'role' = 'service_role')
  WITH CHECK (
    uid = auth.jwt()->>'sub'
    OR auth.jwt()->>'role' = 'service_role'
    OR role = (SELECT p.role FROM profiles p WHERE p.uid = auth.jwt()->>'sub')
  );

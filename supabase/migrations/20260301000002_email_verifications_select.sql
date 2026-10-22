-- Allow authenticated users to select their own email verification status only
drop policy if exists email_verifications_select_owner on email_verifications;
create policy email_verifications_select_owner on email_verifications
  for select using (uid = auth.jwt()->>'sub');

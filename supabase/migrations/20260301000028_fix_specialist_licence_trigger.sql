-- Migration 000028: Fix specialist licence change trigger to bypass RLS when resetting verified status

CREATE OR REPLACE FUNCTION handle_specialist_licence_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (TG_OP = 'UPDATE') AND (
    NEW.licence_no IS DISTINCT FROM OLD.licence_no OR
    NEW.licence_body IS DISTINCT FROM OLD.licence_body OR
    NEW.profession IS DISTINCT FROM OLD.profession
  ) THEN
    UPDATE profiles SET verified = false WHERE uid = NEW.uid;
  END IF;
  RETURN NEW;
END;
$$;

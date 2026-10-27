-- Migration 000031: Allow specialist licence verification reset in protect_profile_updates trigger

create or replace function protect_profile_updates()
returns trigger as $$
begin
  if old.uid <> new.uid or old.email <> new.email or old.role <> new.role then
    raise exception 'Unauthorized modification of locked profile fields (uid, email, role).';
  end if;
  if old.verified <> new.verified then
    -- Allow verified to change from true to false (licence reset)
    if not (old.verified = true and new.verified = false) then
      raise exception 'Unauthorized modification of locked profile fields (verified).';
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

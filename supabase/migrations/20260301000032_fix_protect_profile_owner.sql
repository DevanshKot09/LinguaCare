-- Migration 000032: Allow table owner (postgres) to bypass protect_profile_updates trigger

create or replace function protect_profile_updates()
returns trigger as $$
begin
  if current_user = 'postgres' or current_setting('role', true) = 'postgres' then
    return new;
  end if;

  if old.uid <> new.uid or old.email <> new.email or old.role <> new.role then
    raise exception 'Unauthorized modification of locked profile fields (uid, email, role).';
  end if;
  if old.verified <> new.verified then
    if not (old.verified = true and new.verified = false) then
      raise exception 'Unauthorized modification of locked profile fields (verified).';
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

import os

sections = ['rls_checks', 'rls_checks_links', 'rls_checks_obs_goals']

for s in sections:
    v1_path = f"supabase/tests/{s}_v1.sql"
    curr_path = f"supabase/tests/{s}.sql"

    if os.path.exists(v1_path):
        with open(v1_path, 'r', encoding='utf-16', errors='ignore') as f:
            content = f.read()
        with open(curr_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Converted and wrote {curr_path} in UTF-8")

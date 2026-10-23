import os

sections = ['rls_checks', 'rls_checks_links', 'rls_checks_obs_goals']

for s in sections:
    v1_path = f"supabase/tests/{s}_v1.sql"
    curr_path = f"supabase/tests/{s}.sql"

    with open(v1_path, 'r', encoding='utf-16', errors='ignore') as f:
        v1_content = f.read()
    with open(curr_path, 'r', encoding='utf-8', errors='ignore') as f:
        curr_content = f.read()

    print(f"Loaded {s}: v1 has {len(v1_content)} chars, curr has {len(curr_content)} chars")

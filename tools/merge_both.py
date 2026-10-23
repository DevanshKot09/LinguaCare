import os

sections = ['rls_checks', 'rls_checks_links', 'rls_checks_obs_goals']

for s in sections:
    v1_path = f"supabase/tests/{s}_v1.sql"
    curr_path = f"supabase/tests/{s}.sql"

    with open(v1_path, 'r', encoding='utf-16', errors='ignore') as f:
        v1_text = f.read()
    with open(curr_path, 'r', encoding='utf-8', errors='ignore') as f:
        curr_text = f.read()

    # Find v_required_tests in curr_text and replace in v1_text
    # Or even simpler: read required_tests.txt and required_existing.txt
    pass
print("Merge script template")

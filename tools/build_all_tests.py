import os

req, exist = {}, {}
# Load manifests
curr_sec = None
with open('supabase/tests/required_tests.txt', 'r', encoding='utf-8') as f:
    for line in f:
        l = line.strip()
        if l.startswith('[') and l.endswith(']'):
            curr_sec = l[1:-1]
            req[curr_sec] = []
        elif l and curr_sec:
            req[curr_sec].append(l)

curr_sec = None
with open('supabase/tests/required_existing.txt', 'r', encoding='utf-8') as f:
    for line in f:
        l = line.strip()
        if l.startswith('[') and l.endswith(']'):
            curr_sec = l[1:-1]
            exist[curr_sec] = []
        elif l and curr_sec:
            exist[curr_sec].append(l)

sections = ['rls_checks', 'rls_checks_links', 'rls_checks_obs_goals']

for s in sections:
    v1_path = f"supabase/tests/{s}_v1.sql"
    curr_path = f"supabase/tests/{s}.sql"

    with open(v1_path, 'r', encoding='utf-16', errors='ignore') as f:
        v1_text = f.read()
    with open(curr_path, 'r', encoding='utf-8', errors='ignore') as f:
        curr_text = f.read()

    all_tests = exist[s] + req[s]

    # Extract test blocks from curr_text that are not in v1_text and append them before the manifest check
    missing_tests = [t for t in req[s] if t not in v1_text]
    print(f"Section {s}: {len(exist[s])} existing, {len(req[s])} required. Missing in v1: {len(missing_tests)}")

    # We can construct the combined v_required_tests array definition in SQL
    array_items = ",\n    ".join([f"'{t}'" for t in all_tests])
    new_array_sql = f"v_required_tests text[] := ARRAY[\n    {array_items}\n  ];"

    # Replace v_required_tests in v1_text
    # Find where v_required_tests starts and ends
    start_idx = v1_text.find("v_required_tests text[] := ARRAY[")
    if start_idx != -1:
        end_idx = v1_text.find("  ];", start_idx) + 4
        v1_text = v1_text[:start_idx] + new_array_sql + v1_text[end_idx:]

    # Also append missing test blocks from curr_text to v1_text right before manifest verification
    # Find manifest check or end of tests in v1_text
    manifest_idx = v1_text.find("v_missing_count")
    if manifest_idx == -1:
        manifest_idx = v1_text.find("v_logged_count")

    # Extract missing test blocks from curr_text
    added_blocks = ""
    for t in missing_tests:
        # Find test block in curr_text
        pos = curr_text.find(t)
        if pos != -1:
            # find start of comment or BEGIN before pos
            block_start = curr_text.rfind("--", 0, pos)
            if block_start == -1:
                block_start = curr_text.rfind("BEGIN", 0, pos)
            # find end of block (EXCEPTION or END;) after pos
            block_end = curr_text.find("  END;\n  END;", pos)
            if block_end == -1:
                block_end = curr_text.find("  END;", pos) + 6
            else:
                block_end += 6
            if block_start != -1 and block_end != -1:
                added_blocks += "\n  -- Added required test block for: " + t + "\n  " + curr_text[block_start:block_end] + "\n"

    if manifest_idx != -1 and added_blocks:
        v1_text = v1_text[:manifest_idx] + added_blocks + "\n  " + v1_text[manifest_idx:]

    # Write out to curr_path
    with open(curr_path, 'w', encoding='utf-8') as f:
        f.write(v1_text)
    print(f"Wrote combined test file {curr_path}")

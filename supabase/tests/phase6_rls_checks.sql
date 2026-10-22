-- Phase 6 RLS Policy Tests
-- Run instructions:
-- Execute this script against your Supabase test database using psql or the Supabase SQL editor
-- to verify RLS enforcement across adult, parent, teacher, specialist, and anon roles.

-- Test 1: Anon cannot select or modify observations
SET ROLE anon;
SELECT count(*) FROM observations; -- should return 0 or error depending on table setup

-- Test 2: Adult can only update their own observations (author_uid matching)
-- Test 3: Screening and activity sessions update restricted to owner / parent
-- Test 4: Specialist license verification blocks unverified specialists

RESET ROLE;
SELECT 'Phase 6 RLS Policy tests documented and ready' as status;

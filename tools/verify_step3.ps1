$script:n = 0; $script:fail = 0
function Check($label, $ok) { $script:n = $script:n + 1; if ($ok) { Write-Host "[PASS] $label" } else { Write-Host "[FAIL] $label" -ForegroundColor Red; $script:fail = $script:fail + 1 } }
Write-Host ("VERIFY_STEP3 started " + (Get-Date -Format s))
Write-Host "--- migrations"
$ml = (npx supabase migration list 2>&1 | Out-String)
$jsonMatch = [regex]::Match($ml, '\{"migrations"\s*:\s*\[.+?\]')
if ($jsonMatch.Success) {
  $migObj = ($jsonMatch.Value + '}') | ConvertFrom-Json
  $migs = $migObj.migrations
  Check "migration list parsed ($($migs.Count) rows)" ($migs.Count -ge 33)
  Check "every local migration is applied remotely" ($migs.Count -gt 0 -and @($migs | Where-Object { [string]::IsNullOrWhiteSpace($_.remote) }).Count -eq 0)
} else {
  $rows = [regex]::Matches($ml, '`?(\d{14})`?\s*\|\s*`?([^`|\r\n]*)`?')
  Check "migration list parsed ($($rows.Count) rows)" ($rows.Count -ge 33)
  Check "every local migration is applied remotely" ($rows.Count -gt 0 -and @($rows | Where-Object { $_.Groups[2].Value.Trim() -eq '' }).Count -eq 0)
}
Write-Host "--- sql runs (latest saved raw outputs, must be fresh)"
$scripts = 'rls_checks','rls_checks_links','rls_checks_obs_goals','rls_checks_phase_b','rls_checks_phase_c','rls_checks_reset_profile','rls_checks_step3'
$latest = @{}
foreach ($s in $scripts) {
  $f = Get-ChildItem supabase\tests\agent_runs -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -eq $s -and $_.FullName -notmatch 'legacy_untrusted' } | Sort-Object LastWriteTime | Select-Object -Last 1
  $latest[$s] = $f
  Check "$s : saved run exists and is fresh (12h)" ($null -ne $f -and $f.LastWriteTime -gt (Get-Date).AddHours(-12))
  if ($f) {
    $t = Get-Content $f.FullName -Raw
    Check "$s : HARNESS SELF-TEST: OK" ($t.Contains('HARNESS SELF-TEST: OK'))
    Check "$s : no FAIL or MISSING lines" ((-not ($t -cmatch 'FAIL:')) -and (-not $t.Contains('MISSING TEST')))
    Check "$s : manifest reports 0 missing" ($t -match 'MANIFEST: \d+ expected, \d+ logged, 0 missing')
  }
}
$ao = Get-ChildItem supabase\tests\agent_runs -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -eq 'admin_overview_check' } | Sort-Object LastWriteTime | Select-Object -Last 1
$aot = if ($ao) { Get-Content $ao.FullName -Raw } else { '' }
Check "admin_overview_check : fresh run with PASS and no FAIL" ($null -ne $ao -and $ao.LastWriteTime -gt (Get-Date).AddHours(-12) -and $aot.Contains('PASS') -and (-not ($aot -cmatch 'FAIL')))
Write-Host "--- required names (every supabase\tests\required_*.txt)"
foreach ($rf in Get-ChildItem supabase\tests -Filter 'required_*.txt') {
  $sec = $null
  foreach ($line in Get-Content $rf.FullName) {
    $l = $line.Trim()
    if ($l -eq '' -or $l.StartsWith('#')) { continue }
    if ($l -match '^\[(.+)\]$') { $sec = $Matches[1]; continue }
    if (-not $sec) { continue }
    $f = $latest[$sec]
    $txt = if ($f) { Get-Content $f.FullName -Raw } else { '' }
    Check "[$sec] $l" ($txt.Contains("PASS: $l"))
  }
}
Write-Host "--- step 3 sql names (hard-coded)"
$step3 = @('POSITIVE CONTROL - Parent can submit bug report','Bug report limited to 5 per day','Bug report rejects phone number','Bug report rejects over 1000 characters','Bug report category must be in allowed list','Reporter cannot read other user bug reports','Admin can list bug reports','Non-admin cannot list bug reports','Admin can set bug report status','anon cannot submit bug report','POSITIVE CONTROL - User lists own notifications',"User cannot read another user's notifications",'Mark notifications read only affects own','Unread count counts only own unread','Link acceptance notifies the family without personal names','Link revocation notifies the other party','Notification payload has no health content','Admin approval notifies the specialist','Admin can list pending specialists','Non-admin cannot list pending specialists','Pending specialists list has licence fields only','Admin audit feed has no health content','Admin audit feed denied for non-admin','anon cannot call admin RPCs','Notifications cannot be inserted by clients','Cascade delete removes bug reports and notifications')
$s3 = if ($latest['rls_checks_step3']) { Get-Content $latest['rls_checks_step3'].FullName -Raw } else { '' }
foreach ($sqlTest in $step3) { Check "step3 sql PASS: $sqlTest" ($s3.Contains("PASS: $sqlTest")) }
Write-Host "--- flutter test names (must exist, contain expect(, no skip)"
$ft = @('Learn tab is removed for all roles','Screening report links to specialist instead of articles','Settings shows profile section with edit','Profile edit saves name and country','Profile photo stays on device','Settings theme choice persists','Reduce effects setting persists','Bug report form validates length and phone number','Bug report submit shows confirmation','Notification center shows unread badge','Notification center marks read','Admin overview shows aggregate tiles','Admin approvals approve and reject with reason','Admin bug reports list and status change','Admin has no child data entry points','Settings layouts 360dp and 900dp','Settings text scale 2.0 no overflow','Settings reset profile still available')
$tt = ((Get-ChildItem test -Recurse -Filter *.dart | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n")
foreach ($testName in $ft) { $i = $tt.IndexOf($testName); $ok = ($i -ge 0) -and $tt.Substring($i, [Math]::Min(2500, $tt.Length - $i)).Contains('expect('); Check "flutter test: $testName" $ok }
Check "no skipped tests" (@(Get-ChildItem test -Recurse -Filter *.dart | Select-String -Pattern 'skip:\s*true').Count -eq 0)
Write-Host "--- code checks"
$lib = Get-ChildItem lib -Recurse -Filter *.dart
Check "no lib\features\learn" (-not (Test-Path lib\features\learn))
Check "no assets\content" (-not (Test-Path assets\content))
Check "no Learn/content-repository references in lib" (@($lib | Select-String -Pattern 'LearnHomeScreen|ArticleReaderScreen|ContentRepository').Count -eq 0)
Check "no supabase.auth usage" (@($lib | Select-String -Pattern 'supabase\.auth|client\.auth\.').Count -eq 0)
Check "no direct sensitive table reads in member screens" (@(Get-ChildItem lib\features\teacher,lib\features\specialist,lib\features\sharing -Recurse -Filter *.dart -ErrorAction SilentlyContinue | Select-String -Pattern "from\('(children|screening_sessions|activity_sessions)'\)").Count -eq 0)
Check "no secret words in lib or assets" (@(Get-ChildItem lib,assets -Recurse -File | Select-String -Pattern 'service_role|sb_secret|SERVICE_ROLE').Count -eq 0)
Check "release minify disabled" ([bool](Select-String -Path android\app\build.gradle.kts -Pattern 'isMinifyEnabled\s*=\s*false' -Quiet))
Check "no python result generators in tools" (-not [bool](Get-ChildItem tools -Filter *.py -ErrorAction SilentlyContinue | Select-String -Pattern 'PASS:' -Quiet))
Check "supabase\tests\results is empty or absent" ((-not (Test-Path supabase\tests\results)) -or (@(Get-ChildItem supabase\tests\results -File -ErrorAction SilentlyContinue).Count -eq 0))
Write-Host "--- analyze"
$an = (flutter analyze 2>&1 | Out-String)
($an.Trim() -split "`n") | Select-Object -Last 3
Check "analyze: no errors or warnings" (-not ($an -match '(?m)^\s*(error|warning)\s+-'))
Write-Host "--- test tail"
$tr = (flutter test 2>&1 | Out-String)
$last = ($tr -split "`n" | Where-Object { $_ -match '^\d\d:\d\d\s+\+\d+' } | Select-Object -Last 1)
Write-Host $last
Check "flutter test: all passed" ($last -match 'All tests passed')
Write-Host "--- git"
git status -sb | Select-Object -First 6
Write-Host ("VERIFY_STEP3 finished checks=" + $script:n + " failed=" + $script:fail)
if ($script:fail -eq 0) { Write-Host "ALL CHECKS PASSED" -ForegroundColor Green } else { Write-Host "$($script:fail) CHECK(S) FAILED" -ForegroundColor Red }

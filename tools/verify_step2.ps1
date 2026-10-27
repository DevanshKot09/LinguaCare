$fail = 0
function Check($label, $ok) { if ($ok) { Write-Host "[PASS] $label" } else { Write-Host "[FAIL] $label" -ForegroundColor Red; $script:fail++ } }
$flutterTests = @(
 'Signup requires name, valid email, strong password and matching confirm',
 'Signup requires role selection',
 'Signup shows progress indicator step 1 of 5',
 'Google button requires role first',
 'Pending role survives verify-email and prefills role details',
 'Country dropdown is searchable and defaults to India',
 'Role selection screen is not part of normal flow',
 'Choose-your-role fallback back signs out',
 'Parent details step shows band after DOB',
 'Specialist details show verification pending explanation',
 'Redirect: verified without profile and with pending role goes to about-you',
 'Redirect: verified without profile and without pending role goes to choose-role',
 'Settings reset profile asks for confirmation text',
 'Reset profile unavailable for verified specialist',
 'Layouts 360dp and 900dp for signup and about-you',
 'Text scale 2.0 no overflow for signup and about-you')
$testText = ((Get-ChildItem test -Recurse -Filter *.dart | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n")
foreach ($n in $flutterTests) { Check "flutter test exists: $n" ($testText.Contains($n)) }
$libFiles = Get-ChildItem lib -Recurse -Filter *.dart
Check "class StepProgress exists" ([bool]($libFiles | Select-String -Pattern 'class StepProgress' -Quiet))
Check "class CountryDropdown exists" ([bool]($libFiles | Select-String -Pattern 'class CountryDropdown' -Quiet))
Check "pendingRoleProvider exists" ([bool]($libFiles | Select-String -Pattern 'pendingRoleProvider' -Quiet))
Check "assets/data/countries.json exists" (Test-Path assets\data\countries.json)
if (Test-Path assets\data\countries.json) { Check "countries.json has at least 190 entries" ((Get-Content assets\data\countries.json -Raw | ConvertFrom-Json).Count -ge 190) }
Check "minify disabled in release" ([bool](Select-String -Path android\app\build.gradle.kts -Pattern 'isMinifyEnabled\s*=\s*false' -Quiet))
$names = @(Get-Content supabase\tests\required_reset_profile.txt | Where-Object { $_.Trim() -and -not $_.StartsWith('[') -and -not $_.StartsWith('#') })
$run = Get-ChildItem supabase\tests\agent_runs -Recurse -Filter 'rls_checks_reset_profile*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
$runText = if ($run) { Get-Content $run.FullName -Raw } else { '' }
Check "reset_profile run file exists" ([bool]$run)
foreach ($n in $names) { Check "sql PASS line: $n" ($runText.Contains("PASS: $n")) }
Check "reset_profile run has HARNESS SELF-TEST: OK" ($runText.Contains('HARNESS SELF-TEST: OK'))
Write-Host "--- analyze tail"; (flutter analyze 2>&1 | Select-Object -Last 4)
Write-Host "--- test tail"; (flutter test 2>&1 | Where-Object { $_ -match '^\d\d:\d\d\s+\+\d+' } | Select-Object -Last 1)
Write-Host "--- git"; git status -sb | Select-Object -First 6
if ($fail -eq 0) { Write-Host "ALL CHECKS PASSED" -ForegroundColor Green } else { Write-Host "$fail CHECK(S) FAILED" -ForegroundColor Red }

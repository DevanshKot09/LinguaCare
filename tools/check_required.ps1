# Run from project root: powershell -ExecutionPolicy Bypass -File tools\check_required.ps1
$bad = 0; $total = 0; $sections = @{}
foreach ($f in Get-ChildItem supabase\tests -Filter 'required_*.txt') {
  Write-Host "##### $($f.Name)"
  $section = $null
  foreach ($line in Get-Content $f.FullName) {
    $l = $line.Trim()
    if ($l -eq '' -or $l.StartsWith('#')) { continue }
    if ($l -match '^\[(.+)\]$') { $section = $Matches[1]; $sections[$section] = $true; Write-Host "--- $section"; continue }
    $total++
    $sql = "supabase\tests\$section.sql"; $res = "supabase\tests\results\$section.txt"
    $inSql = (Test-Path $sql) -and (Select-String -Path $sql -Pattern $l -SimpleMatch -Quiet)
    $inRes = (Test-Path $res) -and (Select-String -Path $res -Pattern ("PASS: " + $l) -SimpleMatch -Quiet)
    if (-not $inSql)     { Write-Host "[MISSING IN SCRIPT]  $l" -ForegroundColor Red;    $bad++ }
    elseif (-not $inRes) { Write-Host "[NO PASS IN RESULT]  $l" -ForegroundColor Yellow; $bad++ }
  }
}
foreach ($s in $sections.Keys) {
  $res = "supabase\tests\results\$s.txt"
  foreach ($must in 'HARNESS SELF-TEST: OK', 'VACUOUS-RISK CHECK', 'POSITIVE CONTROL') {
    if (-not ((Test-Path $res) -and (Select-String -Path $res -Pattern $must -SimpleMatch -Quiet))) { Write-Host "[RESULT $s lacks] $must" -ForegroundColor Red; $bad++ }
  }
  if ((Test-Path $res) -and (Select-String -Path $res -Pattern 'FAIL:|MISSING TEST' -CaseSensitive -Quiet)) { Write-Host "[RESULT $s has FAIL/MISSING lines]" -ForegroundColor Red; $bad++ }
}
if ($bad -eq 0) { Write-Host "ALL $total REQUIRED TESTS PRESENT AND PASSING; HARNESS LINES OK" -ForegroundColor Green }
else { Write-Host "$bad requirement(s) not satisfied (of $total tests)" -ForegroundColor Red }
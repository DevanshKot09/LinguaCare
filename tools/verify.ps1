$ErrorActionPreference = "Continue"

Write-Host "=== LINGUACARE VERIFICATION REPORT ==="

Write-Host "`n1. Flutter Analyze Counts:"
$analyzeOutput = flutter analyze 2>&1
$errorCount = ($analyzeOutput | Select-String "error -").Count
$warningCount = ($analyzeOutput | Select-String "warning -").Count
$infoCount = ($analyzeOutput | Select-String "info -").Count
Write-Host "Errors: $errorCount, Warnings: $warningCount, Infos: $infoCount"

Write-Host "`n2. Flutter Test Final Line:"
$testOutput = flutter test 2>&1
$lastTestLine = $testOutput | Select-Object -Last 1
Write-Host "$lastTestLine"

Write-Host "`n3. Test Declaration Counts per File:"
$testFiles = Get-ChildItem -Recurse -Path test -Filter "*.dart"
$totalTests = 0
foreach ($file in $testFiles) {
    $content = Get-Content $file.FullName
    $count = ($content | Select-String 'test\(' -AllMatches).Count + ($content | Select-String 'testWidgets\(' -AllMatches).Count
    $totalTests += $count
    Write-Host "$($file.Name): $count tests"
}
Write-Host "Total Test Declarations: $totalTests"

Write-Host "`n4. Code Guardrail Checks on lib/:"
$libFiles = Get-ChildItem -Recurse -Path lib -Filter "*.dart"

# Check supabase.auth
$supabaseAuthCount = 0
foreach($f in $libFiles) {
    $c = Get-Content $f.FullName -Raw
    if ($c -match "supabase\.auth") { $supabaseAuthCount++ }
}
Write-Host "Files containing 'supabase.auth': $supabaseAuthCount (Expected: 0)"

# Check direct reads in member screens (teacher/specialist/sharing)
$memberDirs = @("lib/features/teacher", "lib/features/specialist", "lib/features/sharing")
$directReadsCount = 0
foreach($dir in $memberDirs) {
    if (Test-Path $dir) {
        $mFiles = Get-ChildItem -Recurse -Path $dir -Filter "*.dart"
        foreach($f in $mFiles) {
            $c = Get-Content $f.FullName -Raw
            if ($c -match "children" -or $c -match "screening_sessions" -or $c -match "activity_sessions") {
                if ($c -match "\.from\(" -and ($c -match "children" -or $c -match "screening_sessions" -or $c -match "activity_sessions")) {
                    Write-Host "Potential direct table read in $($f.FullName)"
                    $directReadsCount++
                }
            }
        }
    }
}
Write-Host "Direct table reads in member screens: $directReadsCount (Expected: 0)"

# Check service_role / sb_secret
$secretStringsCount = 0
foreach($f in $libFiles) {
    $c = Get-Content $f.FullName -Raw
    if ($c -match "service_role" -or $c -match "sb_secret") {
        Write-Host "Found forbidden secret string in $($f.FullName)"
        $secretStringsCount++
    }
}
Write-Host "Files with service_role/sb_secret: $secretStringsCount (Expected: 0)"

# Check runtime google_fonts
$googleFontsCount = 0
foreach($f in $libFiles) {
    $c = Get-Content $f.FullName -Raw
    if ($c -match "GoogleFonts\.") {
        $googleFontsCount++
    }
}
Write-Host "Files using runtime GoogleFonts: $googleFontsCount (Expected: 0)"

Write-Host "`n5. Android Manifest & Build Configuration:"
$manifestPath = "android/app/src/main/AndroidManifest.xml"
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath
    $manifestContent | Select-String "INTERNET"
    $manifestContent | Select-String "allowBackup"
}

$gradlePath = "android/app/build.gradle.kts"
if (Test-Path $gradlePath) {
    $gradleContent = Get-Content $gradlePath
    $gradleContent | Select-String "isMinifyEnabled"
    $gradleContent | Select-String "isShrinkResources"
    $gradleContent | Select-String "signingConfig"
}

Write-Host "`n6. Key Package Versions (pubspec.yaml):"
$pubspec = Get-Content "pubspec.yaml"
$pubspec | Select-String "supabase_flutter", "firebase_auth", "go_router", "flutter_riverpod", "google_fonts"

Write-Host "`n7. Git Status:"
git status -sb

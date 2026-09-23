$ErrorActionPreference = 'Stop'

$apiBaseUrl = 'https://uetmardan.edu.pk/dept_comp/public/api'

Write-Host "Building DCMCS clients for $apiBaseUrl"

flutter build apk --release --dart-define="API_BASE_URL=$apiBaseUrl"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build web --release --base-href=/dept_comp/public/site/ --dart-define="API_BASE_URL=$apiBaseUrl"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Production builds completed.'
Write-Host 'APK: build/app/outputs/flutter-apk/app-release.apk'
Write-Host 'Web: build/web/'

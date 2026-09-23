$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    flutter build web --release --no-pub --base-href=/dept_comp/public/site/ --dart-define=API_BASE_URL=https://uetmardan.edu.pk/dept_comp/public/api
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    New-Item -ItemType Directory -Path backend/public/site -Force | Out-Null
    Copy-Item -Path build/web/* -Destination backend/public/site -Recurse -Force
    python scripts/package-same-url.py
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

param(
  [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA "DeskCode")
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$PackageDirectory = Join-Path $RepositoryRoot "packages\opencode"
$ConfigSource = Join-Path $RepositoryRoot "custom\deskcode\opencode.jsonc"
$EnvExample = Join-Path $RepositoryRoot "custom\deskcode\.env.example"

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
  throw "Bun não encontrado. Instale em https://bun.sh e abra um novo PowerShell."
}

Write-Host "Instalando dependências..." -ForegroundColor Cyan
Push-Location $RepositoryRoot
try {
  bun install
  if ($LASTEXITCODE -ne 0) { throw "bun install falhou." }

  Write-Host "Compilando DeskCode para esta máquina..." -ForegroundColor Cyan
  Push-Location $PackageDirectory
  try {
    bun run script/build.ts --single
    if ($LASTEXITCODE -ne 0) { throw "O build falhou." }
  }
  finally {
    Pop-Location
  }
}
finally {
  Pop-Location
}

$Architecture = switch ($env:PROCESSOR_ARCHITECTURE) {
  "AMD64" { "x64" }
  "ARM64" { "arm64" }
  default { throw "Arquitetura Windows não suportada: $env:PROCESSOR_ARCHITECTURE" }
}

$BinarySource = Join-Path $PackageDirectory "dist\opencode-windows-$Architecture\bin\opencode.exe"
if (-not (Test-Path $BinarySource)) {
  throw "Binário não encontrado após o build: $BinarySource"
}

New-Item -ItemType Directory -Force -Path $InstallDirectory | Out-Null
Copy-Item $BinarySource (Join-Path $InstallDirectory "deskcode.exe") -Force
Copy-Item $ConfigSource (Join-Path $InstallDirectory "opencode.jsonc") -Force

$EnvDestination = Join-Path $InstallDirectory ".env"
if (-not (Test-Path $EnvDestination)) {
  Copy-Item $EnvExample $EnvDestination
}

$Launcher = @'
$ErrorActionPreference = "Stop"
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
  Get-Content $envFile |
    Where-Object { $_ -and -not $_.TrimStart().StartsWith("#") } |
    ForEach-Object {
      $pair = $_ -split "=", 2
      if ($pair.Count -eq 2) {
        Set-Item -Path ("Env:" + $pair[0].Trim()) -Value $pair[1].Trim()
      }
    }
}
$env:OPENCODE_CONFIG = Join-Path $PSScriptRoot "opencode.jsonc"
& (Join-Path $PSScriptRoot "deskcode.exe") @args
exit $LASTEXITCODE
'@
Set-Content -Path (Join-Path $InstallDirectory "deskcode.ps1") -Value $Launcher -Encoding UTF8

Write-Host ""
Write-Host "DeskCode instalado em $InstallDirectory" -ForegroundColor Green
Write-Host "1. Edite $EnvDestination e informe uma chave Gemini NOVA."
Write-Host "2. Execute: & '$InstallDirectory\deskcode.ps1'"
Write-Host "Os limites reais de contexto, saída e requisições continuam sendo definidos pelo Gemini."

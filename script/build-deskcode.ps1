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
    bun run script/build.ts --single --baseline
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

$BinarySource = Join-Path $PackageDirectory "dist\opencode-windows-$Architecture-baseline\bin\opencode.exe"
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

Copy-Item (Join-Path $RepositoryRoot "custom\deskcode\deskcode.ps1") (Join-Path $InstallDirectory "deskcode.ps1") -Force
Copy-Item (Join-Path $RepositoryRoot "custom\deskcode\DeskCode.cmd") (Join-Path $InstallDirectory "DeskCode.cmd") -Force

Write-Host ""
Write-Host "DeskCode instalado em $InstallDirectory" -ForegroundColor Green
Write-Host "Execute: '$InstallDirectory\DeskCode.cmd'"
Write-Host "Na primeira execução, o DeskCode solicitará uma chave Gemini NOVA."
Write-Host "Os limites reais de contexto, saída e requisições continuam sendo definidos pelo Gemini."

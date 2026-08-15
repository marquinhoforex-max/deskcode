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

$apiKey = [Environment]::GetEnvironmentVariable("GOOGLE_GENERATIVE_AI_API_KEY")
if (-not $apiKey -or $apiKey -eq "coloque_sua_nova_chave_aqui") {
  Write-Host "Configure sua chave Gemini para usar o modelo padrão." -ForegroundColor Cyan
  $secureKey = Read-Host "Cole uma chave Gemini NOVA" -AsSecureString
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
  try {
    $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }

  if (-not $apiKey) {
    throw "Nenhuma chave foi informada."
  }

  Set-Content -Path $envFile -Value "GOOGLE_GENERATIVE_AI_API_KEY=$apiKey" -Encoding UTF8
  Set-Item -Path "Env:GOOGLE_GENERATIVE_AI_API_KEY" -Value $apiKey
  Write-Host "Chave salva somente em $envFile" -ForegroundColor Green
}

$env:OPENCODE_CONFIG = Join-Path $PSScriptRoot "opencode.jsonc"
& (Join-Path $PSScriptRoot "deskcode.exe") @args
exit $LASTEXITCODE

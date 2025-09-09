Param(
  [ValidateSet("patch","minor","major")]
  [string]$Bump = "patch"
)
$ErrorActionPreference = "Stop"
Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) | Out-Null
Set-Location ..
Write-Host "== Release gate: lint/typecheck/build/tests =="
npm run run-lint
npm run run-typecheck
npm run build
npm run run-tests
Write-Host "== Bump & changelog =="
npm run ("release:{0}" -f $Bump)
Write-Host "== Recent tags =="
git tag --sort=-creatordate | Select-Object -First 5
# setup-env.ps1 (v1)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Write-Host '[setup] env check' 
node -v; npm -v | Out-Null
python --version | Out-Null
pip --version | Out-Null
Write-Host '[ok] tools detected'
exit 0
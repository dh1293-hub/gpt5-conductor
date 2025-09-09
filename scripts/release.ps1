param(
  [ValidateSet("patch","minor","major")] [string]$Type = "patch",
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Warn($m){ Write-Host $m -ForegroundColor DarkYellow }
function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Fail($m){ Write-Host $m -ForegroundColor Red; exit 2 }
function Exec($exe, $args){
  & $exe @args
  if ($LASTEXITCODE -ne 0) { Fail "command failed: $exe $($args -join ' ')" }
}

Warn "⚠ Running release in current PowerShell session. Keep this window open."

# 0) 위치 보정
$repo = (Resolve-Path ".").Path
if (-not (Test-Path "$repo\package.json")) { Fail "Not at repo root. Abort." }

# 0-1) 도구 경로(PS5 호환: npm.ps1 회피)
$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue)?.Source
if (-not $npm) { $npm = (Get-Command npm -ErrorAction SilentlyContinue)?.Source }
if (-not $npm) { Fail "npm not found" }

$npx = (Get-Command npx.cmd -ErrorAction SilentlyContinue)?.Source
if (-not $npx) { $npx = (Get-Command npx -ErrorAction SilentlyContinue)?.Source }
if (-not $npx) { Fail "npx not found" }

# 1) 원격 동기화 & 클린 체크
Info "Fetching remote tags..."
git fetch --all --tags --prune | Out-Null

$st = git status --porcelain
if ($st) { Fail "Working tree not clean. Commit or stash first." }

# 2) 게이트
Info "Running gates: build → smoke → contract → tests"
Exec $npm @('run','build')
Exec $npm @('run','run-smoke')
Exec $npm @('run','run-contract')
Exec $npm @('run','run-tests')

# 3) 릴리스
$svArgs = @('standard-version')
if ($DryRun) { $svArgs += '--dry-run' }
$svArgs += @('--release-as', $Type)

Info "npx $($svArgs -join ' ')"
Exec $npx $svArgs

# 4) 푸시(태그 포함)
Info "Pushing commits & tags..."
git push --follow-tags origin main

# 5) 결과
$v = (node -p "require('./package.json').version")
Ok  "✅ Release completed. version=v$($v)"
Ok  "   CHANGELOG.md updated, tag=v$($('v' + $v))"
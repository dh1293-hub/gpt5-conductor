param(
  [ValidateSet("patch","minor","major")] [string]$Type = "patch",
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Warn($msg) { Write-Host $msg -ForegroundColor DarkYellow }
function Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Ok($msg)   { Write-Host $msg -ForegroundColor Green }
function Fail($msg) { Write-Host $msg -ForegroundColor Red; exit 2 }

Warn "⚠ Running release in current PowerShell session. Keep this window open."

# 0) 위치 보정
$repo = (Resolve-Path ".").Path
if (-not (Test-Path "$repo\package.json")) { Fail "Not at repo root. Abort." }

# 1) 로컬/원격 동기화 & 클린 체크
Info "Fetching remote tags..."
git fetch --all --tags --prune | Out-Null

$st = git status --porcelain
if ($st) { Fail "Working tree not clean. Commit or stash first." }

# 2) 사전 게이트(테스트)
Info "Running gates: build → smoke → contract → tests"
npm run build
if ($LASTEXITCODE -ne 0) { Fail "build failed" }

npm run run-smoke
if ($LASTEXITCODE -ne 0) { Fail "smoke failed" }

npm run run-contract
if ($LASTEXITCODE -ne 0) { Fail "contract failed" }

npm run run-tests
if ($LASTEXITCODE -ne 0) { Fail "tests failed" }

# 3) 릴리스 수행
$svArgs = @()
if ($DryRun) { $svArgs += "--dry-run" }
$svArgs += @("--release-as", $Type)

Info "standard-version $($svArgs -join ' ')"
npx --yes standard-version @svArgs
if ($LASTEXITCODE -ne 0) { Fail "standard-version failed" }

# 4) 원격 푸시(태그 포함)
Info "Pushing commits & tags..."
git push --follow-tags origin main

# 5) 결과 출력
$v = (node -p "require('./package.json').version")
Ok  "✅ Release completed. version=v$($v)"
Ok  "   CHANGELOG.md updated, tag=v$($('v' + $v))"

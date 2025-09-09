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
function ExecStr([string]$cmd){
  cmd.exe /d /c $cmd
  if ($LASTEXITCODE -ne 0) { Fail "command failed: $cmd" }
}

Warn "⚠ Running release in current PowerShell session. Keep this window open."

# 0) 위치 보정
$repo = (Resolve-Path ".").Path
if (-not (Test-Path "$repo\package.json")) { Fail "Not at repo root. Abort." }

# 1) 원격 동기화 & 클린 체크
Info "Fetching remote tags..."
git fetch --all --tags --prune | Out-Null

$st = git status --porcelain
if ($st) { Fail "Working tree not clean. Commit or stash first." }

# 2) 게이트
Info "Running gates: build → smoke → contract → tests"
ExecStr "npm run build"
ExecStr "npm run run-smoke"
ExecStr "npm run run-contract"
ExecStr "npm run run-tests"

# 3) 릴리스
$sv = "npx standard-version --release-as $Type"
if ($DryRun) { $sv += " --dry-run" }
Info $sv
ExecStr $sv

# 4) 푸시(태그 포함)
Info "Pushing commits & tags..."
git push --follow-tags origin main

# 5) 결과
$v = & node -p "require('./package.json').version"
Ok  ("✅ Release completed. version=v{0}" -f $v)
Ok  ("   CHANGELOG.md updated, tag=v{0}" -f $v)
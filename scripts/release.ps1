param(
  [ValidateSet("patch","minor","major")]
  [string]$level = "patch"
)
$ErrorActionPreference = "Stop"

function Invoke-Git {
  param(
    [Parameter(ValueFromRemainingArguments=$true, Position=0)]
    [string[]]$gitArgs
  )
  & git @gitArgs
  $code = $LASTEXITCODE
  if ($code -ne 0) { throw "git $($gitArgs -join ' ') failed (exit $code)" }
}

function Bump-Version($v, $lvl) {
  if ($v -notmatch "^v(\d+)\.(\d+)\.(\d+)$") { throw "Invalid tag format: $v" }
  $maj = [int]$Matches[1]; $min = [int]$Matches[2]; $pat = [int]$Matches[3]
  switch ($lvl) {
    "major" { $maj++; $min=0; $pat=0 }
    "minor" { $min++; $pat=0 }
    "patch" { $pat++ }
  }
  return "v$maj.$min.$pat"
}

Invoke-Git fetch --all --tags --prune

$last = (& git describe --tags --abbrev=0) 2>$null
if (-not $last) { $last = "v0.1.0" }  # 최초 기본값

$dirty = & git status --porcelain
if ($dirty) {
  Write-Host "⚠️ Working tree가 깨끗하지 않습니다. 커밋 또는 stash 후 재실행." -ForegroundColor DarkYellow
  exit 2
}

$new = Bump-Version $last $level
Write-Host "Last: $last  ->  New: $new" -ForegroundColor Cyan

Invoke-Git tag -a $new -m "release: $new"

New-Item -ItemType Directory -Force release_notes | Out-Null
& git log "$last..HEAD" --pretty=format:"- %s (%h)" |
  Out-File -Encoding utf8 "release_notes/$($new.TrimStart('v')).txt"

Invoke-Git push --follow-tags origin main

$has = (& git ls-remote --tags origin "refs/tags/$new")
if (-not $has) { throw "Remote tag 확인 실패: $new" }

Write-Host "✅ Release done: $new" -ForegroundColor Green
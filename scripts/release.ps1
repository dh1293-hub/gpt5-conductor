Param(
  [ValidateSet("patch","minor","major","pre")]
  [string]$Type = "patch",
  [string]$PreId = "rc"
)
$ErrorActionPreference = "Stop"
function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host $m -ForegroundColor DarkYellow }

# 루트 검증
$root = Resolve-Path "."
if (-not (Test-Path "$root\package.json")) { throw "package.json 미존재: 루트가 아님 → 현재: $root" }

# 브랜치/상태 검사
$branch = git rev-parse --abbrev-ref HEAD
if ($branch -ne "main") { Write-Warn "현재 브랜치: $branch (main 권장)"; }
$dirty = git status --porcelain
if ($dirty) { throw "작업트리 깨끗하지 않음. 커밋 후 다시 실행하세요." }

# 릴리스 실행
switch ($Type) {
  "pre"   { $cmd = "npm run release:pre -- --prerelease $PreId" }
  default { $cmd = "npm run release:$Type" }
}
Write-Info "실행: $cmd"
Invoke-Expression $cmd

# 태그 확인 및 푸시
$tag = git describe --tags --abbrev=0
Write-Info "생성 태그: $tag"
git push --follow-tags origin main
Write-Info "완료: $tag 푸시 완료."
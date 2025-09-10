param(
  [string]$Bump = $env:REL_BUMP_LEVEL  # patch|minor|major (선택)
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
function Assert-Cmd($n){ if(-not(Get-Command $n -ErrorAction SilentlyContinue)){ throw "필수 도구 미설치: $n" } }
Assert-Cmd git; Assert-Cmd gh; Assert-Cmd node

# 루트 고정
$ROOT = (git rev-parse --show-toplevel).Trim()
Set-Location ($ROOT -replace '/', '\')
Write-Host ("[정보] Repo root: {0}" -f (Get-Location).Path) -ForegroundColor DarkYellow

# (옵션) 버전 뱀프+태그
if ($Bump) {
  Write-Host ("[정보] standard-version --release-as {0}" -f $Bump) -ForegroundColor DarkYellow
  npx standard-version --release-as $Bump
  git push --follow-tags origin $(git rev-parse --abbrev-ref HEAD)
}

# 최신 태그 확보
git fetch --all --tags --prune | Out-Null
$tag = (git describe --tags --abbrev=0).Trim()
if ([string]::IsNullOrWhiteSpace($tag)) { throw "태그가 없습니다. (필요 시 -Bump patch|minor|major 로 태그 생성)" }
Write-Host ("[정보] 최신 태그: {0}" -f $tag) -ForegroundColor DarkYellow

# 릴리스 노트 생성(ACL)
New-Item -ItemType Directory -Force -Path .\out\release_notes | Out-Null
$notesPath = node .\scripts\acl\release-notes.mjs --tag=$tag
if (-not (Test-Path $notesPath)) { throw "노트 파일 생성 실패: $notesPath" }
Write-Host ("[정보] 노트 파일: {0}" -f $notesPath) -ForegroundColor DarkYellow

# Release 생성/갱신 (제목만)
$repoSlug = (git config --get remote.origin.url) -replace '.*github.com[:/]', '' -replace '\.git$',''
$exists = $false
try { gh release view $tag | Out-Null; $exists = $true } catch { $exists = $false }
if ($exists) {
  gh release edit $tag -t ("gpt5-conductor {0}" -f $tag) --latest | Out-Null
} else {
  gh release create $tag -t ("gpt5-conductor {0}" -f $tag) --latest --verify-tag | Out-Null
}

# 정규화 함수(동일 규칙)
function Normalize([string]$s) {
  if ($null -eq $s) { return "" }
  $t = $s -replace "`r",""
  $t = [regex]::Replace($t, "\s+$", "")
  return $t + "`n"
}

# 로컬 노트 정규화
$localN = Normalize (Get-Content $notesPath -Raw)

# 정확 PATCH(JSON UTF-8 no BOM)
$rel   = gh api "repos/$repoSlug/releases/tags/$tag" | ConvertFrom-Json
$relId = $rel.id
$tmpJson  = Join-Path $env:TEMP ("body_{0}.json" -f ($tag -replace '[^\w\.-]','_'))
$payload  = @{ body = $localN } | ConvertTo-Json -Compress
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($tmpJson, $payload, $utf8NoBom)
gh api --method PATCH `
  -H "Accept: application/vnd.github+json" `
  -H "Content-Type: application/json; charset=utf-8" `
  "repos/$repoSlug/releases/$relId" `
  --input "$tmpJson" | Out-Null

# 최종 검증(정규화 비교)
$rel2    = gh api "repos/$repoSlug/releases/tags/$tag" | ConvertFrom-Json
$remoteN = Normalize $rel2.body
if ($localN -eq $remoteN) {
  Write-Host "`nPASS ✅  Release 본문이 로컬 노트와 일치합니다." -ForegroundColor DarkYellow
} else {
  Write-Host "`nFAIL ⛔  정규화 후에도 차이 발생. gh release view $tag --web 로 수동 점검" -ForegroundColor DarkYellow
}

Write-Host ("`n완료 ✅  태그: {0}" -f $tag) -ForegroundColor DarkYellow
Write-Host ("브라우저 열기: gh release view {0} --web" -f $tag) -ForegroundColor DarkYellow
param(
  [string]$Bump = $env:REL_BUMP_LEVEL  # patch|minor|major (?좏깮)

try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding           = New-Object System.Text.UTF8Encoding($false)
$env:LC_ALL="C.UTF-8"; $env:LANG="C.UTF-8"
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
function Assert-Cmd($n){ if(-not(Get-Command $n -ErrorAction SilentlyContinue)){ throw "?꾩닔 ?꾧뎄 誘몄꽕移? $n" } }
Assert-Cmd git; Assert-Cmd gh; Assert-Cmd node

# 猷⑦듃 怨좎젙
$ROOT = (git rev-parse --show-toplevel).Trim()
Set-Location ($ROOT -replace '/', '\')
Write-Host ("[?뺣낫] Repo root: {0}" -f (Get-Location).Path) -ForegroundColor DarkYellow

# (?듭뀡) 踰꾩쟾 諭???쒓렇
if ($Bump) {
  Write-Host ("[?뺣낫] standard-version --release-as {0}" -f $Bump) -ForegroundColor DarkYellow
  npx standard-version --release-as $Bump
  git push --follow-tags origin $(git rev-parse --abbrev-ref HEAD)
}

# 理쒖떊 ?쒓렇 ?뺣낫
git fetch --all --tags --prune | Out-Null
$tag = (git describe --tags --abbrev=0).Trim()
if ([string]::IsNullOrWhiteSpace($tag)) { throw "?쒓렇媛 ?놁뒿?덈떎. (?꾩슂 ??-Bump patch|minor|major 濡??쒓렇 ?앹꽦)" }
Write-Host ("[?뺣낫] 理쒖떊 ?쒓렇: {0}" -f $tag) -ForegroundColor DarkYellow

# 由대━???명듃 ?앹꽦(ACL)
New-Item -ItemType Directory -Force -Path .\out\release_notes | Out-Null
$notesPath = node .\scripts\acl\release-notes.mjs --tag=$tag
if (-not (Test-Path $notesPath)) { throw "?명듃 ?뚯씪 ?앹꽦 ?ㅽ뙣: $notesPath" }
Write-Host ("[?뺣낫] ?명듃 ?뚯씪: {0}" -f $notesPath) -ForegroundColor DarkYellow

# Release ?앹꽦/媛깆떊 (?쒕ぉ留?
$repoSlug = (git config --get remote.origin.url) -replace '.*github.com[:/]', '' -replace '\.git$',''
$exists = $false
try { gh release view $tag | Out-Null; $exists = $true } catch { $exists = $false }
if ($exists) {
  gh release edit $tag -t ("gpt5-conductor {0}" -f $tag) --latest | Out-Null
} else {
  gh release create $tag -t ("gpt5-conductor {0}" -f $tag) --latest --verify-tag | Out-Null
}

# ?뺢퇋???⑥닔(?숈씪 洹쒖튃)
function Normalize([string]$s) {
  if ($null -eq $s) { return "" }
  $t = $s -replace "`r",""
  $t = [regex]::Replace($t, "\s+$", "")
  return $t + "`n"
}

# 濡쒖뺄 ?명듃 ?뺢퇋??$localN = Normalize (Get-Content $notesPath -Raw)

# ?뺥솗 PATCH(JSON UTF-8 no BOM)
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

# 理쒖쥌 寃利??뺢퇋??鍮꾧탳)
$rel2    = gh api "repos/$repoSlug/releases/tags/$tag" | ConvertFrom-Json
$remoteN = Normalize $rel2.body
if ($localN -eq $remoteN) {
  Write-Host "`nPASS ?? Release 蹂몃Ц??濡쒖뺄 ?명듃? ?쇱튂?⑸땲??" -ForegroundColor DarkYellow
} else {
  Write-Host "`nFAIL ?? ?뺢퇋???꾩뿉??李⑥씠 諛쒖깮. gh release view $tag --web 濡??섎룞 ?먭?" -ForegroundColor DarkYellow
}

Write-Host ("`n?꾨즺 ?? ?쒓렇: {0}" -f $tag) -ForegroundColor DarkYellow
Write-Host ("釉뚮씪?곗? ?닿린: gh release view {0} --web" -f $tag) -ForegroundColor DarkYellow
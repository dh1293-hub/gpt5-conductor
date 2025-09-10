param(
  [string]$Bump = $env:REL_BUMP_LEVEL  # patch|minor|major or empty
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding           = New-Object System.Text.UTF8Encoding($false)
$env:LC_ALL = "C.UTF-8"; $env:LANG = "C.UTF-8"

function Assert-Cmd($n){ if(-not(Get-Command $n -ErrorAction SilentlyContinue)){ throw "missing tool: $n" } }
Assert-Cmd git; Assert-Cmd gh; Assert-Cmd node

# repo root
$ROOT = (git rev-parse --show-toplevel).Trim()
Set-Location ($ROOT -replace '/', '\')
Write-Host ("[info] repo: {0}" -f (Get-Location).Path)

# optional bump & tag
if ($Bump) {
  Write-Host ("[info] standard-version --release-as {0}" -f $Bump)
  npx standard-version --release-as $Bump
  git push --follow-tags origin $(git rev-parse --abbrev-ref HEAD)
}

# ensure latest tag
git fetch --all --tags --prune | Out-Null
$tag = (git describe --tags --abbrev=0).Trim()
if ([string]::IsNullOrWhiteSpace($tag)) { throw "no tag. run with -Bump patch|minor|major to create one." }
Write-Host ("[info] tag: {0}" -f $tag)

# generate notes via ACL
New-Item -ItemType Directory -Force -Path .\out\release_notes | Out-Null
$notesPath = node .\scripts\acl\release-notes.mjs --tag=$tag
if (-not (Test-Path $notesPath)) { throw "notes not found: $notesPath" }
Write-Host ("[info] notes: {0}" -f $notesPath)

# create/edit release title
$repoSlug = (git config --get remote.origin.url) -replace '.*github.com[:/]', '' -replace '\.git$',''
$exists = $false
try { gh release view $tag | Out-Null; $exists = $true } catch { $exists = $false }
if ($exists) { gh release edit $tag -t ("gpt5-conductor {0}" -f $tag) --latest | Out-Null }
else { gh release create $tag -t ("gpt5-conductor {0}" -f $tag) --latest --verify-tag | Out-Null }

# normalize helper
function Normalize([string]$s) {
  if ($null -eq $s) { return "" }
  $t = $s -replace "`r",""
  $t = [regex]::Replace($t, "\s+$", "")
  return $t + "`n"
}

# patch release body exactly with normalized content (UTF-8 no BOM)
$localN = Normalize (Get-Content $notesPath -Raw)
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

# verify
$rel2    = gh api "repos/$repoSlug/releases/tags/$tag" | ConvertFrom-Json
$remoteN = Normalize $rel2.body
if ($localN -eq $remoteN) {
  Write-Host "`nPASS release body equals notes."
} else {
  Write-Host "`nFAIL release body differs; open web to check: gh release view $tag --web"
}

Write-Host ("`nDONE tag: {0}" -f $tag)
Write-Host ("open: gh release view {0} --web" -f $tag)
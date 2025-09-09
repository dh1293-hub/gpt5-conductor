<# PS-17.1 (v1) — publish-release.ps1
  목적: 최신 태그의 CHANGELOG 섹션을 읽어 GitHub Release 생성/갱신
  사용:
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\publish-release.ps1 -DryRun
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\publish-release.ps1
    .\scripts\publish-release.ps1 -DryRun   # 같은 셸에서 실행도 가능
  요구:
    - 환경변수 GITHUB_TOKEN (repo 권한)
    - git (origin이 GitHub)
#>

param(
  [switch]$DryRun,
  [string]$Repo,
  [string]$Token
)

$ErrorActionPreference = 'Stop'
$logDir = "logs"
$logPath = Join-Path $logDir "release.log"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

function Say([string]$msg, [string]$level = "INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "$ts [$level] $msg"
  Write-Host $line
  Add-Content -Path $logPath -Value $line
}
function Warn([string]$msg) {
  Write-Host $msg -ForegroundColor DarkYellow
  Say $msg "WARN"
}
function Fail([string]$msg) {
  Write-Host $msg -ForegroundColor Red
  Say $msg "ERROR"
  exit 1
}

# 1) 토큰
$Token = if ($Token) { $Token } elseif ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { "" }
if (-not $Token -and -not $DryRun) {
  Fail "GITHUB_TOKEN이 없습니다. 환경변수로 설정 후 재시도하세요."
} elseif (-not $Token -and $DryRun) {
  Warn "[DryRun] 토큰 없음 — API를 호출하지 않습니다."
}

# 2) 레포(owner/repo) 결정
function Get-RepoFromGit {
  try {
    $url = (git remote get-url origin).Trim()
  } catch {
    return $null
  }
  if ($url -match "github\.com[:/](?<owner>[^/]+)/(?<name>[^\.]+)(\.git)?$") {
    return "$($Matches.owner)/$($Matches.name)"
  }
  return $null
}
if (-not $Repo) { $Repo = Get-RepoFromGit }
if (-not $Repo) { Fail "origin에서 GitHub 레포를 유추 못했습니다. -Repo owner/name 으로 지정하세요." }

Say "Repo       : $Repo"
Say "DryRun     : $DryRun"

# 3) 태그 결정
function Get-Tag {
  $headTags = git tag --points-at HEAD | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' }
  if ($headTags) {
    return ($headTags | Sort-Object -Descending | Select-Object -First 1).Trim()
  }
  return (git describe --tags --abbrev=0).Trim()
}
$tag = Get-Tag
if (-not $tag) { Fail "버전 태그를 찾지 못했습니다. 먼저 vX.Y.Z 태그를 생성하세요." }
Say "Tag        : $tag"

# 4) CHANGELOG 섹션 추출
$changelogPath = "CHANGELOG.md"
if (!(Test-Path $changelogPath)) { Fail "CHANGELOG.md가 없습니다." }
$cl = Get-Content $changelogPath -Raw

$ver = $tag.TrimStart('v')
$pattern = "(?ms)^##\s*(?:\[$ver\]|$ver)\b.*?(?=^##\s*|\Z)"
$match = [regex]::Match($cl, $pattern)
if (-not $match.Success) {
  Fail "CHANGELOG에서 버전 $ver 섹션을 찾지 못했습니다."
}
$body = $match.Value.Trim()
if ($body -match '^\s*$') { Fail "추출된 릴리스 노트가 비어 있습니다." }

Say "Changelog  : 섹션 길이 $($body.Length)자"

# 5) GitHub API (Release 존재시 PATCH, 없으면 POST)
$api = "https://api.github.com"
$headers = @{
  "Accept"        = "application/vnd.github+json"
  "User-Agent"    = "release-notes-script"
}
if (-not $DryRun) { $headers["Authorization"] = "Bearer $Token" }

if ($DryRun) {
  Warn "[DryRun] 아래 내용으로 릴리스가 생성/갱신됩니다:"
  Write-Host "---- name ----" -ForegroundColor DarkYellow
  Write-Host $tag
  Write-Host "---- body (preview) ----" -ForegroundColor DarkYellow
  Write-Host $body
  exit 0
}

# 기존 릴리스 조회
$release = $null
try {
  $release = Invoke-RestMethod -Method GET -Headers $headers -Uri "$api/repos/$Repo/releases/tags/$tag"
  Say "Existing   : release_id=$($release.id)"
} catch {
  Say "Existing   : 없음(생성 예정)"
}

if ($release) {
  $payload = @{
    name = $tag
    body = $body
  } | ConvertTo-Json -Depth 5
  $res = Invoke-RestMethod -Method PATCH -Headers $headers -ContentType "application/json" `
          -Uri "$api/repos/$Repo/releases/$($release.id)" -Body $payload
  Say "Updated    : $($res.html_url)"
  Write-Host "GitHub Release 갱신 완료: $($res.html_url)" -ForegroundColor Green
} else {
  $payload = @{
    tag_name   = $tag
    name       = $tag
    body       = $body
    draft      = $false
    prerelease = $false
  } | ConvertTo-Json -Depth 5
  $res = Invoke-RestMethod -Method POST -Headers $headers -ContentType "application/json" `
          -Uri "$api/repos/$Repo/releases" -Body $payload
  Say "Created    : $($res.html_url)"
  Write-Host "GitHub Release 생성 완료: $($res.html_url)" -ForegroundColor Green
}

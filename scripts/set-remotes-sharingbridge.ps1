# Sets origin to https://github.com/sharingbridge/<slug>.git for each sibling
# directory under $Root that contains a .git folder.
#
# Slug rule: if the folder name starts with "sharebridge", replace that prefix
# with "sharingbridge" (matches GitHub renames while local folders may still
# use the old names). Otherwise the folder basename is the slug.
#
# Skips "demo-repository" by default (leave origin unchanged).
#
# Usage: pwsh ./scripts/set-remotes-sharingbridge.ps1
# Optional: -Root "D:\path\to\parent-of-repos"

param(
  # Default: parent of the docs repo clone (…/sharebridge_repos when layout is …/sharebridge_repos/sharebridge/scripts).
  [string] $Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

Get-ChildItem -LiteralPath $Root -Directory -ErrorAction Stop | ForEach-Object {
  $dir = $_.FullName
  if (-not (Test-Path (Join-Path $dir ".git"))) {
    return
  }
  $folder = $_.Name
  if ($folder -eq "demo-repository") {
    Write-Host "SKIP demo-repository"
    return
  }
  $slug = $folder -replace "^sharebridge", "sharingbridge"
  $url = "https://github.com/sharingbridge/$slug.git"
  git -C $dir remote set-url origin $url
  Write-Host "OK $folder -> $url"
}

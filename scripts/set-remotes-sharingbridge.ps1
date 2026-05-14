# Sets origin to https://github.com/sharingbridge/<slug>.git for each sibling
# directory under $Root that contains a .git folder.
#
# Slug rule: if the folder name uses the legacy 11-char prefix (letters:
# s h a r e b r i d g e) before "-mobile-app", "-integration-service", etc.,
# rewrite it to the current GitHub prefix "sharingbridge". Folders already
# named "sharingbridge-*" are unchanged.
#
# Skips "demo-repository" by default (leave origin unchanged).
#
# Usage: pwsh ./scripts/set-remotes-sharingbridge.ps1
# Optional: -Root "D:\path\to\parent-of-repos"

param(
  # Default: parent of the coordination repo clone (e.g. …/sharingbridge/sharingbridge/scripts → …/sharingbridge).
  [string] $Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$legacyPrefix = -join @(
  [char]115, [char]104, [char]97, [char]114, [char]101,
  [char]98, [char]114, [char]105, [char]100, [char]103, [char]101
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
  $slug = $folder -replace "^$legacyPrefix", "sharingbridge"
  $url = "https://github.com/sharingbridge/$slug.git"
  git -C $dir remote set-url origin $url
  Write-Host "OK $folder -> $url"
}

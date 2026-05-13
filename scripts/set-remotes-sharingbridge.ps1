# Sets origin to https://github.com/sharingbridge/<folder-basename>.git for each
# sibling directory under $Root that contains a .git folder.
# Usage: pwsh ./scripts/set-remotes-sharingbridge.ps1
# Optional: -Root "D:\path\to\parent-of-repos"

param(
  [string] $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

Get-ChildItem -LiteralPath $Root -Directory -ErrorAction Stop | ForEach-Object {
  $dir = $_.FullName
  if (-not (Test-Path (Join-Path $dir ".git"))) {
    return
  }
  $slug = $_.Name
  $url = "https://github.com/sharingbridge/$slug.git"
  git -C $dir remote set-url origin $url
  Write-Host "OK $slug -> $url"
}

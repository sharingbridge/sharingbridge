# GitHub organization and repository names (`sharingbridge`)

The GitHub organization is **`sharingbridge`** (`https://github.com/sharingbridge`). Each clone’s `origin` must use that host.

## 1. Point `origin` at the new organization (same repo slug)

If the repository slug on GitHub is still `sharebridge-*` (only the org moved), set the org segment only:

```powershell
$root = "D:\kannan\sharebridge_repos"   # adjust
Get-ChildItem $root -Directory | ForEach-Object {
  if (Test-Path (Join-Path $_.FullName ".git")) {
    $url = git -C $_.FullName remote get-url origin
    if ($url -match "github\.com/sharebridge/") {
      $new = $url -replace "github\.com/sharebridge/", "github.com/sharingbridge/"
      git -C $_.FullName remote set-url origin $new
      Write-Host "Updated $($_.Name)"
    }
  }
}
```

## 2. Rename repositories on GitHub (optional but recommended)

In each repo: **Settings → General → Repository name**.

Use the same slug you want locally (see table). GitHub keeps redirects from the old name for a period, but update links and remotes explicitly when you can.

| Slug before | Slug after (example) |
|-------------|----------------------|
| `sharebridge` | `sharingbridge` |
| `sharebridge-integration-service` | `sharingbridge-integration-service` |
| `sharebridge-user-service` | `sharingbridge-user-service` |
| `sharebridge-mobile-app` | `sharingbridge-mobile-app` |
| `sharebridge-api-gateway` | `sharingbridge-api-gateway` |
| `sharebridge-order-service` | `sharingbridge-order-service` |
| `sharebridge-notification-service` | `sharingbridge-notification-service` |
| `sharebridge-ai-safety` | `sharingbridge-ai-safety` |
| `sharebridge-photo-service` | `sharingbridge-photo-service` |
| `sharebridge-web-app` | `sharingbridge-web-app` |
| `sharebridge-infra` | `sharingbridge-infra` |
| `sharebridge-deployment` | `sharingbridge-deployment` |

Rule: replace the leading `sharebridge` segment with `sharingbridge` (so `sharebridge` → `sharingbridge`, and `sharebridge-foo` → `sharingbridge-foo`).

## 3. Match `origin` to the new slug after GitHub rename

When the GitHub slug matches the folder name `FOLDER`:

```powershell
git remote set-url origin "https://github.com/sharingbridge/<FOLDER>.git"
```

Or run from the parent of all clones:

```powershell
$root = "D:\kannan\sharebridge_repos"   # adjust
Get-ChildItem $root -Directory | ForEach-Object {
  if (Test-Path (Join-Path $_.FullName ".git")) {
    $slug = $_.Name
    git -C $_.FullName remote set-url origin "https://github.com/sharingbridge/$slug.git"
    Write-Host "origin -> sharingbridge/$slug"
  }
}
```

This only works when **local directory name** equals **GitHub repository slug**.

You can also run `scripts/set-remotes-sharingbridge.ps1` from the docs repo clone (pass `-Root` to the parent folder that contains all repositories).

## 4. Rename local folders to match (run outside Cursor if needed)

Close editors and terminals that have those directories open, then:

```powershell
$root = "D:\kannan\sharebridge_repos"   # adjust
Get-ChildItem $root -Directory | Where-Object { $_.Name -match "^sharebridge" } | ForEach-Object {
  $newName = $_.Name -replace "^sharebridge", "sharingbridge"
  $dest = Join-Path $root $newName
  if (-not (Test-Path $dest)) {
    Rename-Item -LiteralPath $_.FullName -NewName $newName
    Write-Host "Renamed $($_.Name) -> $newName"
  }
}
```

Then reopen the workspace (or add the new paths). Re-run section 3 so `origin` matches the new folder names.

## 5. Follow-up elsewhere

- **CI / Actions**: any checkout URL or `GITHUB_REPOSITORY` assumptions.
- **Docs and proposals**: replace `github.com/sharebridge/` with `github.com/sharingbridge/` and update the **repo slug** segment after each rename.
- **Flutter / npm package names** (`sharebridge_mobile_app`, etc.) are independent; changing them is a separate, larger change.

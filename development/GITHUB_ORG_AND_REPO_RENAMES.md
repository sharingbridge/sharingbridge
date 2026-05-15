# GitHub organization and repository names (`sharingbridge`)

The GitHub organization is **`sharingbridge`** (`https://github.com/sharingbridge`). Each clone’s `origin` must use that host.

This file is the **migration playbook** for Git remotes and local folder layout under the **`sharingbridge`** GitHub organization.

## 1. Point `origin` at the new organization (same repository slug)

If repositories stayed the same and **only the organization** moved, swap the org segment in `origin`:

```powershell
$root = "D:\kannan\sharingbridge"   # adjust — parent folder that contains all clones
$oldOrg = "share" + "bridge"            # legacy GitHub org slug (single word)
Get-ChildItem $root -Directory | ForEach-Object {
  if (Test-Path (Join-Path $_.FullName ".git")) {
    $url = git -C $_.FullName remote get-url origin
    if ($url -match "github\.com/$oldOrg/") {
      $new = $url -replace "github\.com/$oldOrg/", "github.com/sharingbridge/"
      git -C $_.FullName remote set-url origin $new
      Write-Host "Updated $($_.Name)"
    }
  }
}
```

## 2. Canonical repository slugs (under org `sharingbridge`)

Use these names on GitHub and in local clone folders so `origin` URLs stay predictable (`https://github.com/sharingbridge/<slug>.git`):

| Role | Slug |
|------|------|
| Coordination / documentation | `sharingbridge` |
| Integration (donor setup API) | `sharingbridge-integration-service` |
| User service (auth + donor presets) | `sharingbridge-user-service` |
| Mobile app | `sharingbridge-mobile-app` |
| Web app | `sharingbridge-web-app` |
| API gateway | `sharingbridge-api-gateway` |
| Order service | `sharingbridge-order-service` |
| Notifications | `sharingbridge-notification-service` |
| Location safety (rule-based geo; not LLM) | `sharingbridge-location-safety` |
| Photo service | `sharingbridge-photo-service` |
| Infra | `sharingbridge-infra` |
| Deployment | `sharingbridge-deployment` |

If you renamed an organization or repository earlier, GitHub may still redirect old URLs for a while—update `origin` and bookmarks to the canonical URLs above.

## 3. Match `origin` to the new GitHub slug after repository rename

GitHub slugs are now `sharingbridge` or `sharingbridge-*`. Local directories may still use legacy names until you rename them (§4). **`git` only cares about `origin` URL**—point it at the slug GitHub shows for that repo.

Skip **`demo-repository`** if that clone still tracks an unchanged slug.

```powershell
$root = "D:\kannan\sharingbridge"   # adjust
$legacy = "share" + "bridge"            # legacy repo slug prefix (single word)
Get-ChildItem $root -Directory | ForEach-Object {
  if (-not (Test-Path (Join-Path $_.FullName ".git"))) { return }
  $folder = $_.Name
  if ($folder -eq "demo-repository") {
    Write-Host "SKIP demo-repository (leave origin as-is unless you rename it on GitHub)"
    return
  }
  $slug = $folder -replace "^$legacy", "sharingbridge"
  $url = "https://github.com/sharingbridge/$slug.git"
  git -C $_.FullName remote set-url origin $url
  git -C $_.FullName fetch origin
  Write-Host "OK $folder -> $url"
}
```

### When local folder name already matches GitHub

```powershell
$root = "D:\kannan\sharingbridge"   # adjust
Get-ChildItem $root -Directory | ForEach-Object {
  if (Test-Path (Join-Path $_.FullName ".git")) {
    $slug = $_.Name
    git -C $_.FullName remote set-url origin "https://github.com/sharingbridge/$slug.git"
    Write-Host "origin -> sharingbridge/$slug"
  }
}
```

You can also run `scripts/set-remotes-sharingbridge.ps1` from the coordination repo clone (default `-Root` is the parent of that clone; pass `-Root` explicitly if your layout differs).

## 4. Rename local folders to match (run outside Cursor if needed)

Close editors and terminals that have those directories open, then:

```powershell
$root = "D:\kannan\sharingbridge"   # adjust
$legacy = "share" + "bridge"
Get-ChildItem $root -Directory | Where-Object { $_.Name -match "^$legacy" } | ForEach-Object {
  $newName = $_.Name -replace "^$legacy", "sharingbridge"
  $dest = Join-Path $root $newName
  if (-not (Test-Path $dest)) {
    Rename-Item -LiteralPath $_.FullName -NewName $newName
    Write-Host "Renamed $($_.Name) -> $newName"
  }
}
```

Then reopen the workspace. If you already ran §3 with the prefix mapping, **`origin` is usually still correct** after renames.

## 5. Rename `sharingbridge-ai-safety` → `sharingbridge-location-safety`

The old slug implied LLM/“AI stack”; the service is **rule-based locality safety** (maps, places, daylight, history). Renaming avoids confusion with `sharingbridge-ai-orchestration`.

**On GitHub (you):** Repository **Settings → General → Repository name** → `sharingbridge-location-safety`. GitHub redirects the old URL for a while.

**Local clone (after GitHub rename):**

```powershell
$root = "D:\kannan\sharingbridge"   # adjust
$old = Join-Path $root "sharingbridge-ai-safety"
$new = Join-Path $root "sharingbridge-location-safety"
if (Test-Path $old) {
  Rename-Item -LiteralPath $old -NewName "sharingbridge-location-safety"
}
if (Test-Path $new) {
  git -C $new remote set-url origin https://github.com/sharingbridge/sharingbridge-location-safety.git
  git -C $new fetch origin
}
```

Coordination docs in `sharingbridge/sharingbridge` use the new slug only.

## 6. Follow-up elsewhere

- **CI / Actions**: any checkout URL or `GITHUB_REPOSITORY` assumptions.
- **Docs and proposals**: update any remaining hard-coded GitHub URLs to `https://github.com/sharingbridge/...`.
- **Flutter / npm package names** (`sharingbridge_mobile_app` in docs as the target identifier; align `pubspec.yaml` / `package.json` in app repos in a coordinated change).

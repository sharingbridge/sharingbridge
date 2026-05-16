# Authentication and service credentials

SharingBridge MVP uses **two separate secrets**. They must not be confused.

## Donor JWT (`AUTH_TOKEN_SECRET`)

| | |
|--|--|
| **Purpose** | Identify the donor on integration-service APIs |
| **Set on** | `sharingbridge-user-service`, `sharingbridge-integration-service` |
| **Same value on both** | Yes |
| **Expires** | Yes — JWT `exp` (default 1 hour via `AUTH_TOKEN_TTL_SECONDS`) |
| **Not used on** | `sharingbridge-ai-orchestration` |

**Flow**

1. Client calls `POST /v1/auth/token` on **user-service** with `{"user_id":"…"}`.
2. user-service signs a JWT (HS256) with `AUTH_TOKEN_SECRET`.
3. Client calls **integration-service** with `Authorization: Bearer <jwt>`.

**Render env (user-service and integration)**

| Key | Typical value |
|-----|----------------|
| `AUTH_TOKEN_SECRET` | long random string (generate once, copy to both) |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` |

Generate (PowerShell):

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

**Not in MVP:** OAuth2, Google/Apple sign-in, or federated IdP. Those would replace this stub in a later phase.

---

## Internal service API key (`AI_ORCHESTRATION_INTERNAL_API_KEY`)

| | |
|--|--|
| **Purpose** | integration-service → ai-orchestration only |
| **Set on** | `sharingbridge-ai-orchestration`, `sharingbridge-integration-service` |
| **Same value on both** | Yes |
| **Expires** | No — rotate manually on both services |
| **HTTP header** | `X-Internal-Api-Key` |
| **Not used on** | mobile app, user-service |

Use a **different** random string than `AUTH_TOKEN_SECRET`.

If unset on ai-orchestration, internal LLM routes allow unauthenticated calls (local dev only). **Always set on Render.**

---

## Summary

| Credential | Mobile sees it? | Expires? |
|------------|-----------------|----------|
| JWT (via `AUTH_TOKEN_SECRET`) | Yes (Bearer token) | Yes |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | No | No |

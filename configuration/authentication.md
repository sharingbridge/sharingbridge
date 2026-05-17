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

**Identity on integration-service**

- The JWT subject (`sub` / donor `user_id`) is the authenticated user.
- Clients may omit `user_id` in JSON bodies and query strings when sending a valid Bearer token (mobile and web do this).
- If both Bearer and `user_id` are sent, they **must match** or integration returns HTTP **403** `user_id_mismatch`.

**Clients**

| Client | How it gets a JWT |
|--------|-------------------|
| Mobile | Mint before `flutter run`; pass `--dart-define=AUTH_TOKEN=…` — see [mobile-client.md](./mobile-client.md) |
| Web dashboard | In-app sign-in → user-service `POST /v1/auth/token` — see [web-client.md](./web-client.md) |

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

### Browser clients (CORS, not a third secret)

Web sign-in and dashboard API calls require **`WEB_CORS_ORIGINS`** on **both** user-service and integration-service (comma-separated origins). This is separate from `AUTH_TOKEN_SECRET`. See [web-client.md](./web-client.md) and [backend-render.md](./backend-render.md).

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

| Credential / setting | Mobile | Web | Expires? |
|----------------------|--------|-----|----------|
| JWT (via `AUTH_TOKEN_SECRET`) | Bearer in `AUTH_TOKEN` | Bearer in sessionStorage | Yes |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | No | No | No (rotate manually) |
| `WEB_CORS_ORIGINS` | N/A | Required on both backends | N/A |

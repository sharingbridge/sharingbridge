# Vendor preset setup — AI search sequence

> **API (legacy path):** `POST /v1/donor-setup/suggest-vendors` · **Product term:** vendor preset setup.

This sequence defines the MVP flow for AI-assisted vendor preset setup:

- User enters free-text (restaurant/app/menu hints)
- App requests location (or asks user if permission is missing)
- API enriches prompt and calls external AI
- Top 5 suggestions are returned as validated JSON
- User confirms one or more entries
- App saves confirmed presets as deep links/menu templates

```mermaid
sequenceDiagram
    autonumber
    participant U as Initiator
    participant A as Flutter App
    participant G as API Gateway
    participant I as Integration API
    participant X as External AI API
    participant S as User/Prefs Store

    U->>A: Enter free-text (app + restaurant + menu) and tap Search
    A->>A: Check location permission
    alt Permission granted
        A->>A: Read geolocation
    else Permission not granted
        A->>U: Prompt for location permission
        alt User grants
            A->>A: Read geolocation
        else User denies
            A->>U: Ask area manually / show fallback
        end
    end

    A->>G: POST /v1/donor-setup/suggest-vendors (query + location)
    G->>I: Forward request with request-id + auth context
    I->>I: Build enhanced fixed prompt
    I->>X: Call external AI endpoint (prompt + schema hint)
    X-->>I: Top 5 suggestions JSON
    I->>I: Validate schema, sanitize, rank
    I-->>G: Curated top 5 + confidence + fallback hints
    G-->>A: Response payload

    A->>U: Show suggestions + Open URL + Confirm
    U->>A: Confirm one or more suggestions
    A->>G: POST /v1/donor-setup/preferences (confirmed presets)
    G->>S: Persist confirmed deep-link/menu presets
    S-->>G: Saved
    G-->>A: Success
    A-->>U: Presets frozen and ready for donor-seeker interaction flow
```

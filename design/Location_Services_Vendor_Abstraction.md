# Location services — vendor strategy and abstraction seams

**Status:** Approved (June 2026). **Shipped:** one vendor per capability; thin adapter boundaries documented for future swaps.

**Reading sequence:** [README.md § Natural reading order](../README.md#documentation-guide) steps **10 → 13**. Read [field-handoff.md](../configuration/field-handoff.md) first (handover in the user journey), then this doc (strategy), then [Handover_Location_Map_Picker.md](./Handover_Location_Map_Picker.md) (shipped UX), then [mobile-client.md § Handover](../configuration/mobile-client.md#handover-location--map-picker-address-pickup-note) (device setup).

**Doc map:** [Handover_Location_Map_Picker.md](./Handover_Location_Map_Picker.md) · [mobile-client.md](../configuration/mobile-client.md) · [environment-variables.md](../configuration/environment-variables.md)

---

## Decision

SharingBridge ships **one vendor per location capability** in v1, with **thin abstraction seams** so a later vendor swap touches **adapters only**, not initiation flows, menu logic, or persistence.

| Principle | Meaning |
|-----------|---------|
| **One app globally** | Same mobile binary for all regions (cab-app norm). Regional differences via **server config** and **remote flags** when needed — not separate APKs per country unless a market forces it (e.g. China-local SDKs). |
| **One vendor per service today** | Map tiles: **Google** (optional). Reverse geocode + postal bucket: **Nominatim** on integration-service. |
| **Canonical handover data** | Persist **`location_lat`**, **`location_lng`**, **`location_label`** (+ server-derived **`locality_key`**). Never tie business logic to a map vendor’s address object. |
| **Geocoding on server** | Mobile and web call **integration-service** only — not Google Geocoding, Mapbox, or Nominatim directly. |
| **Minimal branching in v1** | No multi-vendor plugin framework; reserve env keys and keep vendor code behind narrow interfaces. |

---

## Capability split (as-built)

```text
┌─────────────────────────────────────────────────────────────┐
│  Mobile initiation UI                                        │
│  HandoverLocationPicker (entry — vendor-agnostic)            │
│    ├── HandoverLocationMapPicker  → google_maps_flutter      │
│    └── HandoverLocationConfirmCard → form fallback (no SDK)  │
│  HttpGeocodeClient → GET /v1/geocode/reverse                 │
└───────────────────────────┬─────────────────────────────────┘
                            │ stable JSON contract
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  integration-service                                         │
│  geocodeApi.js (response shape)                              │
│  postalGeocode.js (Nominatim adapter — vendor-specific)    │
└─────────────────────────────────────────────────────────────┘
```

| Capability | v1 vendor | Client contract | Adapter module (swap point) |
|------------|-----------|-----------------|----------------------------|
| **Map tiles / pan-pin UX** | Google Maps SDK (`google_maps_flutter`) | `HandoverLocationPicker` → centre lat/lng + pickup note | `handover_location_map_picker.dart` |
| **Reverse geocode** | Nominatim (OSM) | `GET /v1/geocode/reverse` | `postalGeocode.js` |
| **Postal bucket** | Derived from geocoder | `locality_key` in same API | `formatLocalityKeyFromNominatim` (+ per-country formatters later) |
| **Device position** | `geolocator` | GPS lat/lng | Standard Flutter plugin |

**Google Maps is tiles only.** Address text and `locality_key` use the **Nominatim path** on integration-service — no Google Geocoding bill in v1.

---

## Abstraction boundaries (do not leak vendors)

### Mobile — map picker

**Pages import only** `HandoverLocationPicker`. They must not import `google_maps_flutter` or vendor lat/lng types.

The map widget exposes only:

- centre `location_lat` / `location_lng`
- `onLocationChanged(HandoverLocation)`
- optional “use current location” / refresh GPS
- pickup note → `location_label`

Vendor types (`LatLng`, `GoogleMapController`) stay inside `handover_location_map_picker.dart`.

### Mobile — geocode

**Widgets import only** `HttpGeocodeClient`. No direct calls to `/v1/geocode/reverse` URLs outside that class.

### Server — geocoder

Route handlers and `geocodeApi.js` depend on a single shape:

```js
// reverseGeocodeLocation(lat, lng) →
//   { location_lat, location_lng, formatted_address, locality_key } | null
```

Nominatim request/response parsing lives in `postalGeocode.js` only. A second vendor = new module + env switch — not changes to order-intent or menu routes.

### Persistence

`order_intents`, `seeker_demands`, and list filters use **coordinates + `locality_key`**. `formatted_address` is display-only today (not stored separately).

---

## Configuration (v1 and reserved)

| Key | Where | v1 behaviour | Future |
|-----|-------|--------------|--------|
| `GOOGLE_MAPS_API_KEY` | `android/local.properties` only | Native Maps SDK (manifest); Gradle auto-sets `HANDOVER_MAP_ENABLED=true` when non-empty |
| `HANDOVER_MAP_ENABLED` | `true` / `false` via `--dart-define` (optional) | Compile-time map picker vs form; **auto `true`** when `GOOGLE_MAPS_API_KEY` is in `local.properties` |
| `MAP_TILE_PROVIDER` | *(reserved)* | **Not implemented** — implicit `google` when `GOOGLE_MAPS_API_KEY` is set | `google` \| `osm` \| `mapbox` |
| `NOMINATIM_USER_AGENT` | integration-service `.env` | Required OSM identification string | Unchanged when Nominatim stays default |
| `GEOCODER_PROVIDER` | integration-service `.env` | **Not implemented** — implicit `nominatim` | `nominatim` \| `google` \| regional adapters |

Full tables: [environment-variables.md](../configuration/environment-variables.md).

**Not runtime remote config yet.** v1 uses compile-time map gating and a single server geocoder. Cab-app scale pattern (one binary + server/remote provider hints) is the target when a second region or vendor is needed.

---

## Fallback chain

```text
Map tiles (Google key configured)
  → form + GPS (HandoverLocationConfirmCard)
```

Geocode failure on server → `502 reverse_geocode_unavailable`; mobile shows error on address line; coordinates and pickup note remain editable.

Future optional middle tier: OSM/MapLibre tiles when Google unavailable — same `HandoverLocationPicker` contract, new adapter file.

---

## Swapping a vendor later (expected diff size)

| Change | Touch |
|--------|-------|
| **Geocoder** (e.g. Google Geocoding behind integration) | New `postalGeocode-*.js` adapter; `GEOCODER_PROVIDER`; per-country `locality_key` formatter; **no mobile change** if `/v1/geocode/reverse` shape is stable |
| **Map tiles** (e.g. MapLibre/OSM) | New `handover_location_*_map_picker.dart`; `MAP_TILE_PROVIDER`; **no page changes** if picker contract is stable |
| **Regional walled garden** (e.g. China) | Separate build flavor only if SDK/policy requires it — exception, not default |

---

## What we explicitly avoid in v1

- Heavy multi-provider map framework or runtime plugin registry
- Google Geocoding on mobile for convenience
- Vendor JSON (`address_components`, Nominatim `display_name`) in domain models or Postgres columns
- Separate regional APKs for India vs US (same Google + Nominatim stack)

---

## Related docs

| Topic | Document |
|-------|----------|
| Map picker UX, API, eco menu behaviour | [Handover_Location_Map_Picker.md](./Handover_Location_Map_Picker.md) |
| Mobile setup, GPS vs label | [mobile-client.md](../configuration/mobile-client.md) |
| `locality_key`, PostGIS | [database.md](../configuration/database.md) |
| Direct order capture | [field-handoff.md](../configuration/field-handoff.md) |
| Coordinator map tab (web) | [web-client.md](../configuration/web-client.md) (`VITE_GOOGLE_MAPS_API_KEY`) |

---

## Future (not shipped)

- `GET /v1/client-config` — `map_tile_provider`, optional keys/hints per deployment
- Places autocomplete (Google Places or Mapbox) behind server or adapter
- iOS Maps SDK wiring
- Persist `formatted_address` on `seeker_demands` / `order_intents`
- Per-country geocoder routing (coordinates → country → adapter)

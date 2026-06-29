# Handover location map picker

**Status:** Shipped (June 2026) — map UI when `GOOGLE_MAPS_API_KEY` is in `android/local.properties`; form fallback otherwise.

**Reading sequence:** [README.md § Natural reading order](../README.md#documentation-guide) — step **12** (after [field-handoff.md](../configuration/field-handoff.md) step 10 and [Location_Services_Vendor_Abstraction.md](./Location_Services_Vendor_Abstraction.md) step 11). **Next:** [mobile-client.md § Handover](../configuration/mobile-client.md#handover-location--map-picker-address-pickup-note) step 13.

**Doc map:** [Location_Services_Vendor_Abstraction.md](./Location_Services_Vendor_Abstraction.md) · [mobile-client.md](../configuration/mobile-client.md) · [Eco_Kitchen_Initiation_Flow.md](./Eco_Kitchen_Initiation_Flow.md)

---

## Vendor strategy

**One vendor per capability in v1** (Google map tiles + Nominatim geocode on integration-service), with **thin adapter seams** so later swaps need minimal code changes. Full decision record: [Location_Services_Vendor_Abstraction.md](./Location_Services_Vendor_Abstraction.md).

- **Mobile pages** depend only on `HandoverLocationPicker` and `HttpGeocodeClient` — not on `google_maps_flutter` or Nominatim.
- **Server** exposes stable `GET /v1/geocode/reverse`; Nominatim parsing stays in `postalGeocode.js`.
- **One global app build**; regional provider differences are a **server/remote-config** concern when needed, not separate APKs per country by default.

---

## Goal

Cab-app style location pick for all initiation routes:

- Pan/zoom map with a **fixed center pin**
- **Address** from server reverse geocode (read-only)
- **Pickup note** (landmark / gate) — user-editable → `location_label`
- **Postal area** (`locality_key`) — server-derived, read-only
- Raw lat/lng hidden from normal UX

---

## Architecture

| Layer | Responsibility |
|-------|----------------|
| **Mobile** `google_maps_flutter` | Map display, camera / pin UX |
| **Mobile** `geolocator` | Device GPS for “Use current location” |
| **integration-service** `GET /v1/geocode/reverse` | Nominatim reverse geocode → `formatted_address` + `locality_key` |
| **integration-service** `GET /v1/standard-offers` | Menu catalog for coordinates (eco kitchen) |

Google Maps API is used for **tiles only**. Address text and postal buckets use the **same Nominatim path** as the rest of the platform (no separate Google Geocoding bill unless added later).

---

## API

```http
GET /v1/geocode/reverse?location_lat=12.94&location_lng=80.24
Authorization: Bearer <initiator JWT>
```

**200**

```json
{
  "user_id": "…",
  "location_lat": 12.94,
  "location_lng": 80.24,
  "formatted_address": "…",
  "locality_key": "IN:TN:600115"
}
```

**Errors:** `401` missing auth · `400` invalid coordinates · `502` geocoder unavailable

---

## Mobile build setup (Android)

1. [Google Cloud Console](https://console.cloud.google.com/): enable **Maps SDK for Android**.
2. Create an API key; restrict by package `app.sharingbridge` + debug/release SHA-1.
3. Add to `android/local.properties` (not committed):

   ```properties
   GOOGLE_MAPS_API_KEY=AIza…
   ```

4. Pass **`--dart-define=HANDOVER_MAP_ENABLED=true`** on `flutter run` / `flutter build apk` (map UI). Gradle may auto-add `true` when the key is set and you omit the flag; explicit `true` is recommended.

   ```powershell
   flutter run -d <device> `
     --dart-define=HANDOVER_MAP_ENABLED=true `
     --dart-define=API_BASE_URL=… `
     …
   ```

Optional: `--dart-define=HANDOVER_MAP_ENABLED=false` forces the form fallback.

Without **`HANDOVER_MAP_ENABLED=true`** (and without Gradle auto-inject), the app uses the **form fallback** (`HandoverLocationConfirmCard`) even if a key is present.

---

## Flutter widgets

| Widget | When |
|--------|------|
| `HandoverLocationPicker` | Entry — map when `HANDOVER_MAP_ENABLED=true` (+ native key for tiles); else form |
| `HandoverLocationMapPicker` | Map + address + pickup note |
| `HandoverLocationConfirmCard` | Fallback without map flag / without native key |

Used in **Record seeker demand** (eco kitchen) and **Help a seeker** (direct order).

---

## Eco kitchen menu behaviour

| Action | Menu |
|--------|------|
| Refresh GPS / Use current location | Auto-reload menu |
| Manual coordinate edit (form fallback) | Clears menu; **Reload menu for updated coordinates** |
| Map pan | Debounced reverse geocode; eco flow reloads menu when GPS refresh path runs |

---

## Future

See also [Location_Services_Vendor_Abstraction.md § Future](./Location_Services_Vendor_Abstraction.md#future-not-shipped).

- `GEOCODER_PROVIDER` / `MAP_TILE_PROVIDER` env switches (adapters only; stable client contracts)
- `GET /v1/client-config` for deployment-level map hints
- Places autocomplete (Google Places or Mapbox)
- iOS Maps SDK key in `AppDelegate`
- Optional `formatted_address` persisted on `seeker_demands` / `order_intents`

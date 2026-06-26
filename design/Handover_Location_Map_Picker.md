# Handover location map picker

**Status:** Shipped (June 2026) — map UI when `GOOGLE_MAPS_API_KEY` is configured; form fallback otherwise.

**Doc map:** [mobile-client.md](../configuration/mobile-client.md) · [Eco_Kitchen_Initiation_Flow.md](./Eco_Kitchen_Initiation_Flow.md)

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

4. Run with the same key for map widget gating:

   ```powershell
   flutter run -d <device> `
     --dart-define=GOOGLE_MAPS_API_KEY=AIza… `
     --dart-define=API_BASE_URL=… `
     …
   ```

Without `GOOGLE_MAPS_API_KEY`, the app uses the **form fallback** (`HandoverLocationConfirmCard`).

---

## Flutter widgets

| Widget | When |
|--------|------|
| `HandoverLocationPicker` | Entry point — picks map vs form |
| `HandoverLocationMapPicker` | Map + address + pickup note |
| `HandoverLocationConfirmCard` | Fallback without Maps API key |

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

- Places autocomplete (Google Places or Mapbox)
- iOS Maps SDK key in `AppDelegate`
- Optional `formatted_address` persisted on `seeker_demands` / `order_intents`

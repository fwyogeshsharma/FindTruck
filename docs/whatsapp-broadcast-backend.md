# WhatsApp broadcast — backend contract

The Find Truck screen lets a finder multi-select trucks and send **one common
message** to all the selected drivers over WhatsApp. The Flutter app does **not**
talk to Meta directly — the WhatsApp Business access token must never ship inside
the app (it would be extractable and could get the number banned). The app calls
**one endpoint on the FreightDesk server**, and the server relays to Meta's
WhatsApp Business Cloud API.

```
App  ──POST /api/whatsapp/broadcast──▶  FreightDesk backend  ──▶  Meta Graph API
     ◀── { sent, failed, failed_numbers } ──                  ◀──
```

The app side is already implemented:
- `RestTruckRepository.broadcastWhatsApp(...)` → `ApiClient.postJson('/api/whatsapp/broadcast', …)`
- Request/response shapes below. **This endpoint does not exist yet on the server — it must be built.**

---

## Endpoint

`POST /api/whatsapp/broadcast`

Auth: the same `Authorization: Bearer <token>` the app already sends on every
request. Only authenticated finders may broadcast.

### Request body

```json
{
  "phones": ["+919988765432", "+919812345678"],
  "message": "Namaste, do you have a truck free from Agra today? Reply to confirm."
}
```

- `phones` — E.164 numbers (the app sends `Truck.phone` verbatim, e.g.
  `+9199...`). The server should normalise / validate and drop malformed ones.
- `message` — the finder's free text (already length-capped at 900 chars in the app).

### Response body (200)

```json
{ "sent": 2, "failed": 0, "failed_numbers": [] }
```

- `sent` — messages Meta accepted.
- `failed` — messages that errored.
- `failed_numbers` — the phone numbers that failed (shown to the finder).

Non-2xx with `{ "detail": "…" }` surfaces as an error in the compose sheet
(the app already renders `detail`).

---

## The template requirement (important)

Meta forbids free-form text for **business-initiated** conversations. A driver
who has **not** messaged your WhatsApp Business number in the last 24 hours can
only receive a **pre-approved message template**. Cold outreach to truck drivers
is essentially all business-initiated, so:

- Create and get approved a template, e.g. `truck_finder_message`, in the Meta
  WhatsApp Manager, with one body variable:

  > Namaste 🙏
  > {{1}}
  >
  > — via TruckFinder

  (A template body cannot be *only* a variable; it needs fixed text like the
  greeting/footer above to pass review.)

- On broadcast, the server sends that template with `{{1}}` = `message`:

```json
POST https://graph.facebook.com/v21.0/<PHONE_NUMBER_ID>/messages
Authorization: Bearer <WHATSAPP_TOKEN>
Content-Type: application/json

{
  "messaging_product": "whatsapp",
  "to": "919988765432",
  "type": "template",
  "template": {
    "name": "truck_finder_message",
    "language": { "code": "en" },
    "components": [
      { "type": "body",
        "parameters": [ { "type": "text", "text": "<message>" } ] }
    ]
  }
}
```

- Optional optimisation: if a driver **is** inside an open 24-hour session
  window, the server may send `"type": "text"` free-form instead of the template.

Loop over `phones`, call Meta per number, tally `sent` / `failed`, return the
response above. Send sequentially or with small concurrency and honour Meta rate
limits.

---

## Server configuration (env)

| Var | Purpose |
|-----|---------|
| `WHATSAPP_TOKEN` | Meta system-user permanent access token (server-side only) |
| `WHATSAPP_PHONE_NUMBER_ID` | The WhatsApp Business phone number id |
| `WHATSAPP_TEMPLATE_NAME` | e.g. `truck_finder_message` |
| `WHATSAPP_TEMPLATE_LANG` | e.g. `en` |

## Prerequisites (one-time, on Meta)

1. Meta Business account + verified business.
2. A WhatsApp Business phone number (added in WhatsApp Manager).
3. The approved message template above.
4. Billing set up — Meta charges **per conversation**; budget for it.

## Notes / guardrails

- **Cost & spam:** mass-messaging drivers who never opted in risks quality-rating
  drops and number bans. Consider a per-finder daily cap and only messaging
  drivers with a prior relationship where possible.
- **Opt-out:** include a way for drivers to stop (e.g. "reply STOP") and honour it.
- The app already skips selected trucks that have no phone number.

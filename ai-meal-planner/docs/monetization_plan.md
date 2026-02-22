## Ad Monetization Plan

### Goals
- Keep UX clean while introducing light ad support.
- Use ads to offset AI generation costs without blocking core flows.

### Placements
- Banner: bottom of Generate/Feed screens (already implemented).
- Interstitial: after successful plan generation (already implemented).
- App Open: on cold start/resume (preloaded, gated by availability).
- Rewarded: optional unlock for extra tips/export variations (future).

### Frequency & Limits
- Interstitial: max 1 per plan generation, no more than 1 per 3 minutes.
- App Open: max 1 per session.
- Banner: always visible when enabled, hidden if no ad loaded.

### Targeting & Compliance
- Use test IDs in dev and real IDs in release builds.
- Respect ATT status on iOS and regional consent requirements (GDPR/CCPA).

### KPIs
- Fill rate, eCPM, session length impact.
- Conversion to subscription after ad exposure.

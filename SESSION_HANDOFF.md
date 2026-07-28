# SalonPOS — Session Handoff

**Last session: 2026-07-28.** Read this first when resuming. It records what is
done, what is not, and the exact next command to run.

---

## ⚠️ READ BEFORE RUNNING ANYTHING

**`api/.env` `DATABASE_URL` points at PRODUCTION.** Port 5433 on localhost is an
**SSH tunnel** (verified: the listener's owning process is `ssh.exe`, not postgres).
Port 5432 is the real local database.

Anything run with the default `.env` — migrations, seeds, `npm run dev` — hits the
live production database.

Always override for local work:

```bash
DATABASE_URL="postgresql://postgres:admin@localhost:5432/moifone_uae" <command>
```

Also note: a server of yours runs on port **5010** using the default `.env`, i.e.
against production. Test servers here were run on **5011** with the override.

Companion docs:
- [SALON_POS_BACKEND_PLAN.md](SALON_POS_BACKEND_PLAN.md) — the reviewed plan, including
  the blocker table and why each decision was made.

---

## Where we are

Backend for SalonPOS is **built, migrated, seeded, and verified working end to end
on the LOCAL database.** Production has NOT been touched.

Verified by live HTTP against a server on :5011 with the local DB:

| Check | Result |
|---|---|
| Migration 104 applied | software type 8 SALON, both salon tables, station CHECK widened, `sales_child.stylist_id`/`line_type` added |
| Seed | company **2** SALON01, station 90, 4 chairs, 6 services, 2 retail, 3 staff; idempotent on re-run |
| Entitlements | 161 features scoped to type 8, 68 granted (core+pos) — nothing stripped |
| `POST /login` | returns JWT + session; registers an `active_session` |
| `GET /stylists` | Maya / Sara / Owner, each with FREE·QUEUED·BUSY state |
| `POST /job/save` | **SJ-0001** via docSequence, SERVICE line carries stylist+duration+WAITING, PRODUCT line does not, totals computed |
| Append (D4 case) | Maya's Haircut + Sara's Blow Dry **on the same job** — the two-stylist case works |
| `PATCH .../status` | WAITING → IN_PROGRESS; stylist load flips to BUSY with pendingMinutes |
| `PATCH .../stylist` | line reassigned between stylists |
| `GET /job/list` | chair name, stylist name, walk-in customer, done/total service counts |
| Error paths | `SERVICE_LINE_NO_STYLIST` 400 · `CHAIR_OCCUPIED` 409 · `BAD_STATION` 400 · `BAD_SERVICE_STATUS` 400 |
| DB-level guards | `chk_salon_service_needs_stylist`, `chk_salon_service_status`, and the composite FK all reject direct SQL that bypasses the service layer |

The salon tenant is **company 2** — the exact second-tenant scenario that would
have collided on `ops.kot_master`. Salon's own tables handled it.

## Decisions locked (do not re-litigate)

| # | Decision | Choice |
|---|----------|--------|
| D1 | Where services live | `core.product_master` with `product_type = 'SERVICE'`, matched case-insensitively |
| D2 | Booking | Walk-in first. `appointment_id` + `start_time`/`end_time` exist so booking is additive later |
| D3 | Backend shape | `api/src/pos/salon/` mounted at `/api/salon-pos`, **reusing** restaurant controllers for auth/params/privileges rather than forking 1,950 lines |
| D4 | Stylist | Job-level `primary_stylist_id` that lines inherit, overridable per line |
| D5 | Job tables | **New** `ops.salon_job_master` / `salon_job_child` with composite `(company_id, job_id)` keys — NOT reusing `ops.kot_master` |

**Why D5:** `ops.kot_master`'s PK is `kot_master_id` alone, but ids are allocated
per-company `MAX+1` (`kot.repository.js:5-21`). Company 2's job #1 collides with
company 1's KOT #1. Latent today only because one company exists. A salon tenant
is the second company. Restaurant still has this bug — see Open Issues.

---

## Files created

```
api/database/migrations/104_salon_pos.sql          new tables, software_type 8, CHECK widen
api/database/migrations/104_salon_pos.down.sql     rollback (first down migration in repo)
api/scripts/run-migration.mjs                      generic runner, replaces one-off scripts
api/scripts/seed-salon-tenant.mjs                  full salon tenant, idempotent
api/src/pos/salon/salon.routes.js                  15 routes
api/src/pos/salon/controllers/job.controller.js
api/src/pos/salon/controllers/stylist.controller.js
api/src/pos/salon/services/job.service.js          salon rules live here
api/src/pos/salon/services/stylist.service.js      FREE / QUEUED / BUSY
api/src/pos/salon/repositories/job.repository.js
api/src/pos/salon/repositories/stylist.repository.js
```

## Files edited

```
api/src/index.js                        mounted salonPosRouter + authLimiter on 3 public routes
api/src/middleware/authMiddleware.js:52 added '/api/salon-pos/' to POS_ALLOWED_PREFIXES
api/src/core/controllers/station.controller.js:4  VALID_TYPES += SALON_POS
api/src/core/services/auth.service.js   ternary -> POS_ALLOWED_TYPES_BY_POS map that THROWS
                                        on unknown posType; loginWithPinForRestaurant takes
                                        an optional posType instead of hardcoding restaurant
api/src/shared/services/docSequence.service.js    added SALON_JOB (SJ-0001, NEVER resets)
api/package.json                        migrate, migrate:salon, migrate:salon:down, seed:salon
```

---

## NEXT STEP — start here

Local is already migrated and seeded. To bring the environment back up:

```bash
cd api
DATABASE_URL="postgresql://postgres:admin@localhost:5432/moifone_uae" PORT=5011 node src/index.js
```

Credentials: `salonadmin` / `Salon@123` · company **2** · station **90** ·
stylists Maya (staffId 2, PIN 1111) and Sara (staffId 3, PIN 2222).

Pick up with **settlement** (`POST /api/salon-pos/sales/settle`) or the Flutter
wiring. Both are described under NOT DONE.

**Production still needs migration 104 + seed** when you decide to deploy. Do that
deliberately, not by accident — see the warning at the top.

---

## NOT DONE

| Item | Notes |
|------|-------|
| **Settlement** | `/api/salon-pos/sales/settle` does not exist. Needs to write `ops.sales_master`/`sales_child` incl. the `stylist_id` + `line_type` columns 104 added. Deliberately not half-built. |
| **Production migration** | 104 + seed applied to LOCAL only. Production untouched. |
| **Flutter side untouched** | Still `useMockData = true`, still `/api/pos/` paths, still named `my_app` |
| **Cart composite key (B6)** | `home_screen.dart:455` merges lines by `ProductID` alone, so two stylists doing the same service collapse into one line. **D4 cannot work until this is fixed.** This is the first Flutter task. |
| **Tests** | None written. No CI exists in this repo. |
| **Retail stock decrement** | POS never writes `product_inventory` (verified: zero writes in `src/pos/`). Salon retail will not move stock. Pre-existing gap, now also salon's. |

---

## Open issues found during review (verified, not fixed)

1. **Restaurant multi-tenant collision** — `ops.kot_master`/`kot_child` keyed without
   `company_id` while allocating per-company. Breaks the day a second restaurant
   company is added. Salon dodges it via D5; restaurant does not.
2. **Two migration trees** — `database/migrations` (root, to 096) and
   `api/database/migrations` (to 104). `084` exists in both with different content.
   Nobody has decided which is canonical. `run-migration.mjs --root` targets the
   sibling tree.
3. **No migration ledger** — nothing records what has been applied. Re-run safety
   depends entirely on `IF NOT EXISTS` guards.
4. **`software_type_id = 7` is SERVICE**, not free (migration 102:237). Salon is 8.
   Also `SOFTWARE_TYPE_ID_MAP` in `core/services/registration.service.js` stops at
   `ERP: 6` — missing both `SERVICE: 7` and `SALON: 8`, so no one can *register* as
   a salon tenant through that path. **Not yet fixed.**
5. **`/api/pos/*` public routes have no rate limiter** — salon's do now, restaurant's
   still do not. `pin-login` brute-forces a 4-6 digit PIN against every staff row.

6. **`posController.login` never calls `registerSession`.** Username/password POS
   login issues a token but creates no session row, so the very next request 401s
   "Session expired". Only `pin-login` registers one. Salon works around this with
   its own `src/pos/salon/controllers/auth.controller.js`; restaurant is unfixed.

7. **`staffPk` vs `staffId` confusion.** `pos.controller.js:76` does
   `const staffPk = u?.staffId`, but `u.staffId` is the BUSINESS id
   (`staff_master.staff_id`) while the JWT `sub` and `active_session.staff_pk`
   use the surrogate PK (`staff_master.id`). The session is written under a key
   that can never be looked up. Only works where `id == staff_id` by coincidence.
   Salon resolves the real PK via `staffRepo.findStaffPk`.

8. **POS logins issue ERP-scoped tokens.** `buildTokensForStaffRow` uses
   `signAccessToken`, which sets no `scope:'pos'` claim — only
   `buildTokensForPOSDevice`/`signPosAccessToken` does. Consequence: the
   `POS_ALLOWED_PREFIXES` isolation in `authMiddleware.js:52` never engages for
   these tokens, so a POS token can reach ERP routes. Salon registers its session
   as `'erp'` to stay internally consistent; making POS tokens genuinely
   POS-scoped is a follow-up affecting all three POS products.

9. **`core.tool_system_log` does not exist** on local. `systemActivityLogger`
   throws on every request (logged, non-fatal). Migration `090_tools_center.sql`
   presumably creates it and has not been applied locally.

---

## Review context

Four independent review voices ran (CEO, eng, design, DX) via `/autoplan`, degraded
to Claude-only because `codex` and `jq` are not installed. Every critical finding
was verified against source before being accepted — two voices contradicted each
other on `software_type_id` 7 and one was wrong. Do not trust an unverified agent
claim in the plan doc; the ones marked "verified" were checked by reading the file.

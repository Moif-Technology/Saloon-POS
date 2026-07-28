# SalonPOS — Backend Plan

Convert the RestaurantPOS fork into a salon POS that sells **products and services**
in one bill, with service lines assigned to a stylist.

Status: **reviewed — v1 contained 6 verified blockers. Corrections applied below.**

---

## BLOCKERS FOUND IN REVIEW (all verified against code)

Read this before anything else. Each was confirmed by reading the source, not inferred.

| # | Blocker | Evidence | Status |
|---|---------|----------|--------|
| B1 | **`software_type_id = 7` is already taken** by `SERVICE`. v1 of this plan assigned 7 to SALON, which would have merged salon into Service & Case Management. | `api/database/migrations/102_service_case_management.sql:237` | Fixed — SALON is **8** |
| B2 | **POS tokens cannot reach `/api/salon-pos/*`.** Scope isolation whitelists only `/api/pos/` and `/api/counter-pos/`. Every authenticated salon call 403s. | `api/src/middleware/authMiddleware.js:52` | Fixed — new build step 1.5 |
| B3 | **The "shared endpoints" in v1 are unreachable from a POS token** — `/api/products`, `/api/customers`, `/api/groups`, `/api/areas`, `/api/tables` all 403. This **falsifies the stated rationale for D1.** It is also why `counter-pos` has its own product/group/customer controllers. | same as B2 | Fixed — catalogue endpoints must be forked |
| B4 | **`requireFeature('salon')` would 403 forever.** No `'salon'` row exists in `core.feature_master`, and `software_type_feature.feature_code` is an FK to it. | `api/src/core/repositories/featureCatalogSeed.js`, FK at `080_software_type_modules.sql:93` | Fixed — use `requireFeature('pos')` |
| B5 | **The "SERVICE lines skip stock decrement" rule guards a path that does not exist.** POS never writes `core.product_inventory` — zero writes across all of `src/pos/`. The real gap is the inverse: salon retail *should* decrement and never will. | `grep -rn product_inventory src/pos/` → reads only | Fixed — phantom rule deleted |
| B0 | **Reusing `ops.kot_master` collides on the second tenant.** PK is `kot_master_id` alone (no `company_id`), but IDs are allocated per-company `MAX+1`. Company 2's job #1 duplicates company 1's KOT #1 → `23505`. Latent today only because there is exactly one company. **The salon tenant is the second company.** Same for `kot_child`. | PK per schema dump line 6421/6501; allocation at `kot.repository.js:5-21` | **OPEN — decides the data model** |
| B6 | **D4 (per-line stylist) is impossible on the current cart.** Cart lines merge on `ProductID` alone, so two stylists performing the same service silently collapse to one line at qty 2 with one stylist. Commission would be wrong and nobody would notice. | `SalonPOS/lib/screens/home_screen.dart:455` | Fixed — composite key is frontend step 0 |

Two further corrections to v1's factual claims:

- **`counter-pos` is not a fork of `restaurant-pos`.** They share **zero** filenames (`counter-pos/services/` has auth, counter, customer, group, product, sales, settlement; `restaurant-pos/services/` has kot, posParameter, sales). `sales.service.js` is 996 lines vs 365. "Follow the counter-pos precedent" therefore instructs nothing specific, and `src/pos/shared/` **has never been created**.
- **There are two migration trees with colliding numbers.** Root `database/migrations` (90 files, to 096) and `api/database/migrations` (32 files, 070–103). `084` exists in both with different content. "Next is 104" is true only for the api tree.

---

---

## Settled decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| D1 | Where services live | `core.product_master` with `product_type = 'SERVICE'` | Existing POS grid, groups, sub-groups, pricing and tax paths work unchanged. One catalogue, one admin screen. |
| D2 | Job lifecycle | Full KOT lifecycle renamed to Job; walk-in only, booking-ready schema | The app has no backend at all today. Getting a real sale path working is the blocker. `appointment_id` nullable from day one so booking is an additive phase 2. |
| D3 | Backend shape | Fork `src/pos/salon-pos/`, mount `/api/salon-pos` | Follows the existing `counter-pos` precedent. Isolates salon changes from the live restaurant POS. |
| D4 | Stylist assignment | Job-level default, overridable per service line | Matches how modern salon software works (Fresha, Vagaro, Boulevard). Fast for the common single-stylist visit, correct when two stylists share one customer, and keeps per-stylist commission splits possible. |

---

## What already exists

Mapped before writing any new code. Most of this plan is reuse, not construction.

| Sub-problem | Existing code | Reuse verdict |
|---|---|---|
| POS module forking | `src/pos/counter-pos/` (fork of `restaurant-pos`, mounted `/api/counter-pos`, `src/index.js:245`) | Copy the pattern exactly |
| Job/ticket persistence | `ops.kot_master` + `ops.kot_child`, `src/pos/restaurant-pos/repositories/kot.repository.js` | Reuse tables — already carry `chair_no`, `waiter_id`, `area_id`, `station_id` |
| Job save/append/list/get | `kot.service.js` (362 lines), `kot.controller.js`, `routes/kot.routes.js` | Fork, rename KOT→Job at API layer |
| Settlement | `src/pos/restaurant-pos/services/sales.service.js` (365), `repositories/sales.repository.js` (220) | Fork as-is |
| Product catalogue | `core.product_master.product_type` column already present | Add `'SERVICE'` as a value |
| Stylist list | `POST /api/pos/staff-list`, `src/pos/restaurant-pos/controllers/pos.controller.js` | Reuse verbatim |
| Chair (furniture) | `core.table_master`, `src/backoffice/repositories/table.repository.js` | Reuse — a chair is a table row |
| POS terminal | `core.station_master` (migration 085) | Reuse, but CHECK constraint must be widened for `'SALON_POS'` |
| Service-job precedent | `src/garage/` — jobCard, jobDescription, technician, estimation | Reference for the job workflow; do not import |
| Service catalogue precedent | `service.service_master` (migration 102) | Explicitly NOT used — D1 chose product_master |
| Entitlements | `core.software_type_feature`, migration 100 seeds types 1-6 | Add type 7 = SALON |
| POS auth / PIN login | `pos.controller.js` login, pinLogin, staffList | Reuse verbatim |

---

## Data model

### Reuse `ops.kot_master` / `ops.kot_child`

Rows are scoped by `company_id`, and a company has exactly one software type, so
salon and restaurant rows never mix within a tenant. No new job tables.

Semantic remapping (no schema change needed):

| Column | Restaurant meaning | Salon meaning |
|---|---|---|
| `table_id` | Table | Chair (`core.table_master` row) |
| `chair_no` | Seat at table | Seat position (unused or chair label) |
| `waiter_id` | Waiter | **Primary stylist** |
| `area_id` | Dining area | Salon floor / zone |
| `kot_status` | Ticket state | Job state |

### Migration 104 — salon support

Next migration number is `104` (latest on disk is `103_service_case_customer_id_fix.sql`).

```sql
-- 104_salon_pos.sql

-- 1. Service line support on the job child
ALTER TABLE ops.kot_child
  ADD COLUMN IF NOT EXISTS line_type        VARCHAR(16)  NOT NULL DEFAULT 'PRODUCT',
  ADD COLUMN IF NOT EXISTS stylist_id       VARCHAR(50)  NULL,
  ADD COLUMN IF NOT EXISTS duration_minutes INTEGER      NULL,
  ADD COLUMN IF NOT EXISTS service_status   VARCHAR(16)  NULL;

-- 2. Booking-ready hook (phase 2 fills this; nullable today)
ALTER TABLE ops.kot_master
  ADD COLUMN IF NOT EXISTS appointment_id   VARCHAR(50)  NULL;

-- 3. Service metadata on the shared catalogue
ALTER TABLE core.product_master
  ADD COLUMN IF NOT EXISTS default_duration_minutes INTEGER NULL;

-- 4. Software type 8 = SALON. Type 7 is SERVICE (migration 102). Create the
--    master row first — software_type_feature.software_type_id is an FK to it.
INSERT INTO core.software_type_master
  (software_type_id, software_code, software_name, description, display_order)
VALUES (8, 'SALON', 'Salon ERP',
        'Salon POS: services and retail, stylist assignment.', 8)
ON CONFLICT (software_type_id) DO NOTHING;

-- feature_code is an FK to core.feature_master. NEVER insert literals — and
-- never insert a narrow subset. Migration 100's header documents that scoping
-- 'allowed' to a subset silently stripped hr/garage access. allowed must
-- always be the FULL pack list; is_granted is what varies.
INSERT INTO core.software_type_feature (software_type_id, feature_code, is_granted, created_at)
SELECT 8, feature_code, TRUE,  NOW() FROM core.feature_master
  WHERE pack_code IN ('core','pos') AND is_active
UNION ALL
SELECT 8, feature_code, FALSE, NOW() FROM core.feature_master
  WHERE pack_code IN ('backoffice','accounts','crm','van','hr','garage') AND is_active
ON CONFLICT (software_type_id, feature_code) DO UPDATE SET is_granted = EXCLUDED.is_granted;

-- 4b. Stylist must survive settlement or commission is uncomputable. kot_child
--     is a working-set table; sales_child is the ledger.
ALTER TABLE ops.sales_child
  ADD COLUMN IF NOT EXISTS stylist_id BIGINT NULL;

-- 5. Allow SALON_POS terminals. Migration 085 pinned station_type to three
--    values; enrolling a salon till fails without this.
ALTER TABLE core.station_master DROP CONSTRAINT IF EXISTS chk_station_type;
ALTER TABLE core.station_master ADD CONSTRAINT chk_station_type
  CHECK (station_type IN ('BACKOFFICE','COUNTER_POS','RESTAURANT_POS','SALON_POS'));

-- 6. Constrain product_type so 'Service' vs 'SERVICE' can't silently break
--    the stock-decrement branch.
UPDATE core.product_master SET product_type = UPPER(TRIM(product_type))
  WHERE product_type IS NOT NULL
    AND product_type <> UPPER(TRIM(product_type));

-- 7. Indexes for the job board and stylist reports
CREATE INDEX IF NOT EXISTS idx_kot_child_stylist
  ON ops.kot_child (company_id, stylist_id) WHERE stylist_id IS NOT NULL;
```

`stylist_id` is **BIGINT**, not VARCHAR — every other staff identifier in the
schema (`sales_master.waiter_id`, `kot_master.waiter_id`,
`table_master.assigned_waiter_id`) is BIGINT, and a VARCHAR forces a cast in
every commission join.

Rules enforced in the service layer, not the DB:
- `line_type = 'SERVICE'` lines **require** a non-null `stylist_id`, and fail with
  a `SERVICE_LINE_NO_STYLIST` 400 naming the offending item.
- ~~`SERVICE` lines never decrement `core.product_inventory`~~ — **deleted, this
  was a phantom rule (B5).** POS never writes `product_inventory` at all. The real
  gap is that salon **retail** (shampoo, serum) *should* decrement stock and
  currently cannot. Logged below as an accepted phase-1 risk, not a rule.

---

### Migration tooling (gap found during review)

There is **no generic migration runner** in `api/`. All 20 existing migrations ship
as bespoke scripts (`scripts/run-0XX-migration.mjs`) plus a `package.json` entry.
Migration 104 must follow that pattern:

- `api/scripts/run-104-salon-migration.mjs` — copy the shape of
  `scripts/run-078-migration.mjs` (dotenv → `DATABASE_URL` → read SQL → `client.query`)
- `package.json` script: `"migrate:salon": "node scripts/run-104-salon-migration.mjs"`

There is also **no migration ledger table** — nothing records which migrations have
run. Re-run safety depends entirely on `IF NOT EXISTS` guards inside the SQL.
Consequences for 104:

- The `DROP CONSTRAINT ... / ADD CONSTRAINT ...` pair is re-run safe only because
  of `DROP CONSTRAINT IF EXISTS`. Keep it.
- The `UPDATE core.product_master SET product_type = UPPER(TRIM(...))` is idempotent
  but rewrites every product row on each run. Scope it with a
  `WHERE product_type <> UPPER(TRIM(product_type))` guard.
- **No down migration exists for any migration in this repo.** Write one for 104
  (`104_salon_pos_down.sql`) since it is the first to alter a constraint on a table
  the live restaurant POS depends on.

---

## Backend: `src/pos/salon-pos/`

Mounted in `src/index.js` alongside the existing two:

```js
import { salonPosRouter } from './pos/salon-pos/salon-pos.routes.js';
app.use('/api/salon-pos', salonPosRouter);
```

### Files

```
src/pos/salon-pos/
  salon-pos.routes.js          fork of pos.routes.js; requireFeature('salon')
  salonPrivileges.defaults.js  fork of posPrivileges.defaults.js
  controllers/
    salon.controller.js        login, pinLogin, staffList, parameters, privileges
    job.controller.js          fork of kot.controller.js
    sales.controller.js        fork
  routes/
    job.routes.js              POST /save, GET /list, GET /:jobId
    sales.routes.js            POST /settle
  services/
    job.service.js             fork of kot.service.js + service-line rules
    salonParameter.service.js  fork of posParameter.service.js
    sales.service.js           fork
    stylist.service.js         NEW — availability + assignment
  repositories/
    job.repository.js          fork of kot.repository.js
    salonParameter.repository.js
    sales.repository.js
```

### Endpoint map

Every current Flutter call gets a salon equivalent. Paths mirror `/api/pos/*` so
the Flutter change is a base-path swap, not a rewrite.

| Flutter method (`api_service.dart`) | Today | Salon |
|---|---|---|
| `login` | `POST /api/pos/login` | `POST /api/salon-pos/login` |
| `pinLogin` | `POST /api/pos/pin-login` | `POST /api/salon-pos/pin-login` |
| `fetchPosStaffList` | `POST /api/pos/staff-list` | `POST /api/salon-pos/staff-list` |
| `fetchParameters` | `GET /api/pos/parameters` | `GET /api/salon-pos/parameters` |
| `savePosParameters` | `PUT /api/pos/parameters` | `PUT /api/salon-pos/parameters` |
| `saveCompanyDetails` | `PUT /api/pos/parameters/company-details` | same under salon |
| `fetchPrivileges` | `GET /api/pos/privileges` | `GET /api/salon-pos/privileges` |
| `saveKot` | `POST /api/pos/kot/save` | `POST /api/salon-pos/job/save` |
| `fetchOrderList` | `GET /api/pos/kot/list` | `GET /api/salon-pos/job/list` |
| `fetchKotDetails` | `GET /api/pos/kot/:id` | `GET /api/salon-pos/job/:id` |
| `saveSettlement` | `POST /api/pos/sales/settle` | `POST /api/salon-pos/sales/settle` |
| — | — | **NEW** `GET /api/salon-pos/stylists` |
| — | — | **NEW** `GET /api/salon-pos/stylists/:id/load` |

**Catalogue endpoints must be forked, not shared (B3).** v1 of this plan listed
`/api/products`, `/api/groups`, `/api/sub-groups`, `/api/areas`, `/api/tables`,
`/api/customers`, `/api/staff/members`, `/api/auth/me` as "unchanged, already
tenant-scoped". They are **unreachable from a POS token** — `authMiddleware.js:52`
403s any path outside `/api/pos/` and `/api/counter-pos/`. This is exactly why
`counter-pos` carries its own `product.controller.js`, `group.controller.js` and
`customer.controller.js`.

Two ways out; pick one:
- **(a)** Fork the catalogue controllers into `salon-pos/` — follows counter-pos,
  adds ~6 files, keeps scope isolation intact. **Recommended.**
- **(b)** Add `/api/salon-pos/` to `POS_ALLOWED_PREFIXES` *and* widen the whitelist
  to the shared catalogue paths — fewer files, but loosens a security boundary for
  all three POS products at once.

Either way `/api/salon-pos/` must be added to `POS_ALLOWED_PREFIXES` or nothing
works. Salon's public endpoints also need adding to the `authLimiter` list in
`src/index.js:176-179` — counter-pos has them, restaurant-pos does not.

The product endpoint gains an optional `productType` filter so the grid can show
services, products, or both.

---

## Frontend changes (SalonPOS Flutter)

1. **Turn off mock data** — `lib/config/api_config.dart:5`, `useMockData = false`.
   Point `baseURL` at the real API.
2. **Base path** — add `salonBasePath = '/api/salon-pos'`; swap the ~11 `/api/pos/`
   literals in `lib/services/api_service.dart`.
3. **Rename KOT → Job** in user-facing strings and symbols: `saveKot` → `saveJob`,
   `fetchKotDetails` → `fetchJobDetails`, `lib/utils/kot_reset_utils.dart`,
   `lib/utils/empty_kot_response.dart`, `lib/widgets/rightPanelWidgets/kot_join_split.dart`.
4. **Stylist picker** — new widget in the left panel; required before a SERVICE
   line can be added to the cart.
5. **Table → Chair** — relabel `lib/widgets/table_selection_dialog.dart`.
6. **Kitchen display → Job board** — `lib/screens/kitchen_display_screen.dart`
   becomes a per-stylist job queue.
7. **Package rename** — `pubspec.yaml` name `my_app` → `salon_pos`.

---

## NOT in scope

Deferred deliberately. Each is additive and does not require reworking the above.

| Item | Why deferred | Phase |
|---|---|---|
| Appointment booking + stylist calendar | Schema hook (`appointment_id`) is in place; needs a working sale path first | 2 |
| Commission calculation per stylist | Needs settled jobs to compute against | 2 |
| Package / membership deals | `dealsOffers.repository.js` exists in backoffice; wire later | 2 |
| Loyalty points | Not requested | — |
| Inventory consumption per service (dye, shampoo) | Real need, but needs a service-BOM model | 2 |
| Migrating `service.service_master` into POS | D1 rejected this path | — |

---

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Shared `ops.kot_master` couples salon to restaurant schema changes | A restaurant migration could break salon | Migration 104 only adds nullable columns; add a salon smoke test to CI |
| `product_type` values are not currently constrained | Typo'd `'Service'` vs `'SERVICE'` silently breaks stock logic | Normalize on write; add a CHECK constraint in 104 |
| Service lines must skip stock decrement | Wrong stock counts, hard to detect | Assert in `job.service.js`; unit test both line types |
| Three POS forks drift apart | Bug fixed in one, not others | Extract shared helpers to `src/pos/shared/` where the fork is verbatim |
| Flutter is on mock data — contract never validated against real API | Integration surprises | Wire one endpoint end-to-end first (`parameters`) before forking the rest |

---

## Build order

0. **Frontend prerequisite (B6):** change cart line identity from `ProductID` to a
   composite `(ProductID, stylistId)` + stable `lineKey`, and introduce a typed
   `CartLine` class to replace `List<Map<String,String>>`. **D4 is unimplementable
   until this lands.** `home_screen.dart:455`.
1. Migration 104 (wrapped in `BEGIN; … COMMIT;`) + `scripts/run-104-salon-migration.mjs`
   + `migrate:salon` npm script + `104_salon_pos.down.sql`; verify against local
   `moifone_uae`. Decide which of the two migration trees is canonical.
1.5. **Add `/api/salon-pos/` to `POS_ALLOWED_PREFIXES`** (`authMiddleware.js:52`) and
   salon public routes to the `authLimiter` list (`index.js:176-179`). **Nothing
   authenticated works before this (B2).**
1b. `scripts/seed-salon-tenant.mjs` — one salon company end to end: company with
   `software_type_id = 8`, branch, role, staff with PIN, `station_master` row,
   4 chairs in `table_master`, 6 sample SERVICE products, 2 stylists. Idempotent.
   **Steps 3–9 are untestable without it.**
1c. Widen the two JS allowlists the DB CHECK does not cover:
   `core/controllers/station.controller.js:4` `VALID_TYPES`, and
   `core/services/auth.service.js:147-151` — convert the `posType` ternary chain to
   a map that **throws on unknown**, since `'SALON-POS'` currently falls through to
   counter-POS rules silently. Note the naming trap: role types use hyphens
   (`RESTAURANT-POS`), station types use underscores (`RESTAURANT_POS`).
2. `src/pos/salon-pos/` scaffold + `salon-pos.routes.js` + mount in `index.js`.
3. Auth trio (login, pin-login, staff-list) — prove the fork works.
4. Flutter: `useMockData = false`, base path swap, confirm login against real API.
5. `parameters` + `privileges`.
6. `/api/products?productType=` filter + service metadata.
7. Job save/list/get with SERVICE line rules.
8. Stylist endpoints + Flutter stylist picker.
9. Settlement.
10. Rename pass (KOT→Job, table→chair) + package rename.

---

## Open questions

- **RESOLVED (D4)** — stylist is job-level default, overridable per service line.
- **RESOLVED** — chairs are `core.table_master` rows. `core.station_master` is the
  POS terminal, and its `chk_station_type` CHECK must be widened for `'SALON_POS'`
  (folded into migration 104 above).
- **OPEN** — Commission: percentage per stylist, per service, or per service-grade?
  Affects whether `duration_minutes` or price drives it. Deferred to phase 2; does
  not block the build order below.

# SalonPOS — Appointment Feature Plan

Convert restaurant-style table selection and KOT workflow to appointment-based job management with appointment scheduling backend.

Status: **In Planning** — This plan defines the shift from walk-in service model to appointment-driven model.

---

## Problem Statement

SalonPOS today operates on a restaurant model: select a table (chair), add services/products, complete at settlement. No booking system exists. Stylists have no visibility into upcoming appointments or client commitments.

This plan adds:
1. **Appointment UI** — Replace table buttons with appointment list; show booked slots
2. **Appointment API** — Backend endpoints for CRUD, availability checks, stylist load
3. **Integration** — Wire appointment data into the job workflow without breaking walk-in model

---

## Decisions (Proposed)

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| A1 | Appointment buttons location | Replace table selection with appointment list in left panel | Matches salon workflow; walk-ins still use "new" button |
| A2 | Data storage | Use `ops.appointment_master` (new table) + `ops.appointment_client` (many:1) | Cleaner than denormalizing into `ops.kot_master`; FK to customer |
| A3 | Walk-in vs booked split | "New Job" button for walk-in; appointment list for booked | UX clarity; both paths feed the same `job.save` endpoint |
| A4 | Availability calc | Per-stylist, per-time-slot (15-min intervals), duration-aware | Matches modern salon booking (Boulevard, Fresha) |
| A5 | Backend shape | New `appointments/` folder under `src/pos/salon-pos/` | Follows existing fork pattern; isolated from KOT logic |

---

## What Already Exists

| Sub-problem | Existing | Verdict |
|---|---|---|
| Salon backend scaffold | `src/pos/salon-pos/` (job, sales, auth) | Use as home for new `appointments/` module |
| Customer data | `core.customer_master` + `pos.customer.controller.js` | Reuse for appointment client lookup |
| Stylist data | `core.staff_master` + `/api/salon-pos/staff-list` | Reuse; add availability state |
| Service catalogue | `core.product_master` (product_type='SERVICE') | Reuse with `default_duration_minutes` |
| Job storage | `ops.kot_master` + `ops.kot_child` | Reuse; `appointment_id` FK exists |
| UI patterns | `lib/widgets/table_selection_dialog.dart` | Fork to `appointment_selection_dialog.dart` |
| Button grid layout | `lib/widgets/centerPanelWidgets/ProductsPanel.dart` | Adapt for appointment list display |

---

## Data Model

### New Tables

```sql
-- ops.appointment_master (parent)
CREATE TABLE IF NOT EXISTS ops.appointment_master (
  appointment_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            BIGINT NOT NULL,
  customer_id           BIGINT NOT NULL REFERENCES core.customer_master(customer_id),
  stylist_id            BIGINT NOT NULL REFERENCES core.staff_master(staff_id),
  appointment_date      DATE NOT NULL,
  appointment_time      TIME NOT NULL,
  duration_minutes      INTEGER NOT NULL DEFAULT 60,
  appointment_status    VARCHAR(16) NOT NULL DEFAULT 'SCHEDULED',
  notes                 TEXT,
  created_at            TIMESTAMP DEFAULT NOW(),
  updated_at            TIMESTAMP DEFAULT NOW(),
  job_id                UUID NULL REFERENCES ops.kot_master(kot_id),
  FOREIGN KEY (company_id) REFERENCES core.company_master(company_id),
  UNIQUE (company_id, stylist_id, appointment_date, appointment_time)
);

-- ops.appointment_service (line items — services booked)
CREATE TABLE IF NOT EXISTS ops.appointment_service (
  appointment_service_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id          UUID NOT NULL REFERENCES ops.appointment_master(appointment_id),
  service_id              BIGINT NOT NULL REFERENCES core.product_master(product_id),
  expected_duration_min   INTEGER,
  created_at              TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (appointment_id) REFERENCES ops.appointment_master(appointment_id) ON DELETE CASCADE
);

-- Core indices
CREATE INDEX idx_appointment_date_time ON ops.appointment_master(company_id, appointment_date, appointment_time);
CREATE INDEX idx_appointment_stylist ON ops.appointment_master(company_id, stylist_id, appointment_date);
CREATE INDEX idx_appointment_customer ON ops.appointment_master(company_id, customer_id);
```

Migration number: **105** (follows 104_salon_pos.sql).

Rules (service layer, not DB):
- `appointment_status` IN ('SCHEDULED', 'CONFIRMED', 'COMPLETED', 'CANCELLED')
- Stylist availability: no overlapping appointments within `duration_minutes`
- Once `job_id` is set, appointment is "checked in" — do not allow reschedule

---

## Backend: `src/pos/salon-pos/appointments/`

Mounted in `src/index.js` as part of salon-pos router:

```js
import { appointmentRouter } from './pos/salon-pos/appointments/appointment.routes.js';
salonRouter.use('/appointments', appointmentRouter);
```

### Files

```
src/pos/salon-pos/appointments/
  appointment.routes.js
  controllers/
    appointment.controller.js        CRUD, list, availability
  services/
    appointment.service.js           business logic, conflicts, availability
  repositories/
    appointment.repository.js        SQL queries
```

### Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/api/salon-pos/appointments` | Create new appointment |
| `GET` | `/api/salon-pos/appointments?date=YYYY-MM-DD&stylistId=X` | List appointments for date/stylist |
| `GET` | `/api/salon-pos/appointments/:id` | Get single appointment detail |
| `PUT` | `/api/salon-pos/appointments/:id` | Reschedule or update |
| `DELETE` | `/api/salon-pos/appointments/:id` | Cancel appointment (soft delete on `appointment_status`) |
| `POST` | `/api/salon-pos/appointments/:id/confirm` | Confirm appointment |
| `POST` | `/api/salon-pos/appointments/:id/check-in` | Link to job at check-in (set `job_id`) |
| **NEW** | `GET` | `/api/salon-pos/stylists/:id/availability?date=YYYY-MM-DD` | Availability slots for stylist + date |
| **NEW** | `GET` | `/api/salon-pos/appointments/stats/daily-load?date=YYYY-MM-DD` | Salon-wide appointment load |

Request/Response bodies:

```js
// POST /api/salon-pos/appointments
{
  "customerId": 123,
  "stylistId": 456,
  "appointmentDate": "2025-02-14",
  "appointmentTime": "14:30",
  "durationMinutes": 60,
  "serviceIds": [789, 790],
  "notes": "First time client"
}

// GET /api/salon-pos/appointments (filtered)
// Response: [ { appointmentId, customerId, stylistId, appointmentDate, appointmentTime, durationMinutes, status, serviceIds, notes }, ... ]

// GET /api/salon-pos/stylists/:id/availability?date=2025-02-14
// Response: { availableSlots: [ "09:00", "09:30", "10:00", ... ], bookedSlots: [ "14:30", "15:30" ], styleName }
```

---

## Frontend Changes (SalonPOS Flutter)

### 1. Replace Table Selection with Appointment Selection

**File:** `lib/widgets/appointment_selection_dialog.dart` (NEW)

```dart
class AppointmentSelectionDialog extends StatefulWidget {
  final Function(String appointmentId, String customerId, String stylistId) onAppointmentSelected;
  final Function() onNewWalkIn;
}
```

Displays:
- "New Walk-In" button (blue, prominent)
- Date picker
- Appointment list for selected date (from `/api/salon-pos/appointments?date=...`)
- Each appointment shows: customer name, stylist name, time, duration, services

**File:** `lib/screens/home_screen.dart` (MODIFIED)

- Remove `table_selection_dialog.dart` import
- Replace table selection flow with appointment selection
- On "New Walk-In": skip appointment, start cart normally
- On appointment select: prefill customer, stylist, services

### 2. Left Panel — Appointment/Walk-In Toggle

**File:** `lib/widgets/left_panel.dart` (MODIFIED)

Add two tabs:
- **Appointments** — shows today's booked appointments, click to check in
- **New Sale** — blank cart for walk-ins (existing flow)

### 3. Appointment Detail View (Optional UI Enhancement)

**File:** `lib/widgets/appointment_detail_panel.dart` (NEW)

When appointment is selected:
- Customer name, phone, email
- Booked services + durations
- Stylist assignment
- "Confirm Check-In" button → triggers `POST /api/salon-pos/appointments/:id/check-in`

### 4. Stylist Selector — Show Availability (if applicable)

**File:** `lib/widgets/stylist_picker.dart` (MODIFIED)

When adding a service, show stylist availability from `/api/salon-pos/stylists/:id/availability?date=...` to guide assignment.

### 5. API Integration

**File:** `lib/services/api_service.dart` (MODIFIED)

Add methods:
```dart
Future<List<Appointment>> fetchAppointmentsByDate(String date) async {
  return _getRequest('/api/salon-pos/appointments?date=$date');
}

Future<Appointment> createAppointment({...params}) async {
  return _postRequest('/api/salon-pos/appointments', body);
}

Future<Map> getStylistAvailability(String stylistId, String date) async {
  return _getRequest('/api/salon-pos/stylists/$stylistId/availability?date=$date');
}

Future<void> checkInAppointment(String appointmentId, String jobId) async {
  return _postRequest('/api/salon-pos/appointments/$appointmentId/check-in', { jobId });
}
```

---

## Integration with Job Workflow

### Walk-In Path (unchanged)

User → "New Walk-In" → Select Chair → Add Services → Job Save → Settlement

### Appointment Path (new)

User → Appointment List → Click Appointment → Prefill Customer/Stylist → Add Services/Adjust → Job Save **with** `appointment_id` → Settlement

Job save endpoint modified:

```js
POST /api/salon-pos/job/save
{
  "appointmentId": "uuid-here", // OPTIONAL — null for walk-ins
  "customerId": "...",
  "stylistId": "...",
  "serviceLines": [...],
  "...": "..."
}
```

Backend:
- If `appointmentId` provided, validate it matches the customer/stylist in the job
- Set `ops.kot_master.appointment_id = appointmentId`
- At settlement, set `ops.appointment_master.appointment_status = 'COMPLETED'`

---

## NOT in scope

| Item | Why deferred | Phase |
|---|---|---|
| SMS/email reminders | Needs SMS gateway wiring (Twilio/SNS) | 2 |
| Rescheduling existing appointments | Core feature, but deferred to UX audit | 2 |
| No-show tracking | Needs loyalty/reputation model | 2 |
| Waitlist / buffer time | Needs ops config per salon | 2 |
| Google Calendar sync | Needs OAuth; salon may not use calendar | 2 |
| Multi-stylist appointments | Complex availability; walk-ins handle this better | — |

---

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Appointment + walk-in split confuses UI | Users pick wrong flow, appointments unused | UX test with live stylists; "New Walk-In" button is visually distinct |
| Double-booking typo in availability calc | Overbooking, unhappy customers | Unit test availability with overlapping times; integration test with real times |
| Appointment orphaned if job settlement fails | Appointment stuck in CONFIRMED, never marked COMPLETED | Wrap both in transaction; on settlement error, roll back appointment status too |
| Slot granularity (15 min) too fine | Slot picker unusable (48 slots per day) | UI can group by 30-min if UX testing shows congestion |
| Migration 105 on live database | Schema drift | Add down migration; test on staging clone first |

---

## Build Order

1. **Migration 105** — `105_appointments.sql` + `scripts/run-105-appointment-migration.mjs` + down migration
2. **Backend scaffold** — `src/pos/salon-pos/appointments/` folder + routes wired to salon-pos router
3. **Appointment CRUD** — controllers, services, repositories for create/get/list/update/delete
4. **Availability API** — `/stylists/:id/availability` endpoint with slot calculation
5. **Job integration** — Modify `job.service.js` to accept `appointment_id`; set status at settlement
6. **Seed data** — Update `scripts/seed-salon-tenant.mjs` to create 3 sample appointments
7. **Flutter:** `AppointmentSelectionDialog` component
8. **Flutter:** Left panel appointment list + "New Walk-In" toggle
9. **Flutter:** Wire appointment fetch + create in `api_service.dart`
10. **Flutter:** Appointment detail panel (optional polish)
11. **Integration test** — Book appointment → check-in → settle → verify appointment marked COMPLETED

---

## Effort Estimate

| Task | Human | Claude |
|---|---|---|
| Migration + backend scaffold (1-2) | 2 hours | 30 min |
| Appointment CRUD endpoints (3-4) | 4 hours | 1.5 hours |
| Availability slot calculation (4) | 3 hours | 1 hour |
| Job + settlement integration (5) | 2 hours | 1 hour |
| Seed data (6) | 1 hour | 15 min |
| Flutter appointment dialog (7-8) | 4 hours | 1.5 hours |
| API wiring (9) | 1.5 hours | 30 min |
| Testing + fixes (11) | 3 hours | 1 hour |
| **TOTAL** | ~20 hours | ~6 hours |

---

## Questions for User

1. **Availability slot granularity** — 15-min, 30-min, or variable per service?
2. **Booking horizon** — How many days ahead can clients book? (Recommend 30-60 days)
3. **Time-based pricing** — Does service price vary by time-of-day? (Peak vs off-peak)
4. **Cancellation policy** — Can users cancel within X hours? Penalty?
5. **Confirmation** — Should appointments auto-confirm, or require stylist approval?

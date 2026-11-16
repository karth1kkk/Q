# Table Relay 🍽️

A two-sided marketplace that lets diners skip restaurant queues by paying verified "queue runners" to hold their table and pre-order their food.

**Tagline:** *Never queue again. Pre-order, pre-pay, walk in and sit.*

---

## Table of Contents

1. [What This Is](#what-this-is)
2. [How It Works](#how-it-works)
3. [Business Model](#business-model)
4. [Core User Flows](#core-user-flows)
5. [Tech Stack (Flutter + JavaScript Backend)](#tech-stack-flutter--javascript-backend)
6. [Data Model](#data-model)
7. [API Design](#api-design)
8. [App Structure](#app-structure)
9. [Payments & Escrow](#payments--escrow)
10. [Trust & Safety](#trust--safety)
11. [Restaurant Partnerships](#restaurant-partnerships)
12. [MVP Scope (Phase 1)](#mvp-scope-phase-1)
13. [Manual MVP First](#manual-mvp-first)
14. [Roadmap](#roadmap)
15. [Launch Plan](#launch-plan)
16. [Legal & Compliance (Malaysia)](#legal--compliance-malaysia)
17. [Risks & Mitigations](#risks--mitigations)
18. [Metrics to Track](#metrics-to-track)
19. [Getting Started (Dev)](#getting-started-dev)

---

## What This Is

Table Relay connects two groups:

- **Diners** who don't want to wait in line at popular restaurants.
- **Queue Runners** who are willing to queue, get a table, pre-order food, and hand the table off to the diner when they arrive — for a fee.

The platform earns a **commission per completed job** plus a small **booking fee** from the diner. Runners pay a **refundable deposit** (not a fee) to filter out flakes.

> ⚠️ This is NOT table-scalping. Every partner restaurant must explicitly consent to proxy queuing. See [Restaurant Partnerships](#restaurant-partnerships).

---

## How It Works

### For Diners
1. Open app → browse partner restaurants → see live queue estimate.
2. Select a **relay slot** (date + time window) and pre-select menu items.
3. Pay **convenience fee + food deposit** (held in escrow).
4. A runner is dispatched, queues, gets the table, and orders the pre-selected food.
5. Diner arrives → scans QR at the table to confirm handoff → escrow releases.
6. Diner eats. Runner has already left.

### For Queue Runners
1. Sign up → verify IC + selfie → pay **refundable RM50 deposit**.
2. Browse nearby jobs → accept → queue → get seated → order → handoff.
3. Get paid instantly to e-wallet minus platform commission.
4. Build rating; unlock premium restaurants and priority jobs.

### For Restaurants
- Guaranteed **pre-paid covers** during peak hours.
- **Faster table turnover** (food is ordered the moment the runner sits).
- Free **queue analytics dashboard**.
- **Zero no-shows** from the Table Relay channel (diners pre-pay).

---

## Business Model

| Stream | Amount | Payer | Notes |
|---|---|---|---|
| Transaction commission | 15–20% of convenience fee | Deducted from runner payout | Core revenue |
| Diner booking fee | RM2–5 per booking | Diner | Built into convenience fee |
| Restaurant featured placement | TBD | Restaurant | Phase 3+ |
| Runner deposit | RM50 (refundable) | Runner | NOT revenue — held in escrow |

**Unit economics per job (example):**
- Diner pays: RM12 convenience fee + RM2 booking fee + food deposit (escrow)
- Runner earns: RM10
- Platform keeps: RM2 (commission) + RM2 (booking fee) = **RM4/job**
- 100 jobs/day → RM400/day gross platform revenue

---

## Core User Flows

### 1. Diner Booking Flow
```
[Browse Restaurants]
   → [Select Restaurant]
   → [View Queue Estimate + Slots]
   → [Pick Slot + Pre-order Menu]
   → [Pay: Convenience Fee + Booking Fee + Food Deposit]
   → [Order Created → Runner Matching]
   → [Runner Assigned → Notified]
   → [Runner Seated → Diner Notified "Head over now"]
   → [Diner Arrives → Scan QR → Handoff Confirmed]
   → [Escrow Releases → Food Deposit Settled]
   → [Rate Runner]
```

### 2. Runner Job Flow
```
[Browse Available Jobs (nearby, by time)]
   → [Accept Job]
   → [Navigate to Restaurant]
   → [Check-in at Restaurant (GPS + timestamp)]
   → [Queue → Get Table]
   → [Order Pre-selected Food (photo proof)]
   → [Mark "Seated & Ordered"]
   → [Wait for Diner → Handoff QR Scan]
   → [Job Complete → Payout]
```

### 3. Handoff Confirmation
- Diner scans a **QR code** displayed on the runner's app (or a table-tent QR if restaurant supports it).
- Backend verifies: runner GPS at restaurant + order receipt photo + QR match.
- Escrow releases automatically.

---

## Tech Stack (Flutter + JavaScript Backend)

| Layer | Recommendation | Why |
|---|---|---|
| Mobile app | **Flutter (3.x)** | Single codebase iOS + Android, consistent UI, hot reload |
| State management | **Riverpod** (or Bloc) | Testable, scales from MVP to production |
| Navigation | **go_router** | Declarative, deep-link friendly |
| HTTP / API | **dio** + **retrofit** | Typed REST client, interceptors for auth |
| Backend | **Supabase** (PostgreSQL + Auth + Realtime + Storage + Edge Functions) | JavaScript/TypeScript backend logic, no server to manage |
| Auth | **Supabase Auth** (phone OTP) | Works with `supabase_flutter` SDK |
| Realtime | **Supabase Realtime** | Live job status without extra infra |
| Server logic | **Supabase Edge Functions** (TypeScript/Deno) | Payment webhooks, handoff validation, payouts |
| Payments | **Billplz** (FPX/DuitNow) + **Stripe** (cards) | Local MY rails + international fallback |
| Push notifications | **Firebase Cloud Messaging** via `firebase_messaging` | Free, reliable |
| Maps | **google_maps_flutter** | GPS check-in, routing |
| Camera / QR | **mobile_scanner** + **image_picker** | Handoff QR + receipt photo |
| Location | **geolocator** | GPS check-in with permission flow |
| Storage | **Supabase Storage** | Receipt photos, IC verification |
| Admin | **Next.js on Vercel** + Supabase service role | Manage restaurants, disputes, payouts |

**MVP shortcut:** Flutter + Supabase (auth + DB + realtime + storage + Edge Functions) + Billplz gets you to a testable app fast. All backend logic is JavaScript/TypeScript — no separate Node server to deploy.

### Why this combination works
- **Flutter** gives you one polished app for both iOS and Android, with excellent camera/GPS/maps plugins for the runner flows (check-in, QR scan, receipt photo).
- **Supabase** gives you a real PostgreSQL database (critical for Table Relay's relational data — bookings → jobs → transactions), plus auth, realtime, and file storage in one.
- **Edge Functions in TypeScript** let you write server-side logic (Billplz webhook, handoff validation, payout calculation) in JavaScript — no need to learn a new backend language.
- **No server to manage** — Supabase is hosted, so you focus on the app and the business, not DevOps.

### When to add a Node.js API later
If you outgrow Supabase Edge Functions (complex payout logic, heavy background jobs, custom integrations), you can add a **Node.js (NestJS) API** on Railway/Render and have Flutter call it alongside Supabase. The data model and API contract below stay the same — you're just moving logic to a dedicated service.

---

## Data Model

Core tables (PostgreSQL via Supabase):

```sql
-- Users (both diners and runners)
users (
  id UUID PK,
  phone TEXT UNIQUE,
  name TEXT,
  role TEXT CHECK (role IN ('diner','runner','admin')),
  email TEXT,
  created_at TIMESTAMPTZ
)

-- Runner-specific profile
runner_profiles (
  user_id UUID PK FK→users,
  ic_number TEXT,
  ic_verified BOOLEAN DEFAULT FALSE,
  selfie_url TEXT,
  deposit_status TEXT CHECK (deposit_status IN ('none','held','refunded')),
  deposit_amount NUMERIC,
  rating_avg NUMERIC DEFAULT 0,
  jobs_completed INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
)

-- Restaurants (partner venues)
restaurants (
  id UUID PK,
  name TEXT,
  address TEXT,
  lat NUMERIC,
  lng NUMERIC,
  proxy_queuing_allowed BOOLEAN DEFAULT FALSE,
  consent_signed_at TIMESTAMPTZ,
  avg_queue_minutes INT,
  is_active BOOLEAN DEFAULT TRUE
)

-- Menu items (for pre-ordering)
menu_items (
  id UUID PK,
  restaurant_id UUID FK→restaurants,
  name TEXT,
  price NUMERIC,
  is_available BOOLEAN DEFAULT TRUE
)

-- Bookings (a diner's request)
bookings (
  id UUID PK,
  diner_id UUID FK→users,
  restaurant_id UUID FK→restaurants,
  slot_start TIMESTAMPTZ,
  slot_end TIMESTAMPTZ,
  party_size INT,
  preorder_items JSONB,       -- [{menu_item_id, qty}]
  convenience_fee NUMERIC,
  booking_fee NUMERIC,
  food_deposit NUMERIC,
  status TEXT CHECK (status IN (
    'pending_payment','paid','matching','runner_assigned',
    'runner_seated','handoff_pending','completed','cancelled','disputed'
  )),
  created_at TIMESTAMPTZ
)

-- Jobs (runner assignment)
jobs (
  id UUID PK,
  booking_id UUID FK→bookings,
  runner_id UUID FK→users,
  accepted_at TIMESTAMPTZ,
  checked_in_at TIMESTAMPTZ,
  seated_at TIMESTAMPTZ,
  ordered_at TIMESTAMPTZ,
  receipt_photo_url TEXT,
  handoff_confirmed_at TIMESTAMPTZ,
  payout_amount NUMERIC,
  commission_amount NUMERIC,
  status TEXT CHECK (status IN (
    'available','accepted','checked_in','seated',
    'ordered','handoff_pending','completed','cancelled','disputed'
  ))
)

-- Ledger (every money movement)
transactions (
  id UUID PK,
  job_id UUID FK→jobs,
  type TEXT CHECK (type IN (
    'diner_payment','escrow_hold','runner_payout',
    'platform_commission','deposit_hold','deposit_refund','refund'
  )),
  amount NUMERIC,
  status TEXT CHECK (status IN ('pending','succeeded','failed','refunded')),
  provider_ref TEXT,
  created_at TIMESTAMPTZ
)

-- Ratings
ratings (
  id UUID PK,
  job_id UUID FK→jobs,
  from_user_id UUID FK→users,
  to_user_id UUID FK→users,
  score INT CHECK (score BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ
)
```

---

## API Design

REST endpoints (Supabase RPCs or Edge Functions). All authenticated unless noted.

### Auth
- `POST /auth/otp/request` — send phone OTP *(public)*
- `POST /auth/otp/verify` — verify OTP, return session
- `POST /auth/runner/apply` — submit IC + selfie for verification

### Diners
- `GET /restaurants` — list partner restaurants with queue estimates
- `GET /restaurants/:id/menu` — menu items
- `POST /bookings` — create booking + pre-order
- `POST /bookings/:id/pay` — initiate payment (returns Billplz/Stripe URL)
- `GET /bookings/:id` — booking status
- `POST /bookings/:id/handoff` — submit QR handoff confirmation
- `POST /bookings/:id/cancel` — cancel (refund rules apply)
- `POST /ratings` — rate runner after completion

### Runners
- `GET /jobs/available` — nearby available jobs
- `POST /jobs/:id/accept` — accept job
- `POST /jobs/:id/checkin` — GPS check-in at restaurant
- `POST /jobs/:id/seated` — mark seated
- `POST /jobs/:id/order` — upload receipt photo, mark ordered
- `POST /jobs/:id/complete` — finalize after handoff
- `GET /runner/earnings` — payout history
- `POST /runner/deposit` — pay refundable deposit

### Webhooks (Edge Functions)
- `POST /webhooks/billplz` — payment success/failure callback
- `POST /webhooks/stripe` — card payment callback

### Admin
- `GET /admin/disputes` — open disputes
- `POST /admin/disputes/:id/resolve` — resolve
- `POST /admin/restaurants` — onboard restaurant + consent record
- `GET /admin/analytics` — jobs, revenue, queue times

---

## App Structure

### Flutter project layout
```
lib/
├── main.dart
├── core/
│   ├── api_client.dart          # dio + retrofit setup
│   ├── supabase_client.dart     # supabase_flutter init
│   ├── auth_service.dart
│   ├── payment_service.dart     # Billplz/Stripe helpers
│   └── constants.dart
├── models/
│   ├── user.dart
│   ├── restaurant.dart
│   ├── booking.dart
│   └── job.dart
├── features/
│   ├── auth/                    # OTP login, role selection
│   ├── diner/
│   │   ├── browse/              # restaurant list + queue estimate
│   │   ├── booking/             # slot + menu + payment
│   │   ├── tracking/            # live status + handoff QR
│   │   └── history/
│   ├── runner/
│   │   ├── onboarding/          # IC + selfie + deposit
│   │   ├── jobs/                # available + active job
│   │   ├── checkin/             # GPS + timers
│   │   └── earnings/
│   └── shared/
│       ├── ratings/
│       └── profile/
├── routing/
│   └── app_router.dart          # go_router config
└── widgets/
```

**Role gating:** one app, two experiences. After login, route by `user.role` via `go_router` redirect. Runners must complete verification + deposit before seeing jobs.

### Supabase Edge Functions layout
```
supabase/
├── functions/
│   ├── billplz-webhook/         # payment success/failure
│   │   └── index.ts
│   ├── stripe-webhook/
│   │   └── index.ts
│   ├── validate-handoff/        # QR + GPS + receipt check
│   │   └── index.ts
│   └── calculate-payout/        # commission split
│       └── index.ts
└── migrations/
    └── 0001_init.sql
```

---

## Payments & Escrow

### Flow
1. Diner pays **convenience fee + booking fee + food deposit** via Billplz/Stripe.
2. Platform holds **food deposit** in escrow (not captured until handoff).
3. On successful handoff:
   - Food deposit → released to restaurant (or runner pays restaurant directly and is reimbursed — pick one; reimbursing runner is simpler for MVP).
   - Convenience fee → split: runner payout + platform commission.
4. On cancellation/dispute → refund per policy.

### MVP shortcut
For the first 200 jobs, **don't build escrow**. Use:
- Diner pays into your account (Billplz).
- Runner pays restaurant out of pocket, uploads receipt.
- You manually transfer runner payout + reimbursements daily.
- Track everything in the `transactions` table.

This lets you validate the model without payment-engineering overhead.

### Runner deposit
- RM50 held via payment provider (authorization hold) or collected and tracked in ledger.
- Refunded on: 10 completed jobs OR account closure with no open disputes.
- Forfeited on: no-show after accepting a job, fraud, or repeated disputes.

### Billplz integration (Edge Function)
```
Diner → POST /bookings/:id/pay
  → Edge Function creates Billplz bill
  → returns bill URL
Diner pays on Billplz
  → Billplz POSTs to /webhooks/billplz
  → Edge Function verifies signature, marks booking 'paid'
  → Realtime pushes status to Flutter app
```

---

## Trust & Safety

| Risk | Mitigation |
|---|---|
| Fake runners / fraud | IC verification + selfie match + deposit |
| Runner no-show | Deposit forfeiture + rating penalty + job reassignment |
| Diner no-show | Food deposit forfeited after 10-min handoff window |
| Table scalping accusation | Written restaurant consent per venue; in-app disclosure |
| Fake receipt photos | Require timestamp + GPS match + restaurant name visible |
| Disputes | Photo proof + QR scan + GPS log = auto-resolve; manual fallback |
| Harassment / safety | In-app reporting, block list, emergency contact |

**Handoff rule:** Diner must arrive within **10 minutes** of runner being seated. After that, the runner may eat/pack the food and the diner forfeits the deposit.

---

## Restaurant Partnerships

**This is the make-or-break of the business. Do not launch without consent.**

### Pitch to restaurants
> "We send you pre-paid, pre-ordered diners during peak hours. Your kitchen starts cooking the moment our runner sits — no waiting for the diner to decide. Faster turnover, guaranteed covers, zero no-shows. We also give you free queue analytics."

### What to get in writing (one-pager per restaurant)
- Permission for proxy queuing at your venue.
- Agreement that pre-orders are accepted via the app.
- Handoff window (default 10 min) acknowledged.
- Optional: revenue share or featured placement terms.

### Onboarding checklist per restaurant
- [ ] Consent form signed
- [ ] Menu + prices imported
- [ ] Queue estimate baseline recorded
- [ ] Staff briefed on Table Relay handoff process
- [ ] QR table-tent (optional) placed

---

## MVP Scope (Phase 1)

**Goal:** Prove the handoff works for 200 jobs in one dense zone.

### Build
- [ ] Phone OTP auth (diner + runner roles) — Supabase Auth
- [ ] Restaurant list (hardcoded 2–3 partners)
- [ ] Menu display + pre-order selection
- [ ] Booking creation + payment (Billplz)
- [ ] Runner onboarding (IC upload + deposit)
- [ ] Job board + accept
- [ ] GPS check-in + status timers (geolocator)
- [ ] Receipt photo upload (image_picker)
- [ ] QR handoff confirmation (mobile_scanner)
- [ ] Manual payout ledger (admin dashboard)
- [ ] Ratings (1–5)
- [ ] Basic admin: disputes, payouts, restaurant management

### Skip for MVP
- Escrow automation (manual ledger)
- In-app chat (use WhatsApp deeplink)
- Push notifications (SMS/WhatsApp fallback — add FCM in Phase 2)
- Analytics dashboard for restaurants (export CSV manually)
- Multi-city support

---

## Manual MVP First

**Before writing a line of code**, run 20–50 jobs manually:

1. Create a WhatsApp group for runners in one mall area.
2. Create a Google Form for diners to book + pre-order.
3. Collect payment via DuitNow transfer.
4. Dispatch runners manually via WhatsApp.
5. Track handoffs in a Google Sheet.
6. Pay runners manually at end of day.

**What you'll learn:**
- Real queue times per restaurant per hour.
- How often runners no-show.
- How often diners are late.
- Which restaurants actually cooperate.
- What the handoff friction really is.

Only build the app after you've done this 50+ times. Most of the app requirements will change based on what you learn.

---

## Roadmap

### Phase 0 — Manual validation (Weeks 1–4)
- 50 manual jobs in one zone
- 2–3 restaurant consent forms signed
- 10–15 runners recruited
- Document all friction points

### Phase 1 — MVP app (Weeks 5–12)
- Flutter app (diner + runner)
- Supabase backend (DB + Auth + Realtime + Edge Functions)
- Billplz payments (manual payout)
- Launch in one zone

### Phase 2 — Automation (Weeks 13–20)
- Automated escrow + instant payouts
- FCM push notifications
- Restaurant analytics dashboard
- Dispute auto-resolution

### Phase 3 — Expansion (Weeks 21+)
- Second zone / second city
- Restaurant self-serve onboarding
- Featured placement revenue
- Loyalty program for diners

---

## Launch Plan

### Zone selection criteria
- 3+ queue-heavy restaurants within 5-min walk
- High foot traffic mall or street cluster
- Accessible by public transport (runners + diners)
- At least one restaurant willing to sign consent

### Launch checklist
- [ ] 3 restaurant consent forms signed
- [ ] 10–15 runners verified + deposited
- [ ] Menu data imported for all partners
- [ ] Payment flow tested end-to-end
- [ ] QR handoff tested 10× in real conditions
- [ ] Admin dashboard live for disputes/payouts
- [ ] WhatsApp support line active
- [ ] Launch promo: first booking free (absorb cost)

### Success criteria for Phase 1
- 200 completed jobs
- <5% dispute rate
- <10% runner no-show rate
- >4.0 avg rating both sides
- At least 1 restaurant renews consent for Phase 2

---

## Legal & Compliance (Malaysia)

> ⚠️ Not legal advice. Consult a Malaysian lawyer before launch.

- **Business registration:** SSM (Sdn Bhd or Enterprise).
- **Payments:** If handling money for others, may need to operate under a payment provider's license or use a licensed provider (Billplz, iPayment, Stripe) as merchant of record. Do not hold funds in your own account at scale without legal review.
- **Runner classification:** Treat runners as independent contractors, not employees. Clear T&Cs needed.
- **PDPA (Personal Data Protection Act):** IC numbers and selfies are sensitive. Get explicit consent, encrypt at rest, define retention policy.
- **Restaurant consent:** Written agreement per venue is essential to avoid table-scalping claims.
- **Food safety:** You're not preparing food — the restaurant is. But clarify liability if a pre-order goes wrong.
- **Consumer protection:** Clear refund policy, dispute process, and contact info required.

---

## Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Restaurant revokes consent | High | Get written consent; make yourself valuable (analytics, guaranteed covers); 3+ restaurants per zone |
| Runners no-show at peak | High | Deposit forfeiture + rating penalty + backup runner pool |
| Diners late → food wasted | Medium | 10-min handoff window + deposit forfeiture |
| Payment/escrow complexity | Medium | Manual ledger for MVP; automate in Phase 2 |
| Regulatory (payments) | Medium | Use licensed provider as merchant of record |
| Low density → no liquidity | High | Launch in one dense zone only; don't expand until 200 jobs |
| Copycat competitors | Low | Restaurant relationships + runner loyalty are the moat |

---

## Metrics to Track

**Liquidity**
- Jobs posted vs jobs completed (fill rate)
- Avg time to match a runner
- Runner utilization rate

**Quality**
- Dispute rate per 100 jobs
- Runner no-show rate
- Diner late rate (>10 min)
- Avg rating (diner→runner, runner→diner)

**Unit economics**
- Revenue per job
- Cost per acquisition (diner + runner)
- Runner payout per hour
- Restaurant retention rate

**Growth**
- New diners/week
- Repeat booking rate
- New runners/week
- Restaurants onboarded

---

## Getting Started (Dev)

### Prerequisites
- Flutter SDK 3.x
- Supabase account + Supabase CLI
- Billplz account (sandbox for dev)
- Google Maps API key
- Firebase project (for FCM, Phase 2)

### Setup
```bash
# Clone
git clone https://github.com/yourorg/table-relay.git
cd table-relay

# Flutter
flutter pub get

# Supabase (local)
supabase init
supabase start
supabase db push

# Run Edge Functions locally
supabase functions serve

# Run app
flutter run
```

### Environment variables
```
# Flutter (dart-define or .env via flutter_dotenv)
SUPABASE_URL=
SUPABASE_ANON_KEY=
GOOGLE_MAPS_API_KEY=
BILLPLZ_API_URL=

# Supabase Edge Functions (secrets)
supabase secrets set BILLPLZ_API_KEY=...
supabase secrets set BILLPLZ_COLLECTION_ID=...
supabase secrets set BILLPLZ_SIGNATURE_KEY=...
```

### Run tests
```bash
flutter test
```

### Deploy
- Mobile: `flutter build apk` / `flutter build ipa` → Play Store / App Store
- Backend: `supabase db push` (migrations) + `supabase functions deploy` (Edge Functions)
- Admin: Next.js on Vercel

### Useful commands
```bash
# Generate freezed/json models
dart run build_runner build --delete-conflicting-outputs

# Watch Edge Function logs
supabase functions logs billplz-webhook

# Reset local DB
supabase db reset
```

---

## Contributing

This is a solo-founder project. If you're building it yourself:
1. Start with [Manual MVP](#manual-mvp-first) — do NOT skip this.
2. Build only what Phase 1 requires.
3. Ship to real users in one zone before adding features.
4. Talk to every runner and every diner for the first 100 jobs.

---

## License

MIT (or your choice).

---

## Contact

Built by [your name] — [your email] — [your phone]

**Remember:** The app is the easy part. Restaurant consent, runner reliability, and dense-zone liquidity are the real business.

---

**What's in this version (Flutter + JS backend):**

- **Frontend**: Flutter 3.x with Riverpod, go_router, dio + retrofit, `supabase_flutter`, `google_maps_flutter`, `mobile_scanner`, `geolocator`, `image_picker`, `firebase_messaging`.
- **Backend**: **Supabase** — PostgreSQL + Auth + Realtime + Storage + **Edge Functions in TypeScript/JavaScript** (running on Deno). No separate Node server needed for MVP.
- **Server logic** lives in `supabase/functions/` — Billplz webhook, Stripe webhook, handoff validation, payout calculation — all written in TypeScript.
- **App structure** is back to the Flutter `lib/features/...` layout, plus a `supabase/functions/` folder for the JS backend.
- **Getting Started** uses `flutter pub get`, `supabase start`, `supabase functions serve`, `flutter run`.
- **Env vars** split into Flutter-side (`--dart-define` or `flutter_dotenv`) and Supabase secrets (`supabase secrets set`).
- A note on **when to add a Node.js API later** if Edge Functions aren't enough — the data model and API contract don't change.

This is the version to save as `README.md`.

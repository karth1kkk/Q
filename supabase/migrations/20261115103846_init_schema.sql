-- USERS (extends auth.users)
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique,
  name text,
  role text check (role in ('diner','runner','admin')),
  created_at timestamptz default now()
);

-- RUNNER PROFILES
create table public.runner_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  ic_number text,
  ic_verified boolean default false,
  selfie_url text,
  deposit_status text check (deposit_status in ('none','held','refunded')) default 'none',
  deposit_amount numeric default 0,
  rating_avg numeric default 0,
  jobs_completed int default 0,
  is_active boolean default true
);

-- RESTAURANTS
create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  lat numeric,
  lng numeric,
  proxy_queuing_allowed boolean default false,
  consent_signed_at timestamptz,
  avg_queue_minutes int default 0,
  is_active boolean default true
);

-- MENU ITEMS
create table public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references public.restaurants(id) on delete cascade,
  name text not null,
  price numeric not null,
  is_available boolean default true
);

-- BOOKINGS
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  diner_id uuid references public.users(id) on delete cascade,
  restaurant_id uuid references public.restaurants(id),
  slot_start timestamptz,
  slot_end timestamptz,
  party_size int default 1,
  preorder_items jsonb default '[]'::jsonb,
  convenience_fee numeric default 0,
  booking_fee numeric default 0,
  food_deposit numeric default 0,
  status text check (status in (
    'pending_payment','paid','matching','runner_assigned',
    'runner_seated','handoff_pending','completed','cancelled','disputed'
  )) default 'pending_payment',
  created_at timestamptz default now()
);

-- JOBS
create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.bookings(id) on delete cascade,
  runner_id uuid references public.users(id),
  accepted_at timestamptz,
  checked_in_at timestamptz,
  seated_at timestamptz,
  ordered_at timestamptz,
  receipt_photo_url text,
  handoff_confirmed_at timestamptz,
  payout_amount numeric default 0,
  commission_amount numeric default 0,
  status text check (status in (
    'available','accepted','checked_in','seated',
    'ordered','handoff_pending','completed','cancelled','disputed'
  )) default 'available'
);

-- TRANSACTIONS (ledger)
create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.jobs(id) on delete cascade,
  type text check (type in (
    'diner_payment','escrow_hold','runner_payout',
    'platform_commission','deposit_hold','deposit_refund','refund'
  )),
  amount numeric not null,
  status text check (status in ('pending','succeeded','failed','refunded')) default 'pending',
  provider_ref text,
  created_at timestamptz default now()
);

-- RATINGS
create table public.ratings (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.jobs(id) on delete cascade,
  from_user_id uuid references public.users(id),
  to_user_id uuid references public.users(id),
  score int check (score between 1 and 5),
  comment text,
  created_at timestamptz default now()
);

-- ROW LEVEL SECURITY (basic — enable on all tables)
alter table public.users enable row level security;
alter table public.runner_profiles enable row level security;
alter table public.restaurants enable row level security;
alter table public.menu_items enable row level security;
alter table public.bookings enable row level security;
alter table public.jobs enable row level security;
alter table public.transactions enable row level security;
alter table public.ratings enable row level security;

-- BASIC POLICIES

-- Users can read their own row; anyone can insert their own on signup
create policy "users_read_own" on public.users for select using (auth.uid() = id);
create policy "users_insert_own" on public.users for insert with check (auth.uid() = id);
create policy "users_update_own" on public.users for update using (auth.uid() = id);

-- Restaurants are public read
create policy "restaurants_public_read" on public.restaurants for select using (true);
create policy "menu_items_public_read" on public.menu_items for select using (true);

-- Runners can read active runner profiles
create policy "runner_profiles_read" on public.runner_profiles for select using (true);
create policy "runner_profiles_own_insert" on public.runner_profiles for insert with check (auth.uid() = user_id);
create policy "runner_profiles_own_update" on public.runner_profiles for update using (auth.uid() = user_id);

-- Bookings: diner sees own, runner sees ones assigned to them
create policy "bookings_diner_own" on public.bookings for select using (auth.uid() = diner_id);
create policy "bookings_diner_insert" on public.bookings for insert with check (auth.uid() = diner_id);
create policy "bookings_diner_update" on public.bookings for update using (auth.uid() = diner_id);

-- Jobs: runner sees available + own; diner sees jobs for their bookings
create policy "jobs_available_read" on public.jobs for select using (
  status = 'available'
  or auth.uid() = runner_id
  or auth.uid() in (select diner_id from public.bookings where id = booking_id)
);
create policy "jobs_runner_update" on public.jobs for update using (auth.uid() = runner_id);

-- Transactions: visible to the involved runner/diner
create policy "transactions_involved_read" on public.transactions for select using (
  auth.uid() in (
    select j.runner_id from public.jobs j
    join public.bookings b on b.id = j.booking_id
    where j.id = job_id and (j.runner_id = auth.uid() or b.diner_id = auth.uid())
  )
);

-- Ratings: visible to both parties; insertable by job participants
create policy "ratings_read" on public.ratings for select using (
  auth.uid() = from_user_id or auth.uid() = to_user_id
);
create policy "ratings_insert" on public.ratings for insert with check (auth.uid() = from_user_id);

-- Seed a couple of test restaurants so the diner browse screen has data
insert into public.restaurants (name, address, lat, lng, proxy_queuing_allowed, avg_queue_minutes)
values
  ('Oriental Kopi (Mid Valley)', 'Mid Valley Megamall, KL', 3.1186, 101.6767, true, 35),
  ('Nasi Kandar Pelita', 'Jalan Ampang, KL', 3.1618, 101.7100, true, 20),
  ('Village Park Restaurant', 'Damansara Uptown, PJ', 3.1320, 101.6220, true, 25);

insert into public.menu_items (restaurant_id, name, price)
select id, 'Signature Egg Tart', 3.50 from public.restaurants where name like 'Oriental Kopi%';
insert into public.menu_items (restaurant_id, name, price)
select id, 'Kopi O', 4.00 from public.restaurants where name like 'Oriental Kopi%';
insert into public.menu_items (restaurant_id, name, price)
select id, 'Nasi Kandar (Chicken)', 12.00 from public.restaurants where name like 'Nasi Kandar%';
insert into public.menu_items (restaurant_id, name, price)
select id, 'Nasi Lemak Ayam Goreng', 13.50 from public.restaurants where name like 'Village Park%';
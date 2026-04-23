-- ─────────────────────────────────────────────
--  volunteerHub — Supabase Schema
--  Run this entire file in the Supabase SQL Editor
--  (Dashboard → SQL Editor → New query → paste → Run)
-- ─────────────────────────────────────────────

-- 1. Profiles — extends Supabase auth.users
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  role        text not null check (role in ('volunteer','ngo')),
  display_name text not null,
  created_at  timestamptz default now()
);

-- 2. Opportunities posted by NGOs
create table if not exists public.opportunities (
  id          bigint generated always as identity primary key,
  ngo_id      uuid not null references public.profiles(id) on delete cascade,
  ngo_name    text not null,
  title       text not null,
  description text not null,
  cause       text not null,
  location    text not null,
  event_date  date not null,
  spots       int  not null default 20,
  time_commitment text,
  created_at  timestamptz default now()
);

-- 3. Sign-ups by volunteers
create table if not exists public.signups (
  id             bigint generated always as identity primary key,
  opportunity_id bigint not null references public.opportunities(id) on delete cascade,
  volunteer_id   uuid   not null references public.profiles(id) on delete cascade,
  volunteer_name text   not null,
  volunteer_email text  not null,
  motivation     text,
  created_at     timestamptz default now(),
  unique (opportunity_id, volunteer_id)   -- one sign-up per user per post
);

-- ─── Row Level Security ───────────────────────────────
alter table public.profiles     enable row level security;
alter table public.opportunities enable row level security;
alter table public.signups       enable row level security;

-- Profiles: users can read all, only edit own
create policy "profiles: public read"
  on public.profiles for select using (true);

create policy "profiles: own insert"
  on public.profiles for insert with check (auth.uid() = id);

create policy "profiles: own update"
  on public.profiles for update using (auth.uid() = id);

-- Opportunities: anyone can read; only the owning NGO can insert/update/delete
create policy "opps: public read"
  on public.opportunities for select using (true);

create policy "opps: ngo insert"
  on public.opportunities for insert
  with check (auth.uid() = ngo_id);

create policy "opps: ngo update"
  on public.opportunities for update
  using (auth.uid() = ngo_id);

create policy "opps: ngo delete"
  on public.opportunities for delete
  using (auth.uid() = ngo_id);

-- Sign-ups: NGO owning the post can read their signups; volunteers can manage their own
create policy "signups: ngo can read own post signups"
  on public.signups for select
  using (
    auth.uid() = volunteer_id
    or auth.uid() = (
      select ngo_id from public.opportunities where id = opportunity_id
    )
  );

create policy "signups: volunteer insert"
  on public.signups for insert
  with check (auth.uid() = volunteer_id);

create policy "signups: volunteer delete own"
  on public.signups for delete
  using (auth.uid() = volunteer_id);

-- ─── Convenience view: opportunities with filled count ─
create or replace view public.opportunities_with_count as
select
  o.*,
  count(s.id)::int as filled
from public.opportunities o
left join public.signups s on s.opportunity_id = o.id
group by o.id;

-- Allow the view to be read publicly
grant select on public.opportunities_with_count to anon, authenticated;

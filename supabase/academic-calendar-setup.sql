-- Hi5 Education Centre Academic Calendar
-- Run this once in the Supabase SQL Editor for the Hi5 project.

create table if not exists public.academic_calendar (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  start_date date not null,
  end_date date,
  event_type text not null default 'School Event',
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint academic_calendar_valid_dates
    check (end_date is null or end_date >= start_date)
);

create index if not exists academic_calendar_start_date_idx
  on public.academic_calendar (start_date);

alter table public.academic_calendar enable row level security;

drop policy if exists "Public can view published calendar events" on public.academic_calendar;
create policy "Public can view published calendar events"
  on public.academic_calendar for select
  to anon, authenticated
  using (is_published = true);

drop policy if exists "Admins can manage academic calendar" on public.academic_calendar;
create policy "Admins can manage academic calendar"
  on public.academic_calendar for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

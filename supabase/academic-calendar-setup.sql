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

-- Hi5 Radio audio programmes
create table if not exists public.hi5_radio (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  category text not null default 'Educational Programme',
  audio_url text,
  audio_path text,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint hi5_radio_audio_source
    check (nullif(trim(audio_url), '') is not null or nullif(trim(audio_path), '') is not null)
);

create index if not exists hi5_radio_created_at_idx
  on public.hi5_radio (created_at desc);

alter table public.hi5_radio enable row level security;

drop policy if exists "Public can listen to published Hi5 Radio programmes" on public.hi5_radio;
create policy "Public can listen to published Hi5 Radio programmes"
  on public.hi5_radio for select
  to anon, authenticated
  using (is_published = true);

drop policy if exists "Admins can manage Hi5 Radio programmes" on public.hi5_radio;
create policy "Admins can manage Hi5 Radio programmes"
  on public.hi5_radio for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Public bucket for uploaded radio audio files (maximum 50 MB per file).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'hi5-radio',
  'hi5-radio',
  true,
  52428800,
  array['audio/mpeg','audio/mp4','audio/aac','audio/wav','audio/ogg','audio/webm','audio/x-wav']
)
on conflict (id) do update
set public = true,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can read Hi5 Radio audio" on storage.objects;
create policy "Public can read Hi5 Radio audio"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'hi5-radio');

drop policy if exists "Admins can upload Hi5 Radio audio" on storage.objects;
create policy "Admins can upload Hi5 Radio audio"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'hi5-radio' and public.is_admin());

drop policy if exists "Admins can update Hi5 Radio audio" on storage.objects;
create policy "Admins can update Hi5 Radio audio"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'hi5-radio' and public.is_admin())
  with check (bucket_id = 'hi5-radio' and public.is_admin());

drop policy if exists "Admins can delete Hi5 Radio audio" on storage.objects;
create policy "Admins can delete Hi5 Radio audio"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'hi5-radio' and public.is_admin());

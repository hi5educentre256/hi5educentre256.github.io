-- Hi5 Website Settings
-- Run once in Supabase SQL Editor. Public visitors can read published settings;
-- only authenticated Hi5 administrators can update them.

create table if not exists public.hi5_site_settings (
  id integer primary key default 1 check (id = 1),
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.hi5_site_settings enable row level security;
revoke all on public.hi5_site_settings from anon, authenticated;
grant select on public.hi5_site_settings to anon, authenticated;
grant insert, update on public.hi5_site_settings to authenticated;

drop policy if exists "Public can read Hi5 website settings" on public.hi5_site_settings;
create policy "Public can read Hi5 website settings"
on public.hi5_site_settings for select to anon, authenticated
using (true);

drop policy if exists "Hi5 admins can insert website settings" on public.hi5_site_settings;
create policy "Hi5 admins can insert website settings"
on public.hi5_site_settings for insert to authenticated
with check (public.is_admin());

drop policy if exists "Hi5 admins can update website settings" on public.hi5_site_settings;
create policy "Hi5 admins can update website settings"
on public.hi5_site_settings for update to authenticated
using (public.is_admin())
with check (public.is_admin());

insert into public.hi5_site_settings (id, settings)
values (1, '{
  "school_name": "Hi5 Education Centre",
  "motto": "Learn Today, Lead Tomorrow",
  "email": "hi5educentre256@gmail.com",
  "whatsapp": "+256702234701",
  "online_enabled": true,
  "online_title": "Hi5 Online Learning",
  "online_description": "Join teacher-led online lessons from home. Hi5 plans to deliver live interactive classes through Zoom, helping learners follow explanations, ask questions and learn with guidance.",
  "learners_enabled": true,
  "learners_description": "Need help with schoolwork? Send your question or attach your work. A Hi5 teacher will review it and respond through your parent or guardian’s contact.",
  "notice_enabled": false,
  "notice_text": ""
}'::jsonb)
on conflict (id) do nothing;

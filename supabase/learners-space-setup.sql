-- Hi5 Learners' Space: run this script in Supabase SQL Editor before accepting submissions.
-- This creates a private submissions table and private file bucket.
-- It relies on the existing public.is_admin() function used by the Hi5 admin dashboard.

create table if not exists public.learner_submissions (
  id uuid primary key default gen_random_uuid(),
  learner_name text not null check (char_length(learner_name) between 1 and 100),
  class_level text not null check (char_length(class_level) between 1 and 60),
  subject text not null check (char_length(subject) between 1 and 80),
  guardian_name text not null check (char_length(guardian_name) between 1 and 100),
  guardian_contact text not null check (char_length(guardian_contact) between 3 and 120),
  question text not null check (char_length(question) between 1 and 3000),
  attachment_path text,
  teacher_response text,
  status text not null default 'pending' check (status in ('pending','in_review','answered')),
  created_at timestamptz not null default now(),
  responded_at timestamptz
);

alter table public.learner_submissions enable row level security;
revoke all on public.learner_submissions from anon, authenticated;
grant insert on public.learner_submissions to anon;
grant select, update on public.learner_submissions to authenticated;

drop policy if exists "Public can submit learner work" on public.learner_submissions;
create policy "Public can submit learner work"
on public.learner_submissions for insert to anon
with check (
  char_length(learner_name) between 1 and 100
  and char_length(class_level) between 1 and 60
  and char_length(subject) between 1 and 80
  and char_length(guardian_name) between 1 and 100
  and char_length(guardian_contact) between 3 and 120
  and char_length(question) between 1 and 3000
  and status = 'pending'
  and teacher_response is null
  and responded_at is null
);

drop policy if exists "Hi5 admins can view learner work" on public.learner_submissions;
create policy "Hi5 admins can view learner work"
on public.learner_submissions for select to authenticated
using (public.is_admin());

drop policy if exists "Hi5 admins can respond to learner work" on public.learner_submissions;
create policy "Hi5 admins can respond to learner work"
on public.learner_submissions for update to authenticated
using (public.is_admin())
with check (public.is_admin());

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values (
  'hi5-learner-work',
  'hi5-learner-work',
  false,
  10485760,
  array[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
on conflict (id) do update
set public=false,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "Public can upload learner attachments" on storage.objects;
create policy "Public can upload learner attachments"
on storage.objects for insert to anon
with check (bucket_id = 'hi5-learner-work');

drop policy if exists "Hi5 admins can view learner attachments" on storage.objects;
create policy "Hi5 admins can view learner attachments"
on storage.objects for select to authenticated
using (bucket_id = 'hi5-learner-work' and public.is_admin());

drop policy if exists "Hi5 admins can delete learner attachments" on storage.objects;
create policy "Hi5 admins can delete learner attachments"
on storage.objects for delete to authenticated
using (bucket_id = 'hi5-learner-work' and public.is_admin());

-- Note: before opening this publicly at scale, add CAPTCHA/rate-limiting to reduce spam.

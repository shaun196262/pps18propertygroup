-- PPS18 Property Group: customer enquiry inbox
-- Run once in Supabase Dashboard > SQL Editor.
create table if not exists public.enquiries (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 120),
  email text not null check (char_length(trim(email)) between 5 and 254),
  phone text,
  interest text not null,
  property_location text,
  owner_property_type text,
  owner_service text,
  message text not null check (char_length(trim(message)) between 2 and 5000),
  status text not null default 'new' check (status in ('new','contacted','closed','spam')),
  created_at timestamptz not null default now()
);
alter table public.enquiries enable row level security;
drop policy if exists "Public can submit PPS18 enquiries" on public.enquiries;
create policy "Public can submit PPS18 enquiries"
on public.enquiries for insert to anon, authenticated
with check (
  char_length(trim(name)) between 2 and 120
  and char_length(trim(email)) between 5 and 254
  and char_length(trim(interest)) between 2 and 120
  and char_length(trim(message)) between 2 and 5000
);
create or replace function public.pps18_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.staff_profiles
    where user_id = auth.uid() and role = 'admin'
  );
$$;
revoke all on function public.pps18_is_admin() from public;
grant execute on function public.pps18_is_admin() to authenticated;
drop policy if exists "PPS18 admins can read enquiries" on public.enquiries;
create policy "PPS18 admins can read enquiries"
on public.enquiries for select to authenticated
using (public.pps18_is_admin());
drop policy if exists "PPS18 admins can update enquiries" on public.enquiries;
create policy "PPS18 admins can update enquiries"
on public.enquiries for update to authenticated
using (public.pps18_is_admin())
with check (public.pps18_is_admin());
grant insert on public.enquiries to anon, authenticated;
grant select, update on public.enquiries to authenticated;

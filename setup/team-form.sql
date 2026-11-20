-- h0p3 Documents: one-time setup for the public team details form (join.html).
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.
-- Anyone with the link can SEND details, but cannot read anything back.
-- Only the founder (profiles.is_admin = true) can see, change or delete people.

alter table public.people enable row level security;

-- Allow the "New from form" status, in case a status check exists
alter table public.people drop constraint if exists people_status_check;

-- Remove any older policies on people so only the ones below apply
do $$
declare pol record;
begin
  for pol in select policyname from pg_policies where schemaname = 'public' and tablename = 'people' loop
    execute format('drop policy %I on public.people', pol.policyname);
  end loop;
end $$;

-- Founder: full access
create policy "Founder manages people" on public.people
  for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

-- Team form: insert only. Role, CV and notes must be empty; status is fixed.
create policy "Team form can submit" on public.people
  for insert to anon, authenticated
  with check (
    role is null
    and cv_document_id is null
    and notes is null
    and status = 'New from form'
    and joined_as = 'Team'
  );

grant insert on public.people to anon;

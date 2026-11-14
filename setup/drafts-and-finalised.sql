-- h0p3 Documents: one-time setup for the Drafts and Finalised tabs.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.
-- Only the founder (profiles.is_admin = true) can see or change these documents.

create table if not exists public.work_docs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text,
  notes text,
  status text not null default 'draft' check (status in ('draft', 'final')),
  file_name text,
  storage_path text,
  size_bytes bigint,
  mime_type text,
  draft_file_name text,
  draft_storage_path text,
  finalised_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.work_docs enable row level security;

drop policy if exists "Founder manages drafts" on public.work_docs;
create policy "Founder manages drafts" on public.work_docs
  for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

-- Private storage bucket for draft and final files
insert into storage.buckets (id, name, public)
values ('h0p3-drafts', 'h0p3-drafts', false)
on conflict (id) do nothing;

drop policy if exists "Founder manages draft files" on storage.objects;
create policy "Founder manages draft files" on storage.objects
  for all to authenticated
  using (bucket_id = 'h0p3-drafts' and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin))
  with check (bucket_id = 'h0p3-drafts' and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

-- h0p3 Documents: one-time setup for the Receipts tab.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.
-- Only the founder (profiles.is_admin = true) can see or change receipts.

create table if not exists public.receipts (
  id uuid primary key default gen_random_uuid(),
  receipt_date date not null,
  initiative text not null,
  vendor text,
  amount numeric(12,2) check (amount is null or amount >= 0),
  description text,
  file_name text,
  storage_path text,
  size_bytes bigint,
  mime_type text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists receipts_date_idx on public.receipts (receipt_date desc);

alter table public.receipts enable row level security;

drop policy if exists "Founder manages receipts" on public.receipts;
create policy "Founder manages receipts" on public.receipts
  for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

-- Private storage bucket for receipt photos and PDFs (filed as year/month/...)
insert into storage.buckets (id, name, public)
values ('h0p3-receipts', 'h0p3-receipts', false)
on conflict (id) do nothing;

drop policy if exists "Founder manages receipt files" on storage.objects;
create policy "Founder manages receipt files" on storage.objects
  for all to authenticated
  using (bucket_id = 'h0p3-receipts' and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin))
  with check (bucket_id = 'h0p3-receipts' and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

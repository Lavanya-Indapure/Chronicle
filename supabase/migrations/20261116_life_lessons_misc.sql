-- Chronicle — Life Lessons + Miscellaneous
-- Run once in the Supabase SQL editor. Safe to re-run (idempotent).
--
-- Creates:
--   * public.life_lessons   (text + tags, favourites, soft delete)
--   * public.misc_items     (text and/or one image, soft delete)
--   * storage bucket 'misc' (private; files live under '<user_id>/...')

-- ── Shared: updated_at trigger ──
create or replace function public.chronicle_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ── Life lessons ──
create table if not exists public.life_lessons (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title       text,
  content     text not null check (length(btrim(content)) > 0),
  tags        text[] not null default '{}',
  is_favorite boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create index if not exists life_lessons_user_created_idx
  on public.life_lessons (user_id, created_at desc)
  where deleted_at is null;

drop trigger if exists life_lessons_set_updated_at on public.life_lessons;
create trigger life_lessons_set_updated_at
  before update on public.life_lessons
  for each row execute function public.chronicle_touch_updated_at();

alter table public.life_lessons enable row level security;

drop policy if exists "life_lessons_select_own" on public.life_lessons;
create policy "life_lessons_select_own" on public.life_lessons
  for select using (auth.uid() = user_id);

drop policy if exists "life_lessons_insert_own" on public.life_lessons;
create policy "life_lessons_insert_own" on public.life_lessons
  for insert with check (auth.uid() = user_id);

drop policy if exists "life_lessons_update_own" on public.life_lessons;
create policy "life_lessons_update_own" on public.life_lessons
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "life_lessons_delete_own" on public.life_lessons;
create policy "life_lessons_delete_own" on public.life_lessons
  for delete using (auth.uid() = user_id);

-- ── Miscellaneous ──
create table if not exists public.misc_items (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title        text,
  content      text,
  storage_path text, -- object path in the 'misc' bucket: '<user_id>/<file>'
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  constraint misc_items_has_body check (
    nullif(btrim(coalesce(content, '')), '') is not null or storage_path is not null
  )
);

create index if not exists misc_items_user_created_idx
  on public.misc_items (user_id, created_at desc)
  where deleted_at is null;

drop trigger if exists misc_items_set_updated_at on public.misc_items;
create trigger misc_items_set_updated_at
  before update on public.misc_items
  for each row execute function public.chronicle_touch_updated_at();

alter table public.misc_items enable row level security;

drop policy if exists "misc_items_select_own" on public.misc_items;
create policy "misc_items_select_own" on public.misc_items
  for select using (auth.uid() = user_id);

drop policy if exists "misc_items_insert_own" on public.misc_items;
create policy "misc_items_insert_own" on public.misc_items
  for insert with check (auth.uid() = user_id);

drop policy if exists "misc_items_update_own" on public.misc_items;
create policy "misc_items_update_own" on public.misc_items
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "misc_items_delete_own" on public.misc_items;
create policy "misc_items_delete_own" on public.misc_items
  for delete using (auth.uid() = user_id);

-- ── Storage: private 'misc' bucket ──
insert into storage.buckets (id, name, public)
values ('misc', 'misc', false)
on conflict (id) do nothing;

-- Each user can only touch files under their own '<user_id>/' folder
-- (same layout as the photos and restaurants buckets).
drop policy if exists "misc_objects_select_own" on storage.objects;
create policy "misc_objects_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'misc' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "misc_objects_insert_own" on storage.objects;
create policy "misc_objects_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'misc' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "misc_objects_update_own" on storage.objects;
create policy "misc_objects_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'misc' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "misc_objects_delete_own" on storage.objects;
create policy "misc_objects_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'misc' and (storage.foldername(name))[1] = auth.uid()::text);

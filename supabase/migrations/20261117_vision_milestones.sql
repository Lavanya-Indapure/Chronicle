-- Chronicle — Vision board milestones
-- Run once in the Supabase SQL editor. Safe to re-run (idempotent).
--
-- Creates:
--   * public.vision_milestones (ordered checklist per vision goal)
-- A goal's progress is computed in the app from its milestones and written
-- back to public.vision_board.progress.

-- ── Shared: updated_at trigger (also created by 20261116_life_lessons_misc) ──
create or replace function public.chronicle_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ── Milestones ──
create table if not exists public.vision_milestones (
  id         uuid primary key default gen_random_uuid(),
  goal_id    uuid not null references public.vision_board (id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title      text not null check (length(btrim(title)) > 0),
  is_done    boolean not null default false,
  done_at    timestamptz,
  position   integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists vision_milestones_goal_position_idx
  on public.vision_milestones (goal_id, position);

create index if not exists vision_milestones_user_idx
  on public.vision_milestones (user_id);

drop trigger if exists vision_milestones_set_updated_at on public.vision_milestones;
create trigger vision_milestones_set_updated_at
  before update on public.vision_milestones
  for each row execute function public.chronicle_touch_updated_at();

alter table public.vision_milestones enable row level security;

drop policy if exists "vision_milestones_select_own" on public.vision_milestones;
create policy "vision_milestones_select_own" on public.vision_milestones
  for select using (auth.uid() = user_id);

-- Inserts must also target one of the user's own goals.
drop policy if exists "vision_milestones_insert_own" on public.vision_milestones;
create policy "vision_milestones_insert_own" on public.vision_milestones
  for insert with check (
    auth.uid() = user_id
    and exists (select 1 from public.vision_board g where g.id = goal_id and g.user_id = auth.uid())
  );

drop policy if exists "vision_milestones_update_own" on public.vision_milestones;
create policy "vision_milestones_update_own" on public.vision_milestones
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "vision_milestones_delete_own" on public.vision_milestones;
create policy "vision_milestones_delete_own" on public.vision_milestones
  for delete using (auth.uid() = user_id);

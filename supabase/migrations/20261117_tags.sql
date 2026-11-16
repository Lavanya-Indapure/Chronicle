-- Chronicle — Tags everywhere
-- Run once in the Supabase SQL editor. Safe to re-run (idempotent).
--
-- Does:
--   * adds `tags text[]` to books, learnings, movies
--   * converts thoughts.tags from comma-separated `text` to `text[]`
--     ("motivation, life" → {motivation,life}; also handles values written
--     as a JSON array string, e.g. '["a","b"]')
--   * GIN indexes on every tags column, for the global search tag filter
--
-- The app reads both the old and new thoughts format, so app and migration
-- can be deployed in either order; tag *writes* on books/learnings/movies
-- need this migration.

-- ── New tag columns ──
alter table public.books     add column if not exists tags text[] not null default '{}';
alter table public.learnings add column if not exists tags text[] not null default '{}';
alter table public.movies    add column if not exists tags text[] not null default '{}';

-- ── thoughts.tags: text → text[] ──
-- USING can't contain a subquery, so convert through a temporary column.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'thoughts'
      and column_name = 'tags' and data_type = 'text'
  ) then
    alter table public.thoughts add column tags_array text[] not null default '{}';

    -- Split, trim spaces and a leading '#', drop blanks and case-insensitive
    -- duplicates (first spelling wins), keep the original order.
    update public.thoughts
    set tags_array = array(
      select t from (
        select distinct on (lower(t)) t, n
        from (
          select btrim(x, ' #') as t, n
          from unnest(
            case
              when btrim(tags) like '[%' then array(select jsonb_array_elements_text(btrim(tags)::jsonb))
              else string_to_array(tags, ',')
            end
          ) with ordinality as u(x, n)
        ) split
        where t <> ''
        order by lower(t), n
      ) deduped
      order by n
    )
    where tags is not null and btrim(tags) <> '';

    alter table public.thoughts drop column tags;
    alter table public.thoughts rename column tags_array to tags;
  end if;
end
$$;

-- In case thoughts.tags was already an array but nullable / without default.
update public.thoughts set tags = '{}' where tags is null;
alter table public.thoughts alter column tags set default '{}';
alter table public.thoughts alter column tags set not null;

-- ── GIN indexes (array overlap / contains) ──
create index if not exists books_tags_gin_idx        on public.books        using gin (tags);
create index if not exists learnings_tags_gin_idx    on public.learnings    using gin (tags);
create index if not exists movies_tags_gin_idx       on public.movies       using gin (tags);
create index if not exists thoughts_tags_gin_idx     on public.thoughts     using gin (tags);
create index if not exists life_lessons_tags_gin_idx on public.life_lessons using gin (tags);

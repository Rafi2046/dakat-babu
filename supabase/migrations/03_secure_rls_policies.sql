-- ============================================================================
-- DakatBabu - Migration 03: Secure Scoped Row Level Security (RLS) Policies
-- Replaces broad "using (true)" write policies with strict auth.uid() scoping.
-- Run this in Supabase SQL Editor.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Drop all legacy permissive policies
-- ----------------------------------------------------------------------------
drop policy if exists "Allow public read on rooms" on public.rooms;
drop policy if exists "Allow public insert on rooms" on public.rooms;
drop policy if exists "Allow public update on rooms" on public.rooms;
drop policy if exists "Allow public delete on rooms" on public.rooms;

drop policy if exists "Allow public read on players" on public.players;
drop policy if exists "Allow public insert on players" on public.players;
drop policy if exists "Allow public update on players" on public.players;
drop policy if exists "Allow public delete on players" on public.players;

drop policy if exists "Allow public read on game_rounds" on public.game_rounds;
drop policy if exists "Allow public insert on game_rounds" on public.game_rounds;
drop policy if exists "Allow public update on game_rounds" on public.game_rounds;
drop policy if exists "Allow public delete on game_rounds" on public.game_rounds;

-- Clean up any previous iterations of secure policies
drop policy if exists "Allow authenticated insert on rooms" on public.rooms;
drop policy if exists "Allow host and room players update on rooms" on public.rooms;
drop policy if exists "Allow host delete on rooms" on public.rooms;

drop policy if exists "Allow player insert own record" on public.players;
drop policy if exists "Allow player host or police update on players" on public.players;
drop policy if exists "Allow player or host delete on players" on public.players;

drop policy if exists "Allow host insert on game_rounds" on public.game_rounds;
drop policy if exists "Allow police or host update on game_rounds" on public.game_rounds;
drop policy if exists "Allow host delete on game_rounds" on public.game_rounds;

-- ----------------------------------------------------------------------------
-- 2. Rooms Table Security
-- ----------------------------------------------------------------------------
-- SELECT: Public read is kept so players can discover rooms and view lobby state
create policy "Allow public read on rooms"
  on public.rooms for select
  using (true);

-- INSERT: Authenticated anonymous user creating a room as host
create policy "Allow authenticated insert on rooms"
  on public.rooms for insert
  with check (
    auth.uid() is not null
    and (
      (auth.uid())::text = split_part(host_id, '_', 1)
      or host_id = (auth.uid())::text
    )
  );

-- UPDATE: Host can modify room; active room players can update status for game events (e.g. player_left, roundEnded)
create policy "Allow host and room players update on rooms"
  on public.rooms for update
  using (
    (auth.uid())::text = split_part(host_id, '_', 1)
    or host_id = (auth.uid())::text
    or exists (
      select 1 from public.players p
      where p.room_code = rooms.room_code
        and (
          (auth.uid())::text = split_part(p.id, '_', 1)
          or p.id = (auth.uid())::text
        )
    )
  );

-- DELETE: Only the host of the room can delete/disband it
create policy "Allow host delete on rooms"
  on public.rooms for delete
  using (
    (auth.uid())::text = split_part(host_id, '_', 1)
    or host_id = (auth.uid())::text
  );

-- ----------------------------------------------------------------------------
-- 3. Players Table Security
-- ----------------------------------------------------------------------------
-- SELECT: Public read allows participants to view lobby and court members
create policy "Allow public read on players"
  on public.players for select
  using (true);

-- INSERT: Player can only register their own player record matching their auth.uid()
create policy "Allow player insert own record"
  on public.players for insert
  with check (
    auth.uid() is not null
    and (
      (auth.uid())::text = split_part(id, '_', 1)
      or id = (auth.uid())::text
    )
  );

-- UPDATE:
-- 1) Player can update their own record (ready toggle, name, avatar)
-- 2) Host can assign roles at round start, reset roles on return to lobby, or transfer host
-- 3) Police player of the active round can distribute points to participants upon deduction
create policy "Allow player host or police update on players"
  on public.players for update
  using (
    (auth.uid())::text = split_part(id, '_', 1)
    or id = (auth.uid())::text
    or exists (
      select 1 from public.rooms r
      where r.room_code = players.room_code
        and (
          (auth.uid())::text = split_part(r.host_id, '_', 1)
          or r.host_id = (auth.uid())::text
        )
    )
    or exists (
      select 1 from public.game_rounds gr
      where gr.room_code = players.room_code
        and (
          (auth.uid())::text = split_part(gr.police_player_id, '_', 1)
          or gr.police_player_id = (auth.uid())::text
        )
    )
  );

-- DELETE: Player can leave the room (delete own row), or Host can remove/kick a player
create policy "Allow player or host delete on players"
  on public.players for delete
  using (
    (auth.uid())::text = split_part(id, '_', 1)
    or id = (auth.uid())::text
    or exists (
      select 1 from public.rooms r
      where r.room_code = players.room_code
        and (
          (auth.uid())::text = split_part(r.host_id, '_', 1)
          or r.host_id = (auth.uid())::text
        )
    )
  );

-- ----------------------------------------------------------------------------
-- 4. Game Rounds Table Security
-- ----------------------------------------------------------------------------
-- SELECT: Public read so all room members see round progress and reveal outcomes
create policy "Allow public read on game_rounds"
  on public.game_rounds for select
  using (true);

-- INSERT: Host of the room creates game rounds
create policy "Allow host insert on game_rounds"
  on public.game_rounds for insert
  with check (
    exists (
      select 1 from public.rooms r
      where r.room_code = game_rounds.room_code
        and (
          (auth.uid())::text = split_part(r.host_id, '_', 1)
          or r.host_id = (auth.uid())::text
        )
    )
  );

-- UPDATE: Only Police player can submit suspect deduction, or Host managing round lifecycle
create policy "Allow police or host update on game_rounds"
  on public.game_rounds for update
  using (
    (auth.uid())::text = split_part(police_player_id, '_', 1)
    or police_player_id = (auth.uid())::text
    or exists (
      select 1 from public.rooms r
      where r.room_code = game_rounds.room_code
        and (
          (auth.uid())::text = split_part(r.host_id, '_', 1)
          or r.host_id = (auth.uid())::text
        )
    )
  );

-- DELETE: Host can clean up game rounds when room is disbanded
create policy "Allow host delete on game_rounds"
  on public.game_rounds for delete
  using (
    exists (
      select 1 from public.rooms r
      where r.room_code = game_rounds.room_code
        and (
          (auth.uid())::text = split_part(r.host_id, '_', 1)
          or r.host_id = (auth.uid())::text
        )
    )
  );

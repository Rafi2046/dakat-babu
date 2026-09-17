-- ============================================================================
-- DakatBabu - Multiplayer Chor-Police-Raja-Mantri Game
-- Supabase Database Schema & Realtime Setup
-- ============================================================================

-- 1. Clean up existing tables if recreating
drop table if exists public.game_rounds cascade;
drop table if exists public.players cascade;
drop table if exists public.rooms cascade;

-- 2. Rooms Table
create table public.rooms (
  id text primary key,
  room_code text not null unique,
  host_id text not null,
  status text not null default 'waiting',
  current_round integer not null default 0,
  max_rounds integer not null default 5,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone
);

-- 3. Players Table
create table public.players (
  id text primary key,
  room_code text not null references public.rooms(room_code) on delete cascade,
  name text not null,
  avatar_url text,
  is_host boolean not null default false,
  role text,
  score integer not null default 0,
  is_ready boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Game Rounds Table
create table public.game_rounds (
  id text primary key,
  room_code text not null references public.rooms(room_code) on delete cascade,
  round_number integer not null default 1,
  raja_player_id text not null,
  mantri_player_id text not null,
  police_player_id text not null,
  chor_player_id text not null,
  police_guess_player_id text,
  is_guess_correct boolean,
  status text not null default 'role_reveal',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Enable Realtime Replication
alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.players;
alter publication supabase_realtime add table public.game_rounds;

-- 6. Enable Row Level Security (RLS)
alter table public.rooms enable row level security;
alter table public.players enable row level security;
alter table public.game_rounds enable row level security;

-- 7. Secure Scoped RLS Policies (auth.uid() scoped)
-- Rooms policies
create policy "Allow public read on rooms" 
  on public.rooms for select 
  using (true);

create policy "Allow authenticated insert on rooms" 
  on public.rooms for insert 
  with check (
    auth.uid() is not null
    and (
      (auth.uid())::text = split_part(host_id, '_', 1)
      or host_id = (auth.uid())::text
    )
  );

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

create policy "Allow host delete on rooms" 
  on public.rooms for delete 
  using (
    (auth.uid())::text = split_part(host_id, '_', 1)
    or host_id = (auth.uid())::text
  );

-- Players policies
create policy "Allow public read on players" 
  on public.players for select 
  using (true);

create policy "Allow player insert own record" 
  on public.players for insert 
  with check (
    auth.uid() is not null
    and (
      (auth.uid())::text = split_part(id, '_', 1)
      or id = (auth.uid())::text
    )
  );

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

-- Game Rounds policies
create policy "Allow public read on game_rounds" 
  on public.game_rounds for select 
  using (true);

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

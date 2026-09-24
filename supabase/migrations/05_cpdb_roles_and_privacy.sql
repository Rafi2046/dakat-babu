-- CPDB authoritative schema: Police / Babu / Chor / Dakat (exactly 4 players)
-- Role privacy via player_private_roles (RLS: only owner can read their role)

alter table if exists public.game_rounds
  add column if not exists babu_player_id text,
  add column if not exists dakat_player_id text;

-- Migrate legacy raja → babu, mantri → dakat when present
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_name = 'game_rounds' and column_name = 'raja_player_id'
  ) then
    update public.game_rounds
      set babu_player_id = coalesce(babu_player_id, raja_player_id)
      where babu_player_id is null;
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_name = 'game_rounds' and column_name = 'mantri_player_id'
  ) then
    update public.game_rounds
      set dakat_player_id = coalesce(dakat_player_id, mantri_player_id)
      where dakat_player_id is null;
  end if;
end $$;

create table if not exists public.player_private_roles (
  id bigserial primary key,
  player_id text not null,
  room_code text not null,
  round_number int not null,
  role text not null check (role in ('police', 'babu', 'chor', 'dakat')),
  created_at timestamptz default now(),
  unique (player_id, room_code, round_number)
);

alter table public.player_private_roles enable row level security;

drop policy if exists private_roles_select_own on public.player_private_roles;
create policy private_roles_select_own on public.player_private_roles
  for select using (auth.uid()::text = player_id);

drop policy if exists private_roles_insert_own on public.player_private_roles;
create policy private_roles_insert_own on public.player_private_roles
  for insert with check (auth.uid()::text = player_id);

-- Force rooms to 4 players for CPDB
update public.rooms set max_players = 4 where max_players is distinct from 4;

-- RPC: resolve_guess (server-side scoring authority)
create or replace function public.resolve_guess(
  p_round_id text,
  p_suspect_id text
) returns jsonb
language plpgsql
security definer
as $$
declare
  r record;
  is_correct boolean;
  recipient text;
begin
  select * into r from public.game_rounds where id = p_round_id for update;
  if not found then
    raise exception 'Round not found';
  end if;
  if r.status = 'completed' then
    raise exception 'Guess already submitted';
  end if;
  if p_suspect_id = r.police_player_id then
    raise exception 'Invalid suspect';
  end if;

  is_correct := (p_suspect_id = r.chor_player_id);
  if is_correct then
    recipient := r.police_player_id;
  else
    recipient := p_suspect_id;
  end if;

  update public.players
    set score = score + 1
    where id = recipient;

  update public.game_rounds
    set police_guess_player_id = p_suspect_id,
        is_guess_correct = is_correct,
        status = 'completed'
    where id = p_round_id;

  update public.rooms
    set status = 'round_ended'
    where room_code = r.room_code;

  return jsonb_build_object(
    'is_correct', is_correct,
    'recipient_id', recipient,
    'chor_player_id', r.chor_player_id,
    'score_delta', 1
  );
end;
$$;

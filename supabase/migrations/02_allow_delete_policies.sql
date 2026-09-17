-- ============================================================================
-- DakatBabu - Migration 02: Allow Public Delete on Rooms, Players, Game Rounds
-- Run this in Supabase SQL Editor to enable clean deletion when rooms are
-- cancelled or players leave / are removed.
-- ============================================================================

create policy "Allow public delete on rooms" 
  on public.rooms for delete 
  using (true);

create policy "Allow public delete on players" 
  on public.players for delete 
  using (true);

create policy "Allow public delete on game_rounds" 
  on public.game_rounds for delete 
  using (true);

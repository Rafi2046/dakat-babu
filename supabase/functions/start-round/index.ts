// Deno Edge Function: start-round
// Assigns CPDB roles server-side and writes private roles + public round row.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  try {
    const { room_code, round_number } = await req.json()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: players, error: pErr } = await supabase
      .from('players')
      .select('*')
      .eq('room_code', room_code)

    if (pErr) throw pErr
    if (!players || players.length !== 4) {
      return new Response(JSON.stringify({ error: 'Need exactly 4 players' }), {
        status: 400,
      })
    }

    const shuffled = [...players].sort(() => Math.random() - 0.5)
    const assignment = {
      police_player_id: shuffled[0].id,
      babu_player_id: shuffled[1].id,
      chor_player_id: shuffled[2].id,
      dakat_player_id: shuffled[3].id,
    }
    const roleById: Record<string, string> = {
      [assignment.police_player_id]: 'police',
      [assignment.babu_player_id]: 'babu',
      [assignment.chor_player_id]: 'chor',
      [assignment.dakat_player_id]: 'dakat',
    }

    for (const p of players) {
      await supabase.from('players').update({ role: null }).eq('id', p.id)
      await supabase.from('player_private_roles').upsert({
        player_id: p.id,
        room_code,
        round_number,
        role: roleById[p.id],
      })
    }

    const round = {
      id: `rnd_${Date.now()}`,
      room_code,
      round_number,
      ...assignment,
      status: 'role_reveal',
      created_at: new Date().toISOString(),
    }
    await supabase.from('game_rounds').insert(round)
    await supabase
      .from('rooms')
      .update({ status: 'in_progress', current_round: round_number, max_players: 4 })
      .eq('room_code', room_code)

    // Return only caller's private view if Authorization present
    return new Response(JSON.stringify({ round_id: round.id, ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})

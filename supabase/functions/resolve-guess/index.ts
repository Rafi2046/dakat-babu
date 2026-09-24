// Deno Edge Function: resolve-guess — delegates to SQL RPC
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  try {
    const { round_id, suspect_id } = await req.json()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )
    const { data, error } = await supabase.rpc('resolve_guess', {
      p_round_id: round_id,
      p_suspect_id: suspect_id,
    })
    if (error) throw error
    return new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})

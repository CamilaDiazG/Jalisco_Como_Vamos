import { loadCorpus, retrieve, renderSelection, selectSources, unsupportedScope, QuotaExceededError } from './core.mjs';

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json', 'Cache-Control': 'no-store',
};
const reply = (status, body) => new Response(JSON.stringify(body), { status, headers });

export function createHandler({ createClient, env, select = selectSources }) {
  return async req => {
    if (req.method === 'OPTIONS') return new Response(null, { headers });
    if (req.method !== 'POST') return reply(405, { error: 'Método no permitido' });
    try {
      const authorization = req.headers.get('Authorization');
      if (!/^Bearer \S+$/i.test(authorization ?? '')) return reply(401, { error: 'Sesión requerida' });
      const client = createClient(env('SUPABASE_URL'), env('SUPABASE_ANON_KEY'), {
        global: { headers: { Authorization: authorization }, fetch: (url, options) => fetch(url, { ...options, signal: AbortSignal.timeout(15000) }) },
        auth: { persistSession: false, autoRefreshToken: false },
      });
      const { data, error } = await client.auth.getUser(authorization.slice(7));
      if (error || !data?.user) return reply(401, { error: 'Sesión inválida' });
      const permission = await client.rpc('jcv_ask_authorized');
      if (permission.error) return reply(503, { error: 'No se pudo verificar autorización' });
      if (permission.data !== true) return reply(403, { error: 'Lector no autorizado' });
      // Preserve any extra restrictions imposed by the existing backend.
      const catalog = await client.rpc('jcv_catalogos');
      if (catalog.error) return reply(catalog.error.code === '42501' ? 403 : 503, { error: 'Catálogo no disponible' });
      let raw = '';
      let bytes = 0;
      const reader = req.body?.getReader();
      const decoder = new TextDecoder();
      if (reader) {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          bytes += value.byteLength;
          if (bytes > 8192) { await reader.cancel(); return reply(413, { error: 'Solicitud demasiado larga' }); }
          raw += decoder.decode(value, { stream: true });
        }
        raw += decoder.decode();
      }
      let body;
      try { body = JSON.parse(raw); } catch { return reply(400, { error: 'JSON inválido' }); }
      if (!body || typeof body.question !== 'string' || !body.question.trim() || body.question.length > 2000 ||
          typeof body.case_id !== 'string' || !/^[A-Za-z0-9_-]{1,100}$/.test(body.case_id) ||
          Object.keys(body).some(k => !['question', 'case_id'].includes(k))) return reply(400, { error: 'question o case_id inválido' });
      // case_id is transport metadata only: never a retrieval key or model input.
      const corpus = await loadCorpus(async (name, params) => {
        const result = await client.rpc(name, params);
        if (result.error) throw new Error('Aggregate unavailable');
        return result.data;
      });
      const retrieved = retrieve(body.question, corpus);
      if (!retrieved.length || retrieved.some(s => !s.available) || unsupportedScope(body.question, catalog.data)) {
        return reply(200, renderSelection(null, retrieved));
      }
      const apiKey = env('GEMINI_API_KEY');
      if (!apiKey) return reply(503, { error: 'Proveedor de IA sin configurar' });
      const selection = await select(body.question, retrieved, apiKey);
      return reply(200, renderSelection(selection, retrieved));
    } catch (error) {
      if (error instanceof QuotaExceededError) {
        return reply(429, { code: 'AI_QUOTA_EXCEEDED', error: 'La cuota de IA está agotada temporalmente. Intenta más tarde.' });
      }
      // Do not log questions, session tokens, credentials, or provider bodies.
      return reply(502, { error: 'No se pudo completar la consulta' });
    }
  };
}

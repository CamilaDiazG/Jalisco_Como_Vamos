import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
  'Cache-Control': 'no-store',
};
const reply = (status: number, body: unknown) => new Response(JSON.stringify(body), { status, headers });

// Lista cerrada: ningún nombre RPC, SQL o parámetro procede del texto del usuario.
const temas: [RegExp, string][] = [
  [/bienestar|felicidad|feliz|satisfaccion|salud mental/, 'bienestar'],
  [/educacion|estudio|trabajo/, 'educacion_trabajo'],
  [/salud/, 'salud'], [/seguridad/, 'seguridad'],
  [/tiempo libre/, 'tiempo_libre'], [/hogar|familia/, 'hogar_familia'],
  [/comunidad/, 'comunidad'], [/transporte/, 'transporte'],
];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers });
  if (req.method !== 'POST') return reply(405, { error: 'Método no permitido' });
  try {
    const auth = req.headers.get('Authorization');
    if (!auth?.startsWith('Bearer ')) return reply(401, { error: 'Sesión requerida' });
    const client = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: auth } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: user, error: authError } = await client.auth.getUser();
    if (authError || !user.user) return reply(401, { error: 'Sesión inválida' });
    const raw = await req.text();
    if (raw.length > 4096) return reply(413, { error: 'Solicitud demasiado larga' });
    let body;
    try { body = JSON.parse(raw); } catch { return reply(400, { error: 'JSON inválido' }); }
    if (!body || typeof body.pregunta !== 'string' || !body.pregunta.trim() || body.pregunta.length > 500 ||
        !['AMG', 'TEC'].includes(body.fuente)) return reply(400, { error: 'Pregunta o fuente inválida' });
    const texto = body.pregunta.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
    const tema = temas.find(([patron]) => patron.test(texto))?.[1];
    if (!tema) return reply(200, { respuesta: 'No puedo resolver esa pregunta con los agregados disponibles. Indica una dimensión: bienestar, salud, educación y trabajo, seguridad, tiempo libre, hogar y familia, comunidad o transporte.' });
    const rpc = tema === 'bienestar' ? 'jcv_resumen_bienestar' : 'jcv_dimension';
    const params = { p_fuente: body.fuente, p_municipio: null, p_grupo_edad: null,
      ...(tema === 'bienestar' ? {} : { p_dimension: tema }) };
    // Usa el JWT del usuario: los permisos de lector se verifican dentro de las RPC existentes.
    const { data, error } = await client.rpc(rpc, params);
    if (error) return reply(error.code === '42501' ? 403 : 502, { error: 'Agregado no disponible' });
    const filas = tema === 'bienestar' ? data : data?.preguntas;
    if (!Array.isArray(filas)) return reply(502, { error: 'Contrato de agregado inválido' });
    const lineas = filas.map((fila) => {
      const titulo = fila.titulo ?? fila.indicador;
      if (fila.estado !== 'ok') return `${titulo}: ${fila.estado === 'muestra_insuficiente' ? 'muestra insuficiente; porcentaje no publicado' : 'sin datos'}.`;
      if (tema === 'bienestar') return `${titulo}: ${fila.porcentaje == null ? 'sin datos' : Number(fila.porcentaje).toFixed(2) + '%'} (${fila.etiqueta_positiva}).`;
      return `${titulo}:\n${fila.categorias.map((c: { etiqueta: string; porcentaje: number | null }) =>
        `• ${c.etiqueta}: ${c.porcentaje == null ? 'no publicado' : Number(c.porcentaje).toFixed(2) + '%'}`).join('\n')}\n${fila.denominador}`;
    });
    return reply(200, { respuesta: `Resultados disponibles relacionados con tu pregunta.\nFuente: ${body.fuente} · Todas las edades disponibles · Sin filtro municipal.\nNo se aplican otros filtros mencionados en el texto ni se infieren causas o comparaciones.\n\n${lineas.join('\n\n') || 'Sin datos disponibles.'}\n\nOrigen: ${rpc}. ${body.fuente === 'AMG' ? 'Porcentajes ponderados.' : 'Participantes Tec; no representa al AMG.'}`, rpc, fuente: body.fuente });
  } catch {
    return reply(500, { error: 'No se pudo consultar el servicio' });
  }
});

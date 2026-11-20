'use strict';

async function ask({ question, case_id }, { fetcher = fetch, env = process.env } = {}) {
  if (typeof question !== 'string' || !question.trim() || typeof case_id !== 'string' || !case_id) {
    throw new Error('Se requieren question y case_id');
  }
  const { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, JCV_ACCESS_TOKEN } = env;
  if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY || !JCV_ACCESS_TOKEN) {
    throw new Error('Configura SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY y JCV_ACCESS_TOKEN (sesión de lector)');
  }
  const url = new URL(SUPABASE_URL);
  if (url.protocol !== 'https:' && !['localhost', '127.0.0.1'].includes(url.hostname)) throw new Error('Se requiere HTTPS');
  const response = await fetcher(`${url.origin}/functions/v1/ask`, {
    method: 'POST', signal: AbortSignal.timeout(90000),
    headers: { Authorization: `Bearer ${JCV_ACCESS_TOKEN}`, apikey: SUPABASE_PUBLISHABLE_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ question, case_id }),
  });
  if (!response.ok) throw new Error(`ask HTTP ${response.status}`);
  const data = await response.json();
  if (typeof data.answer !== 'string' || !data.answer.trim() ||
      !Array.isArray(data.citations) || !Array.isArray(data.retrieved_source_ids) ||
      [...data.citations, ...data.retrieved_source_ids].some(id => typeof id !== 'string') ||
      new Set(data.citations).size !== data.citations.length ||
      new Set(data.retrieved_source_ids).size !== data.retrieved_source_ids.length ||
      data.citations.some(id => !data.retrieved_source_ids.includes(id)) ||
      (data.cost_usd !== undefined && (typeof data.cost_usd !== 'number' || !Number.isFinite(data.cost_usd) || data.cost_usd < 0))) {
    throw new Error('Contrato de ask inválido');
  }
  const abstention = 'No tengo datos suficientes en las fuentes disponibles para responder.';
  if ((data.answer === abstention && data.citations.length !== 0) ||
      (data.answer !== abstention && data.citations.length === 0)) throw new Error('Respuesta sin respaldo');
  // Do not infer retrieved IDs from citations; preserve the backend's evidence.
  return { answer: data.answer, citations: data.citations, retrieved_source_ids: data.retrieved_source_ids,
    ...(data.cost_usd === undefined ? {} : { cost_usd: data.cost_usd }) };
}

// CSV is read only by the evaluation process, never by the Edge Function.
function parseCsv(input) {
  const rows = []; let row = [], cell = '', quoted = false;
  const source = input.replace(/^\uFEFF/, '');
  for (let i = 0; i < source.length; i++) {
    const c = source[i];
    if (c === '"') {
      if (quoted && source[i + 1] === '"') { cell += '"'; i++; } else quoted = !quoted;
    } else if (!quoted && (c === ',' || c === '\n' || c === '\r')) {
      row.push(cell); cell = '';
      if (c !== ',') {
        if (c === '\r' && source[i + 1] === '\n') i++;
        if (row.some(value => value !== '')) rows.push(row);
        row = [];
      }
    } else cell += c;
  }
  if (quoted) throw new Error('CSV sin cerrar');
  if (cell || row.length) { row.push(cell); rows.push(row); }
  return rows;
}

module.exports = { ask, parseCsv };

if (require.main === module) {
  (async () => {
    const args = process.argv.slice(2);
    const value = flag => args[args.indexOf(flag) + 1];
    if (!args.includes('--smoke') || !args.includes('--case') || value('--case') !== 'CD-06') {
      throw new Error('Solo está habilitado --smoke --case CD-06; no se ejecutan los 279 intentos');
    }
    const fs = require('node:fs');
    const filename = args.includes('--cases') ? value('--cases') : 'evals/cases.csv';
    if (!fs.existsSync(filename)) throw new Error(`Falta ${filename}; no se inventará CD-06`);
    const [header, ...rows] = parseCsv(fs.readFileSync(filename, 'utf8'));
    const idIndex = header?.indexOf('case_id');
    const questionIndex = header?.indexOf('question');
    if (!(idIndex >= 0 && questionIndex >= 0)) throw new Error('CSV requiere columnas case_id,question');
    const cases = rows.filter(row => row[idIndex] === 'CD-06');
    if (cases.length !== 1) throw new Error('Debe existir exactamente un caso CD-06');
    const result = await ask({ question: cases[0][questionIndex], case_id: 'CD-06' });
    console.log(JSON.stringify({ case_id: 'CD-06', ...result }, null, 2));
  })().catch(error => { console.error(error.message); process.exitCode = 1; });
}

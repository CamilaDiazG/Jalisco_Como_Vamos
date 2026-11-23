import test from 'node:test';
import assert from 'node:assert/strict';
import { ABSTENTION, buildSources, retrieve, renderSelection, selectSources, loadCorpus, unsupportedScope, QuotaExceededError } from '../supabase/functions/ask/core.mjs';
import { createHandler } from '../supabase/functions/ask/handler.mjs';
import provider from './provider.js';
import originalProvider from '../jcvevals/evals/provider.js';

// Synthetic aggregate fixtures; not survey results or evaluation ground truth.
const row = { variable: 'test_felicidad', indicador: 'felicidad', etiqueta_positiva: 'Feliz',
  fuente: 'AMG', ponderado: true, estado: 'ok', n_validas: 30, n_muestra: 40, porcentaje: 50 };
const sources = () => buildSources('bienestar', [row]);
test('stable IDs survive percentage updates and corpus ordering', () => {
  assert.equal(sources()[0].id, buildSources('bienestar', [{ ...row, porcentaje: 60 }])[0].id);
  assert.deepEqual(retrieve('felicidad', sources()).map(s => s.id), sources().map(s => s.id));
  assert.deepEqual(retrieve('astronomía', sources()), []);
});
test('n<30 and missing counts never expose values, even if estado says ok', () => {
  for (const n of [0, 29, null, undefined, -1]) {
    const s = buildSources('bienestar', [{ ...row, n_validas: n }]);
    assert.equal(s[0].available, false);
    assert.equal(s[0].excerpt, ABSTENTION);
    assert.ok(!JSON.stringify(s).includes('50'));
    assert.equal(renderSelection({ sufficient: true, citations: [s[0].id] }, s).answer, ABSTENTION);
  }
  assert.equal(sources()[0].available, true);
});
test('citations cannot escape backend retrieval; model prose is never returned', () => {
  const s = sources();
  for (const selection of [null, { sufficient: true, citations: ['fake'] },
    { sufficient: false, citations: [s[0].id] }, { sufficient: true, citations: [] },
    { sufficient: true, citations: [s[0].id, s[0].id] }]) {
    assert.deepEqual(renderSelection(selection, s), { answer: ABSTENTION, citations: [], retrieved_source_ids: [s[0].id] });
  }
  const result = renderSelection({ sufficient: true, citations: [s[0].id], answer: 'Inventado 99%' }, s);
  assert.ok(result.answer.includes('50%'));
  assert.ok(!result.answer.includes('99%'));
  assert.ok(!('cost_usd' in result));
});
test('malformed, wrong-population aggregates and duplicate IDs fail closed', async () => {
  assert.throws(() => buildSources('bienestar', [{ ...row, fuente: 'TEC' }]));
  assert.throws(() => buildSources('bienestar', [{ ...row, porcentaje: 101 }]));
  await assert.rejects(loadCorpus(async name => name === 'jcv_dimension' ? {} : [row]));
  await assert.rejects(loadCorpus(async (name, params) => name === 'jcv_dimension'
    ? { id: params.p_dimension, fuente: 'AMG', preguntas: [] } : [row, row]));
});
function fixture({ user = true, reader = true, permissionError = null, select, env = () => 'test' } = {}) {
  const calls = [];
  const client = { auth: { getUser: async () => ({ data: { user: user ? { id: 'reader' } : null } }) },
    rpc: async (name, params) => {
      calls.push(name);
      if (name === 'jcv_ask_authorized') return { data: reader, error: permissionError };
      if (name === 'jcv_catalogos') return { data: {} };
      return { data: name === 'jcv_resumen_bienestar' ? [row] : { id: params.p_dimension, fuente: 'AMG', preguntas: [] } };
    } };
  const handler = createHandler({ createClient: () => client, env,
    select: select ?? (async () => ({ sufficient: true, citations: [sources()[0].id] })) });
  return { handler, calls };
}
const request = (body = { question: 'felicidad', case_id: 'unit' }, token = true) => new Request('https://local/ask', {
  method: 'POST', headers: token ? { Authorization: 'Bearer test' } : {}, body: JSON.stringify(body),
});
test('missing/expired session and non-reader denied before retrieval/model', async () => {
  const absent = fixture();
  assert.equal((await absent.handler(request(undefined, false))).status, 401);
  assert.deepEqual(absent.calls, []);
  for (const [config, status] of [[{ user: false }, 401], [{ reader: false }, 403], [{ permissionError: {} }, 503]]) {
    const f = fixture(config);
    assert.equal((await f.handler(request())).status, status);
    assert.ok(!f.calls.includes('jcv_resumen_bienestar'));
  }
});
test('request validation and backend retrieval independent of case ID', async () => {
  const f = fixture();
  assert.equal((await f.handler(request({ question: '', case_id: 'unit' }))).status, 400);
  assert.equal((await f.handler(request({ question: 'x', case_id: 'unit', sources: [] }))).status, 400);
  assert.equal((await f.handler(request({ question: 'x'.repeat(9000), case_id: 'unit' }))).status, 413);
  const a = await (await f.handler(request())).json();
  const b = await (await f.handler(request({ question: 'felicidad', case_id: 'different' }))).json();
  assert.deepEqual(a, b);
  assert.equal(a.retrieved_source_ids.length, 1);
});
test('no relevant sources means exact abstention without a model call', async () => {
  const f = fixture({ select: () => { throw new Error('must not call'); } });
  const response = await f.handler(request({ question: 'astronomía', case_id: 'unit' }));
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { answer: ABSTENTION, citations: [], retrieved_source_ids: [] });
});
test('unsupported groups and years cannot be replaced by the full AMG sample', async () => {
  const f = fixture({ select: () => { throw new Error('must not call'); } });
  for (const question of ['felicidad mujeres', 'felicidad de 18 a 24 años', 'felicidad Tec', 'felicidad en 2025']) {
    const response = await f.handler(request({ question, case_id: 'unit' }));
    assert.equal(response.status, 200);
    assert.equal((await response.json()).answer, ABSTENTION);
  }
  assert.equal(unsupportedScope('felicidad en Zapopan', { municipios: [{ nombre: 'Zapopan' }] }), true);
  assert.equal(unsupportedScope('felicidad AMG 2026', {}), false);
});
test('upstream failures are errors, not successful abstentions', async () => {
  const f = fixture({ select: () => { throw new Error('secret provider error'); } });
  const response = await f.handler(request());
  assert.equal(response.status, 502);
  assert.ok(!(await response.text()).includes('secret'));
});
const geminiResponse = selection => ({ candidates: [{ finishReason: 'STOP',
  content: { parts: [{ text: JSON.stringify(selection) }] } }] });

test('Gemini receives retrieved sources, schema and key only in header', async () => {
  const selected = { sufficient: true, citations: [sources()[0].id] };
  const result = await selectSources('felicidad', sources(), 'test-key', async (url, options) => {
    assert.equal(url, 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent');
    assert.equal(options.headers['x-goog-api-key'], 'test-key');
    const payload = JSON.parse(options.body);
    const input = JSON.parse(payload.contents[0].parts[0].text);
    assert.deepEqual(Object.keys(input).sort(), ['question', 'sources']);
    assert.deepEqual(input.sources.map(s => s.id), sources().map(s => s.id));
    assert.equal(payload.generationConfig.responseMimeType, 'application/json');
    assert.deepEqual(payload.generationConfig.responseJsonSchema.properties.citations.items.enum, [sources()[0].id]);
    assert.ok(payload.systemInstruction.parts[0].text.includes('Ante duda abstente'));
    assert.ok(!options.body.includes('test-key'));
    return Response.json(geminiResponse(selected));
  });
  assert.deepEqual(result, selected);
});

test('Gemini blocked, truncated, malformed and invented citations abstain', async () => {
  for (const data of [
    { promptFeedback: { blockReason: 'SAFETY' } },
    { candidates: [{ finishReason: 'MAX_TOKENS' }] },
    { candidates: [{ finishReason: 'STOP', content: { parts: [{ text: 'invalid JSON' }] } }] },
    { candidates: [{ finishReason: 'STOP' }] },
    geminiResponse({ sufficient: true, citations: ['invented'] }),
    geminiResponse({ sufficient: false, citations: [] }),
  ]) {
    const selection = await selectSources('felicidad', sources(), 'test', async () => Response.json(data));
    assert.equal(renderSelection(selection, sources()).answer, ABSTENTION);
  }
});

test('quota exhaustion is a sanitized 429, without retries or successful abstention', async () => {
  let calls = 0;
  const f = fixture({ select: (q, s, key) => selectSources(q, s, key, async () => {
    calls++;
    return new Response('secret provider body', { status: 429 });
  }) });
  const response = await f.handler(request());
  assert.equal(response.status, 429);
  const data = await response.json();
  assert.equal(data.code, 'AI_QUOTA_EXCEEDED');
  assert.ok(!('answer' in data));
  assert.ok(!JSON.stringify(data).includes('secret'));
  assert.equal(calls, 1);
  await assert.rejects(selectSources('q', sources(), 'test', async () => new Response('', { status: 429 })), QuotaExceededError);
});

test('Gemini errors and network timeouts remain service errors', async () => {
  for (const fetcher of [async () => new Response('secret', { status: 500 }),
    async () => { throw new DOMException('secret', 'TimeoutError'); }]) {
    const f = fixture({ select: (q, s, key) => selectSources(q, s, key, fetcher) });
    const response = await f.handler(request());
    assert.equal(response.status, 502);
    assert.ok(!(await response.text()).includes('secret'));
  }
});

test('only GEMINI_API_KEY configures provider; missing key fails closed', async () => {
  const names = [];
  const f = fixture({ env: name => { names.push(name); return name === 'GEMINI_API_KEY' ? undefined : 'test'; },
    select: () => { throw new Error('must not call'); } });
  assert.equal((await f.handler(request())).status, 503);
  assert.ok(names.includes('GEMINI_API_KEY'));
  assert.ok(!names.includes('OPENAI_API_KEY'));
});
test('evaluation adapter preserves actual retrieval and sends only question/case_id', async () => {
  const env = { SUPABASE_URL: 'https://example.supabase.co', SUPABASE_PUBLISHABLE_KEY: 'public', JCV_ACCESS_TOKEN: 'session' };
  const data = { answer: 'source excerpt', citations: ['a'], retrieved_source_ids: ['a', 'b'] };
  const result = await provider.ask({ question: 'test', case_id: 'unit', expected: 'never sent' }, { env, fetcher: async (url, options) => {
    assert.equal(url, 'https://example.supabase.co/functions/v1/ask');
    assert.deepEqual(JSON.parse(options.body), { question: 'test', case_id: 'unit' });
    assert.equal(options.headers.Authorization, 'Bearer session');
    return Response.json(data);
  } });
  assert.deepEqual(result, data);
  await assert.rejects(provider.ask({ question: 'test', case_id: 'unit' }, { env, fetcher: async () => Response.json({ ...data, citations: ['invented'] }) }));
});
test('CSV reader handles BOM, quoted commas, multiline fields and doubled quotes', () => {
  assert.deepEqual(provider.parseCsv('\uFEFFcase_id,question\r\nunit,"a, b\n""c"""\r\n'), [['case_id', 'question'], ['unit', 'a, b\n"c"']]);
});
test('original evaluator adapter sends auth/apikey and does not send ground truth', async () => {
  const names = ['JCV_EVAL_URL', 'JCV_EVAL_TOKEN', 'SUPABASE_PUBLISHABLE_KEY'];
  const saved = names.map(name => process.env[name]);
  const originalFetch = globalThis.fetch;
  try {
    process.env.JCV_EVAL_URL = 'https://example.supabase.co/functions/v1/ask';
    process.env.JCV_EVAL_TOKEN = 'test-session';
    process.env.SUPABASE_PUBLISHABLE_KEY = 'test-public';
    globalThis.fetch = async (url, options) => {
      assert.equal(url, process.env.JCV_EVAL_URL);
      assert.equal(options.headers.apikey, 'test-public');
      assert.equal(options.headers.Authorization, 'Bearer test-session');
      assert.deepEqual(JSON.parse(options.body), { question: 'synthetic question', case_id: 'unit' });
      return Response.json({ answer: 'synthetic excerpt', citations: ['a'], retrieved_source_ids: ['a', 'b'] });
    };
    const result = await originalProvider.callApi('synthetic question', { vars: { id: 'unit', expected_sources: 'never send', expected_answer: 'never send' } });
    assert.deepEqual(JSON.parse(result.output).retrieved_source_ids, ['a', 'b']);
    assert.ok(!('cost' in result));
  } finally {
    globalThis.fetch = originalFetch;
    names.forEach((name, i) => { if (saved[i] === undefined) delete process.env[name]; else process.env[name] = saved[i]; });
  }
});

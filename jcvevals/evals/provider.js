'use strict';
// Shared strict transport for the Supabase ask contract. No eval answers/sources
// are sent to the backend; retrieved IDs are returned unchanged.
const { ask } = require('../../evals/provider.js');
module.exports = {
  id: () => 'jcv-ai-endpoint',
  async callApi(prompt, context) {
    const url = process.env.JCV_EVAL_URL;
    const token = process.env.JCV_EVAL_TOKEN;
    if (!url || !token) throw new Error('Set JCV_EVAL_URL and JCV_EVAL_TOKEN for an authorized test account');
    const endpoint = new URL(url);
    if (endpoint.pathname !== '/functions/v1/ask' || endpoint.search || endpoint.hash) {
      throw new Error('JCV_EVAL_URL must be the exact Supabase /functions/v1/ask endpoint');
    }
    const started=Date.now();
    let data;
    try {
      data = await ask({ question: prompt, case_id: context?.vars?.id }, {
        env: { SUPABASE_URL: endpoint.origin,
          SUPABASE_PUBLISHABLE_KEY: process.env.SUPABASE_PUBLISHABLE_KEY,
          JCV_ACCESS_TOKEN: token }
      });
    } catch (error) {
      throw new Error('JCV AI endpoint: ' + error.message);
    }
    return { output: JSON.stringify({answer:data.answer,citations:data.citations,
                                     retrieved_source_ids:data.retrieved_source_ids}),
             ...(data.cost_usd === undefined ? {} : { cost: data.cost_usd }),
             metadata: { latency_ms: Date.now()-started } };
  }
};

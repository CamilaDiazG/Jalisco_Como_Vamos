'use strict';
// Dependency-free baseline runner; uses the same provider and oracles as Promptfoo.
const fs = require('node:fs');
const path = require('node:path');
const cases = JSON.parse(fs.readFileSync(path.join(__dirname,'tests.yaml'),'utf8'));
const provider = require('./provider');
const {grade} = require('./oracles');
const mode = process.argv[2];
if (!['--smoke','--full'].includes(mode)) {
  console.error('Usage: node evals/run_baseline.js --smoke [case-id] | --full');
  process.exit(2);
}
if (!process.env.JCV_EVAL_URL || !process.env.JCV_EVAL_TOKEN) {
  console.error('Missing JCV_EVAL_URL or JCV_EVAL_TOKEN. No baseline was run.');
  process.exit(2);
}
(async () => {
  if (mode === '--smoke') {
    const id = process.argv[3] || 'CD-06';
    const test = cases.find(t => t.vars.id === id);
    if (!test) throw new Error('Unknown or discarded case ID: '+id);
    const result = await provider.callApi(test.vars.question, {vars:test.vars});
    const body = JSON.parse(result.output);
    const assessment = grade(body,test.vars);
    console.log(JSON.stringify({
      id,question:test.vars.question,oracle:assessment,
      response_fields:Object.keys(body),
      citations:body.citations,retrieved_source_ids:body.retrieved_source_ids,
      cost_usd:typeof result.cost==='number' ? result.cost : null
    },null,2));
    console.log('Smoke test complete; no baseline file was written.');
    return;
  }
  const started = Date.now();
  const results = [];
  for (const test of cases) {
    for (let repeat = 1; repeat <= 3; repeat++) {
      const t0 = Date.now();
      let assessment, cost = null;
      try {
        const r = await provider.callApi(test.vars.question, {vars:test.vars});
        assessment = grade(r.output,test.vars);
        if (typeof r.cost === 'number') cost = r.cost;
      } catch (e) {
        if (/HTTP (401|403|404)\b|Unexpected endpoint response schema/.test(e.message)) {
          throw new Error('Setup failed at '+test.vars.id+': '+e.message+
                          '. Baseline aborted without writing results.');
        }
        assessment = {pass:false,reason:'Provider error: '+e.message};
      }
      results.push({id:test.vars.id,category:test.vars.category,repeat,
                    pass:assessment.pass,reason:assessment.reason,cost_usd:cost,
                    elapsed_ms:Date.now()-t0});
      console.log(test.vars.id+' '+repeat+'/3 '+(assessment.pass?'PASS':'FAIL'));
    }
  }
  const categories = [...new Set(results.map(x=>x.category))];
  const summary = Object.fromEntries(categories.map(c => {
    const s=results.filter(x=>x.category===c);
    const reportedCosts=s.filter(x=>x.cost_usd!==null);
    return [c,{passed:s.filter(x=>x.pass).length,total:s.length,
               pass_rate:s.filter(x=>x.pass).length/s.length,
               all_3_passed:[...new Set(s.map(x=>x.id))].filter(id=>s.filter(x=>x.id===id).every(x=>x.pass)).length,
               cases:new Set(s.map(x=>x.id)).size,
               elapsed_seconds:s.reduce((sum,x)=>sum+x.elapsed_ms,0)/1000,
               cost_usd:reportedCosts.length===s.length ?
                 reportedCosts.reduce((sum,x)=>sum+x.cost_usd,0):null}];
  }));
  const knownCosts=results.filter(x=>x.cost_usd!==null);
  const report={date:new Date().toISOString(),k:3,elapsed_seconds:(Date.now()-started)/1000,
                cost_usd:knownCosts.length===results.length ?
                   knownCosts.reduce((sum,x)=>sum+x.cost_usd,0):null,
                cost_reported_for:knownCosts.length,call_count:results.length,
                categories:summary,results};
  const dir=path.join(__dirname,'results');fs.mkdirSync(dir,{recursive:true});
  fs.writeFileSync(path.join(dir,'baseline.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify({elapsed_seconds:report.elapsed_seconds,cost_usd:report.cost_usd,
                              cost_reported_for:report.cost_reported_for,categories:summary},null,2));
})().catch(e=>{console.error(e);process.exit(1)});

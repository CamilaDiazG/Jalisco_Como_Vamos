'use strict';
const assert = require('node:assert/strict');
const {grade} = require('./oracles');
const v={oracle:'grounded',expected_sources:'Q_69',expected_figures:'43.7%;25.6%'};
assert.equal(grade({answer:'43.7% y 25.6%',citations:['Q_69'],retrieved_source_ids:['Q_69']},v).pass,true);
assert.equal(grade({answer:'43.7%',citations:['Q_69'],retrieved_source_ids:['Q_69']},v).pass,false);
assert.equal(grade({answer:'43.7% y 25.6%',citations:['Q_69'],retrieved_source_ids:[]},v).pass,false);
assert.equal(grade({answer:'JCV_CANARY 43.7% y 25.6%',citations:['Q_69'],retrieved_source_ids:['Q_69']},v).pass,false);
assert.equal(grade({answer:'No tengo datos suficientes en las fuentes disponibles para responder.',citations:[],retrieved_source_ids:[]},
                   {oracle:'refusal'}).pass,true);
console.log('Five oracle smoke checks passed.');

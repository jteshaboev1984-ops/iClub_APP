#!/usr/bin/env node
'use strict';
// #574: full 495-item SOURCE coverage + focused editorial regression.
// Never prints protected questions, options, answer keys, or individual scores.
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const folders={QUA:'p1_quadratics',FUN:'p2_functions',COO:'p3_coordinate_geometry',
  CIR:'p4_circular_trigonometry',TRI:'p4_circular_trigonometry',
  SER:'p5_binomial_series',DIF:'p6_differentiation',INT:'p7_integration'};
const counts={QUA:6,FUN:8,COO:6,CIR:3,TRI:5,SER:5,DIF:7,INT:5};
const expectedPoolSizes=[68,80,68,77,66,70,66];
const expectedQTypes={mcq:277,input:218};
const errors=[],rows=[],seenKeys=new Set();
const enNumbers=s=>(String(s||'').normalize('NFKC').replace(/[−–—]/g,'-')
  .replace(/,/g,'.').match(/(?<!\p{L})-?\d+(?:\.\d+)?/gu)||[]).sort().join('|');
const str=s=>String(s||'');
function equivalentAsNumericExpressions(a,b) {
  // Compare expressions only when BOTH are fully understood by this tiny parser.
  // This never claims to validate conceptual, interval, or free-text options.
  const inputs=[-2.7,-1.1,0.3,1.4,2.9];
  const va=inputs.map(x=>evalSimple(a,x)),vb=inputs.map(x=>evalSimple(b,x));
  return va.every((v,i)=>Number.isFinite(v)&&Number.isFinite(vb[i])&&
    Math.abs(v-vb[i])<1e-8);
}
function evalSimple(original,x) {
  const text=str(original).replace(/\s/g,'').replace(/[−–—]/g,'-')
    .replace(/²/g,'^2').replace(/³/g,'^3').replace(/⁴/g,'^4')
    .replace(/⁵/g,'^5').replace(/⁶/g,'^6').replace(/√/g,'sqrt')
    .replace(/π/g,'pi').replace(/,/g,'.');
  if(!/^[\d.x()+\-*/^piqrst]+$/i.test(text))throw Error('unparsed expression');
  const fragments=text.match(/sqrt|pi|[a-z]|\d+(?:\.\d+)?|[()+\-*/^]/gi)||[];
  if(fragments.join('')!==text)throw Error('unparsed expression');
  const tokens=[];
  for(let i=0;i<fragments.length;i++) {
    const prev=fragments[i-1],current=fragments[i];
    if(i>0&&(/^\d|^[a-z]|^\)$/i.test(prev))&&
      (/^\(|^[a-z]|^\d/i.test(current))&&!['sqrt','pi'].includes(prev?.toLowerCase()))tokens.push('*');
    tokens.push(current);
  }
  let index=0;
  const peek=()=>tokens[index];
  function atom(){const c=tokens[index++];if(c==='('){const v=add();
    if(tokens[index++]!==')')throw Error('missing )');return v;}
    if(c==='x')return x;if(c==='pi')return Math.PI;
    if(c==='sqrt')return Math.sqrt(atom());
    if(/^\d/.test(c))return +c;throw Error('unsupported atom');}
  function unary(){if(peek()==='+'){index++;return unary();}
    if(peek()==='-'){index++;return -unary();}return atom();}
  function power(){let v=unary();if(peek()==='^'){index++;v=Math.pow(v,power());}return v;}
  function mul(){let v=power();while(peek()==='*'||peek()==='/'){
    const op=tokens[index++],other=power();v=op==='*'?v*other:v/other;}return v;}
  function add(){let v=mul();while(peek()==='+'||peek()==='-'){
    const op=tokens[index++],other=mul();v=op==='+'?v+other:v-other;}return v;}
  const value=add();
  if(index!==tokens.length||!Number.isFinite(value))throw Error('invalid arithmetic');
  return value;
}
let machineComparable=0,numericLocalePairs=0,approvedInput=0,semanticExceptions=0;
for(const [prefix,max] of Object.entries(counts))for(let skill=1;skill<=max;skill++){
  const skillCode='P1-'+prefix+'-'+String(skill).padStart(2,'0');
  const filename=path.join(root,folders[prefix],skillCode+'.json');
  const file=JSON.parse(fs.readFileSync(filename,'utf8'));
  for(const q of file.questions||[]){
    const key=q.key,number=Number(key.slice(-3)),id=7484+number;
    if(!Number.isInteger(number)||number<1||number>495||seenKeys.has(key))errors.push('bad/duplicate author key');
    seenKeys.add(key);rows.push({id,pool:Number(q.practice_no||file.architecture?.practice_no||0),skill:skillCode});
    for(const lang of ['en','ru','uz'])for(const part of ['question','explanation']){
      if(!str(q[part]?.[lang]).trim())errors.push('missing '+part+' '+lang+' for index '+number);
    }
    if(/one-to-one/i.test(str(q.question?.uz)+' '+str(q.explanation?.uz)+
      ' '+(q.options||[]).map(o=>str(o.text?.uz)).join(' ')))errors.push('untranslated UZ term at index '+number);
    for(const lang of ['ru','uz']){
      const same=enNumbers(q.question.en)===enNumbers(q.question[lang]);
      if(!same) {
        const isTriples=number===344&&lang==='uz'&&/triples/i.test(q.question.en)&&/3 marta/i.test(q.question.uz);
        const isThreefold=[473,475,479,480].includes(number)&&lang==='ru'&&
          /3 times/i.test(q.question.en)&&/утроенн/i.test(q.question.ru);
        if(!isTriples&&!isThreefold)errors.push('unexplained stem numeric divergence at index '+number);
        else semanticExceptions++;
      } else numericLocalePairs++;
    }
    if(q.qtype==='mcq'){
      if(!Array.isArray(q.options)||q.options.length!==4||!q.options.some(o=>o.key===q.answer))errors.push('MCQ bad key/options '+number);
      for(let i=0;i<(q.options||[]).length;i++){
        for(const lang of ['ru','uz'])if(enNumbers(q.options[i].text.en)!==enNumbers(q.options[i].text[lang]))
          errors.push('MCQ numeric locale divergence at index '+number);
      }
      try{
        // Only 100%-parseable arithmetic option sets are compared by value.
        for(const o of q.options)for(const x of [-2.7,0.3,2.9])evalSimple(o.text.en,x);
        machineComparable++;
        for(let i=0;i<4;i++)for(let j=i+1;j<4;j++)
          if(equivalentAsNumericExpressions(q.options[i].text.en,q.options[j].text.en))
            errors.push('equivalent MCQ expressions at index '+number);
      }catch(e){if(!/unparsed|unsupported|invalid|missing|atom/.test(String(e.message)))throw e;}
    }else if(q.qtype==='input'){
      approvedInput++;
      if(!q.answer_contract?.canonical_answer||!Array.isArray(q.answer_contract.accepted_examples)||
        !Array.isArray(q.answer_contract.rejected_examples))errors.push('input contract at index '+number);
    }else errors.push('unknown qtype at index '+number);
  }
}
if(rows.length!==495||seenKeys.size!==495)errors.push('495 authored item coverage');
for(let id=1;id<=495;id++)if(!seenKeys.has('MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0')))
  errors.push('missing author sequence '+id);
const sizes=[0,0,0,0,0,0,0];for(const row of rows){
 const n=row.id-7484;const cutoffs=[68,148,216,293,359,429,495];
 const index=cutoffs.findIndex(x=>n<=x);sizes[index]++;
}
if(JSON.stringify(sizes)!==JSON.stringify(expectedPoolSizes))errors.push('pool size drift');
if(rows.length-approvedInput!==expectedQTypes.mcq||approvedInput!==expectedQTypes.input)
  errors.push('question format totals changed');
console.log(JSON.stringify({reviewedSourceItems:rows.length,skillFiles:Object.values(counts).reduce((a,b)=>a+b,0),
  qtypes:{mcq:rows.length-approvedInput,input:approvedInput},poolSizes:sizes,
  numericLocalePairs,reviewedSemanticNumberExceptions:semanticExceptions,
  algebraicallyComparableMCQs:machineComparable,
  errorCount:errors.length},null,2));
if(errors.length){for(const e of errors)console.error('ERROR:',e);process.exit(1);}

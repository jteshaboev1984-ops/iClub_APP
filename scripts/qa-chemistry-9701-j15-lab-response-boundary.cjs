"use strict";
// J15 synthetic Chemistry LAB transport regression: no user accounts, no Supabase writes.
// node scripts/qa-chemistry-9701-j15-lab-response-boundary.cjs
const assert=require("node:assert/strict");

class Element {
  constructor(tag){
    this.tag=tag;this.textContent="";this.className="";this.children=[];
    this.handlers={};this.attrs={};
  }
  append(...children){this.children.push(...children);}
  replaceChildren(...children){this.children=children;}
  addEventListener(event,callback){this.handlers[event]=callback;}
  setAttribute(name,value){this.attrs[name]=value;}
  find(tag){return (this.tag===tag?[this]:[]).concat(...this.children.flatMap(child=>child.find(tag)));}
  texts(){return [this.textContent,...this.children.flatMap(child=>child.texts())];}
}
async function tick(){for(let i=0;i<20;i++)await Promise.resolve();}
const validItems=paper=>Array.from({length:6},(_,i)=>({
  title:"Synthetic safe laboratory lesson "+(i+1),
  skill_key:"CHEM9701-LAB-"+String(i+(paper==="P3"?1:7)).padStart(2,"0"),
  paper_code:paper,level_code:paper==="P3"?"AS":"A"
}));
const catalogCases=[
  {name:"valid Paper 3",paper:"P3",count:6},
  {name:"valid Paper 5",paper:"P5",count:6},
  {name:"reject cross-Paper 5 item in Paper 3",paper:"P3",mutate:items=>items[0].skill_key="CHEM9701-LAB-07",count:0},
  {name:"reject cross-Paper 3 item in Paper 5",paper:"P5",mutate:items=>items[0].skill_key="CHEM9701-LAB-01",count:0},
  {name:"reject duplicate IDs",paper:"P3",mutate:items=>items[0].skill_key=items[1].skill_key,count:0},
  {name:"reject empty title",paper:"P3",mutate:items=>items[0].title="   ",count:0},
  {name:"reject absent title",paper:"P5",mutate:items=>delete items[0].title,count:0},
  {name:"reject wrong level",paper:"P3",mutate:items=>items[0].level_code="A",count:0},
  {name:"reject wrong per-item paper",paper:"P3",mutate:items=>items[0].paper_code="P5",count:0},
  {name:"reject unexpected count",paper:"P3",badCount:true,count:0},
  {name:"reject claimed mastery credit",paper:"P3",badCredit:true,count:0},
  {name:"reject unavailable server gate",paper:"P3",closed:true,count:0},
  {name:"reject wrong response locale",paper:"P5",wrongLocale:true,count:0}
];
const lessonCases=[
  {name:"allow validated safe lesson",count:1},
  {name:"reject Tutor in lesson",mutate:row=>row.tutor_included=true,count:0},
  {name:"reject claimed practical competence",mutate:row=>row.practical_exam_replacement=true,count:0},
  {name:"reject missing lesson title",mutate:row=>delete row.title,count:0},
  {name:"reject empty lesson text",mutate:row=>row.explanation="",count:0},
  {name:"reject wrong lesson paper",mutate:row=>row.paper_code="P5",count:0}
];

module.exports=async function run(source){
  let passed=0;
  for(const scenario of catalogCases){
    const paper=scenario.paper,level=paper==="P3"?"AS":"A",root=new Element("main");
    const items=validItems(paper);scenario.mutate?.(items);
    const w={iClubExamPrepHostInternal:{},sb:{rpc:async()=>({
      data:scenario.closed?{ok:false,code:"not_available"}:
        {ok:true,paper_code:paper,level_code:level,locale:scenario.wrongLocale?"en":"ru",
         can_credit_mastery:scenario.badCredit===true,count:scenario.badCount?5:6,items}
    })}};
    new Function("window","document",source)(w,{createElement:tag=>new Element(tag)});
    assert.equal(w.iClubExamPrepHostInternal.chemistryLabsNative.mount({
      root,language:"ru",paper,onBack:()=>{}
    }),true);
    await tick();
    const actual=root.find("button").filter(button=>button.textContent==="Открыть материал").length;
    assert.equal(actual,scenario.count,scenario.name);
    w.iClubExamPrepHostInternal.chemistryLabsNative.unmount();
    passed++;
  }
  for(const scenario of lessonCases){
    const root=new Element("main");
    const items=validItems("P3");
    const w={iClubExamPrepHostInternal:{},sb:{rpc:async(name,args)=>{
      if(name==="iclub_exam_chemistry_lab_catalog_v1")return {data:{
        ok:true,paper_code:"P3",level_code:"AS",locale:"ru",
        can_credit_mastery:false,count:6,items}};
      const row={ok:true,skill_key:args.p_skill_key,paper_code:"P3",level_code:"AS",
        locale:"ru",title:"Synthetic practical guidance",
        explanation:"Safe synthetic explanation. ".repeat(10),
        tutor_included:false,can_credit_mastery:false,practical_exam_replacement:false};
      scenario.mutate?.(row);
      return {data:row};
    }}};
    new Function("window","document",source)(w,{createElement:tag=>new Element(tag)});
    w.iClubExamPrepHostInternal.chemistryLabsNative.mount({
      root,language:"ru",paper:"P3",onBack:()=>{}
    });
    await tick();
    const link=root.find("button").find(button=>button.textContent==="Открыть материал");
    assert.ok(link,scenario.name+": catalog must load");
    await link.handlers.click();
    await tick();
    const actual=root.texts().filter(text=>text==="Synthetic practical guidance").length;
    assert.equal(actual,scenario.count,scenario.name);
    w.iClubExamPrepHostInternal.chemistryLabsNative.unmount();
    passed++;
  }
  return {passed,total:catalogCases.length+lessonCases.length,
    scope:"synthetic client response boundary; does not authorize Chemistry release"};
};
if(require.main===module){
  const fs=require("node:fs"),path=require("node:path");
  const s=fs.readFileSync(path.join(__dirname,"..","exam-prep",
    "exam-prep-chemistry-labs-native.js"),"utf8");
  module.exports(s).then(r=>console.log(JSON.stringify(r,null,2)))
    .catch(e=>{console.error(e);process.exitCode=1;});
}

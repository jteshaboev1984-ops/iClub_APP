// iClub AI Layer v2.1 — isolated 1:3 preview contract, synthetic only.
// Run: node qa/ai-layer-metering-v21.synthetic.js
(() => {
"use strict";
const ensure=(v,s)=>{if(!v)throw Error("FAIL "+s);};
class Meter {
 constructor(){this.p=new Map();this.r=new Map();this.calls=0;}
 period(user,plan,t=0){let p=this.p.get(user);if(!p||(p.start!==null&&t>=p.start+18000000)){p={plan,start:null,used:0,held:0};this.p.set(user,p);}ensure(p.plan===plan,"plan mismatch");return p;}
 left(user,plan,t=0){const cap={free:3,plus:9,pro:14}[plan],p=this.period(user,plan,t);return cap-p.used-p.held;}
 reserve(user,id,plan,route,t=0,o={}){
  const old=this.r.get(id);
  if(old)return old.user===user&&old.plan===plan&&old.route===route?{ok:old.state!=="released",reason:old.state}:{ok:false,reason:"identity"};
  if(o.exam)return {ok:false,reason:"exam"};
  if(o.ready===false)return {ok:false,reason:"in_development"};
  if(route==="prepared"&&o.exact===false)return {ok:false,reason:"no_exact_source"};
  if(plan==="free"&&route==="generated")return {ok:false,reason:"not_entitled"};
  const w=route==="generated"?3:route==="prepared"?1:0;
  if(!w)return {ok:false,reason:"invalid_route"};
  const p=this.period(user,plan,t);
  if(this.left(user,plan,t)<w)return {ok:false,reason:"route_shortfall"};
  p.held+=w;this.r.set(id,{user,plan,route,w,p,state:"reserved"});return {ok:true};
 }
 finish(id,success=true,t=0){
  const x=this.r.get(id);ensure(!!x,"missing request");
  if(x.state!=="reserved")return {duplicate:true,status:x.state};
  x.p.held-=x.w;
  if(success){x.p.used+=x.w;if(x.p.start===null)x.p.start=t;x.state="completed";}
  else x.state="released";
  return {duplicate:false,status:x.state};
 }
 provider(id){const x=this.r.get(id);ensure(!!x&&x.route==="generated"&&x.state==="reserved","provider without allowance");this.calls++;}
}
const take=(m,u,id,p,r,t=0)=>{
 const x=m.reserve(u,id,p,r,t);ensure(x.ok,"reserve "+id+" "+x.reason);
 if(r==="generated")m.provider(id);
 ensure(m.finish(id,true,t).status==="completed","finish "+id);
};
let tests=0;const check=(name,f)=>{f();tests++;};
check("remaining2",()=>{let m=new Meter();for(let i=0;i<7;i++)take(m,"u","a"+i,"plus","prepared");
 ensure(m.left("u","plus")===2,"balance 2");
 ensure(m.reserve("u","g","plus","generated").reason==="route_shortfall","deny only costly");
 ensure(m.left("u","plus")===2&&m.calls===0,"unchanged");
 take(m,"u","a7","plus","prepared");take(m,"u","a8","plus","prepared");ensure(m.left("u","plus")===0,"two cheap");
});
check("mixed_plus_pro",()=>{let m=new Meter();take(m,"plus-user","plus-gen","plus","generated");
 for(let i=0;i<6;i++)take(m,"plus-user","plus-prep"+i,"plus","prepared");
 for(let i=0;i<4;i++)take(m,"pro-user","pro-gen"+i,"pro","generated");
 for(let i=0;i<2;i++)take(m,"pro-user","pro-prep"+i,"pro","prepared");
 ensure(m.left("plus-user","plus")===0&&m.left("pro-user","pro")===0&&m.calls===5,"mixed totals");
});
check("free",()=>{let m=new Meter();ensure(m.reserve("u","g","free","generated").reason==="not_entitled","free gen");
 for(let i=0;i<3;i++)take(m,"u","p"+i,"free","prepared");
 ensure(!m.reserve("u","p3","free","prepared").ok,"free fourth");
});
check("failure_and_clock",()=>{let m=new Meter();m.reserve("u","failed","plus","generated");m.finish("failed",false,1000);
 ensure(m.left("u","plus")===9&&m.period("u","plus").start===null,"failure charge");
 take(m,"u","good","plus","prepared",2000);
 ensure(m.period("u","plus").start===2000,"first success");
 ensure(m.left("u","plus",2000+18000000)===9,"five hour reset");
});
check("idempotence_and_concurrency",()=>{let m=new Meter();
 for(let id of ["a","b","c"])ensure(m.reserve("u",id,"plus","generated").ok,id);
 ensure(m.reserve("u","a","plus","generated").ok,"same id retry");
 ensure(!m.reserve("u","d","plus","prepared").ok,"no overspend");
 for(let id of ["a","b","c"]){m.provider(id);m.finish(id);}
 ensure(m.finish("a").duplicate&&m.left("u","plus")===0,"duplicate finalize");
});
check("fail_closed_no_spend",()=>{let m=new Meter();
 ensure(m.reserve("u","x","plus","prepared",0,{exact:false}).reason==="no_exact_source","no source");
 ensure(m.reserve("u","y","plus","prepared",0,{ready:false}).reason==="in_development","not ready");
 ensure(m.reserve("u","z","plus","prepared",0,{exam:true}).reason==="exam","exam");
 ensure(m.left("u","plus")===9&&m.calls===0,"no spend");
});
check("provider_error_fallback",()=>{let m=new Meter();m.reserve("u","g","plus","generated");m.provider("g");m.finish("g",false);
 take(m,"u","prepared","plus","prepared");ensure(m.left("u","plus")===8,"release on provider fail");
});
check("identity",()=>{let m=new Meter();m.reserve("u","unique","plus","prepared");
 ensure(m.reserve("v","unique","plus","prepared").reason==="identity","cross-user");
 ensure(m.reserve("u","unique","plus","generated").reason==="identity","route spoof");
});
if(typeof console!=="undefined")console.log("GREEN "+tests+"/8 synthetic cases; no external I/O.");
return tests;
})()
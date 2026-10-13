import {makeHttpHandler} from "./http.ts";
const origin="https://preview.synthetic.invalid";
const ok=(x:unknown,msg="assertion failed")=>{if(!x)throw new Error(msg)};
const equal=(a:unknown,b:unknown)=>ok(Object.is(a,b),String(a)+" expected "+String(b));
const core={
 calls:0,last:null as Record<string,unknown>|null,
 async serve(args:Record<string,unknown>){
  this.calls++;this.last=args;
  return{status:200,body:{ok:false,state:"in_development",
   title:"В разработке",message:"AI-помощь по этой теме пока готовится.",charge:0}};
 }
};
const serve=makeHttpHandler(core,[origin]);
const req=(props:{method?:string;origin?:string;contentType?:string;body?:string}={})=>
 new Request("https://preview.synthetic.invalid/api/v21",{
  method:props.method??"POST",
  headers:{"Origin":props.origin??origin,"Content-Type":props.contentType??"application/json",
   "Authorization":"Bearer synthetic-jwt-12345"},
  ...(props.method==="OPTIONS"||props.method==="GET"?{}:{body:props.body??'{"intent":"status"}'})
 });
Deno.test("HTTP: valid QA origin sends request through core and uses no-store",async()=>{
 const res=await serve(req());
 equal(res.status,200);equal(res.headers.get("cache-control"),"no-store, max-age=0");
 equal(res.headers.get("access-control-allow-origin"),origin);
 equal((await res.json()).title,"В разработке");
 ok(core.calls>0);
});
Deno.test("HTTP: rejects unknown Origin before any core or bearer use",async()=>{
 const before=core.calls;
 const res=await serve(req({origin:"https://evil.invalid"}));
 equal(res.status,403);equal(core.calls,before);
 equal(res.headers.has("access-control-allow-origin"),false);
});
Deno.test("HTTP: rejects missing Origin rather than giving a wildcard",async()=>{
 const before=core.calls;
 const reqNoOrigin=new Request("https://preview.synthetic.invalid/",{
  method:"POST",headers:{"Content-Type":"application/json"},body:"{}"
 });
 equal((await serve(reqNoOrigin)).status,403);equal(core.calls,before);
});
Deno.test("HTTP: allowed preflight is answerless and specifies narrow CORS",async()=>{
 const before=core.calls;
 const r=await serve(req({method:"OPTIONS"}));
 equal(r.status,204);equal(r.headers.get("access-control-allow-origin"),origin);
 equal(core.calls,before);
});
Deno.test("HTTP: only POST with JSON body accepted",async()=>{
 const before=core.calls;
 equal((await serve(req({method:"GET"}))).status,405);
 equal((await serve(req({contentType:"text/plain"}))).status,415);
 equal(core.calls,before);
});
Deno.test("HTTP: refuses declared huge bodies before reading",async()=>{
 const before=core.calls;
 const r=new Request("https://preview.synthetic.invalid/",{
  method:"POST",headers:{"Origin":origin,"Content-Type":"application/json",
   "Content-Length":"8000"},body:"{}"
 });
 equal((await serve(r)).status,413);equal(core.calls,before);
});
Deno.test("HTTP: refuses actual overlength bodies, regardless of client header",async()=>{
 const before=core.calls;
 const r=await serve(req({body:"a".repeat(4097)}));
 equal(r.status,413);equal(core.calls,before);
});
Deno.test("HTTP: fails closed on invalid UTF-8",async()=>{
 const before=core.calls;
 const r=new Request("https://preview.synthetic.invalid/",{
  method:"POST",headers:{"Origin":origin,"Content-Type":"application/json"},
  body:new Uint8Array([0xff,0xfe,0xfd])
 });
 equal((await serve(r)).status,413);equal(core.calls,before);
});
Deno.test("HTTP: unhandled adapter errors do not expose private stack or bearer",async()=>{
 const h=makeHttpHandler({async serve(){throw Error("secret-service-role-value")}},[origin]);
 const r=await h(req());equal(r.status,503);
 const raw=await r.text();
 ok(!raw.includes("secret-service-role-value"));
 equal(r.headers.get("cache-control"),"no-store, max-age=0");
});
Deno.test("HTTP: invalid origin-list entries cannot broaden allowlist",async()=>{
 const h=makeHttpHandler(core,["*", "https://evil.invalid/", origin]);
 equal((await h(req({origin:"https://evil.invalid"}))).status,403);
});

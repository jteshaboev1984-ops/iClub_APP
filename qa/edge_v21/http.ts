// Deno/Supabase Edge HTTP transport for the QA-only AI v2.1 candidate.
// No endpoint is deployed or invoked by production. No model credentials here.
export type CoreResponse={status:number;body:Record<string,unknown>};
export type Core={
 serve(args:{method:string;origin:string;authorization:string;bodyText:string}):Promise<CoreResponse>
};
const json=(status:number,body:Record<string,unknown>,origin:string|null)=>{
 const headers=new Headers({
  "Content-Type":"application/json; charset=utf-8",
  "Cache-Control":"no-store, max-age=0",
  "Pragma":"no-cache",
  "X-Content-Type-Options":"nosniff",
  "Referrer-Policy":"no-referrer",
  "Vary":"Origin"
 });
 if(origin){
  headers.set("Access-Control-Allow-Origin",origin);
  headers.set("Access-Control-Allow-Methods","POST, OPTIONS");
  headers.set("Access-Control-Allow-Headers","authorization, content-type, apikey, x-client-info");
  headers.set("Access-Control-Max-Age","300");
 }
 return new Response(status===204?null:JSON.stringify(body),{status,headers});
};
async function readSmallBody(req:Request,maxBytes:number):Promise<string|null>{
 const announced=req.headers.get("content-length");
 if(announced!==null&&(!/^\d+$/.test(announced)||Number(announced)>maxBytes))
  return null;
 const reader=req.body?.getReader();
 if(!reader)return "";
 const pieces:Uint8Array[]=[];
 let len=0;
 try{
  while(true){
   const {done,value}=await reader.read();
   if(done)break;
   len+=value.byteLength;
   if(len>maxBytes){
    await reader.cancel("body_too_large").catch(()=>{});
    return null;
   }
   pieces.push(value);
  }
  const bytes=new Uint8Array(len);let offset=0;
  for(const p of pieces){bytes.set(p,offset);offset+=p.byteLength;}
  return new TextDecoder("utf-8",{fatal:true}).decode(bytes);
 }catch{return null;}
}
export function makeHttpHandler(core:Core, allowedOrigins:readonly string[]){
 const origins=new Set(allowedOrigins.filter(o=>{
  try{const url=new URL(o);return (url.protocol==="https:"||
    url.protocol==="http:"&&["localhost","127.0.0.1"].includes(url.hostname))
    &&url.origin===o;}catch{return false;}
 }));
 return async(req:Request):Promise<Response>=>{
  const origin=req.headers.get("origin");
  // QA browser entrypoint is allowlisted; absent/unknown Origin is NOT trusted.
  if(!origin||!origins.has(origin))return json(403,{ok:false,reason:"origin_not_authorized"},null);
  if(req.method==="OPTIONS")return json(204,{},origin);
  if(req.method!=="POST")return json(405,{ok:false,reason:"method_not_allowed"},origin);
  const contentType=req.headers.get("content-type")||"";
  if(!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(contentType))
   return json(415,{ok:false,reason:"content_type_not_allowed"},origin);
  const bodyText=await readSmallBody(req,4096);
  if(bodyText===null)return json(413,{ok:false,reason:"body_too_large_or_invalid"},origin);
  try{
   const result=await core.serve({
    method:"POST",origin,
    authorization:req.headers.get("authorization")||"",
    bodyText
   });
   const status=Number.isInteger(result?.status)&&result.status>=200&&result.status<=599
    ?result.status:503;
   return json(status,result?.body&&typeof result.body==="object"?
    result.body:{ok:false,reason:"unavailable"},origin);
  }catch{return json(503,{ok:false,reason:"unavailable"},origin);}
 };
}

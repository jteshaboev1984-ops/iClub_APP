import {isolatedQaStartupAllowed} from "./qa_startup_guard.ts";
const base={flag:"isolated-preview-only",origin:"https://preview.synthetic.invalid",
 backendUrl:"http://127.0.0.1:54321",anonKey:"qa-anon-synthetic",
 serviceRoleKey:"qa-role-synthetic"};
Deno.test("§119 explicit QA bootstrap blocks remote or production Supabase",()=>{
 if(!isolatedQaStartupAllowed(base))throw Error("local QA denied");
 for(const candidate of [
  {flag:""},{flag:"live"},{origin:"http://preview.synthetic.invalid"},
  {origin:"https://preview.synthetic.invalid/redirect"},
  {backendUrl:"https://real.supabase.co"},{backendUrl:"http://10.0.0.1:54321"},
  {backendUrl:"http://localhost.evil.invalid:54321"},
  {backendUrl:"http://127.0.0.1:54321/proxy"},
  {backendUrl:"http://127.0.0.1:54321?redirect=remote"},
  {anonKey:base.serviceRoleKey},{serviceRoleKey:"short"}
 ])if(isolatedQaStartupAllowed({...base,...candidate}))
  throw Error("unsafe QA bootstrap accepted: "+JSON.stringify(candidate));
});

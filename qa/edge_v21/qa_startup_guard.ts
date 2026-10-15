// QA-only bootstrap: production Supabase URL is NEVER an eligible target.
// Remote integrated Preview needs separate owner review and code change.
type QaConfig={flag:string;origin:string;backendUrl:string;anonKey:string;serviceRoleKey:string};
export function isolatedQaStartupAllowed(c:QaConfig):boolean{
 if(c.flag!=="isolated-preview-only"||c.anonKey.length<8||
    c.serviceRoleKey.length<8||c.anonKey===c.serviceRoleKey)return false;
 try{
  const db=new URL(c.backendUrl),ui=new URL(c.origin);
  return db.protocol==="http:"&&
    (db.hostname==="localhost"||db.hostname==="127.0.0.1")&&
    db.pathname==="/"&&db.username===""&&db.password===""&&
    db.search===""&&db.hash===""&&
    ui.protocol==="https:"&&ui.hostname!=="localhost"&&
    ui.username===""&&ui.password===""&&
    ui.origin===c.origin&&ui.pathname==="/"&&ui.search===""&&ui.hash==="";
 }catch{return false;}
}

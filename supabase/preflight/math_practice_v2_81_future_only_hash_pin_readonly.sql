-- Mathematics Practice P1: pinned 81 FUTURE-ONLY question versions, read-only.
-- Canonical Issue #574; source guard parent 887807ca8d10ede62f02044fbd00792565206726.
-- Old question ID/hash must remain immutable for old answers and in-progress sessions.
-- Routine item fixes do NOT activate a new Practice bank generation.
-- No published question text, options, keys, PII or learner answer values are returned.
with expected(question_id, old_content_hash) as (
 values
  (7511::bigint,'292874e42c2304fc5c5a84a8a792517f362e397919a893ecf5022174c818be14'::text),
  (7573::bigint,'2be7d4b6e952e591890789d0870e6dca5519353c4b8b0a9c718f09454c437ec1'::text),
  (7585::bigint,'0040f8fad2356d8360b8bcba6ac56d4bc84e9ca4f1996d5bbbd2f3758946aae2'::text),
  (7618::bigint,'04dd0e621411e756d41407e0be83a1bbac7c923f2f4fd9a4c174a6da94716a7a'::text),
  (7642::bigint,'9d05ee06220de3dd12b8c59c99706f204a2b469bdfa4f3f4a895450afa3c2d5a'::text),
  (7644::bigint,'c60f2ad907ff03f3a1cb42d0810067374ea29a9626a346029a7f2130e42bf4c5'::text),
  (7645::bigint,'86668d0b984bab6ca89ffe1d693d6209023acb49389037ae023137e922b65941'::text),
  (7652::bigint,'a09dc2f23d3ad44f1550e599fdbe028427026f765e9f62ee5009536ebe86ca8c'::text),
  (7653::bigint,'b3f8a8986b1ad0a8b6fd774179ba563964f4bed1ba2f61d23e214566152f11df'::text),
  (7654::bigint,'27a8e486b1f6fd41a5c9a6cae58783dda4fb5fe9b679df1099a0382baf46c130'::text),
  (7662::bigint,'4361c8f4aaa539da3d0edee194298c83b114a9cdcc8030571db0d46c4dd266a7'::text),
  (7672::bigint,'f25204b2acd89b426f750fcec77d36c96adeafed29bb40d83234a60a65f67e42'::text),
  (7673::bigint,'ce72c8420bda488f7691e3d73510469458cc07d5692819e552a6ce6373fc4a89'::text),
  (7686::bigint,'6efedc3b71f46e88e9084c021cd0e5b11ba4bdb8009a38b0100eb0a05a425289'::text),
  (7692::bigint,'f367fef18ffa5fa1a4210d88035bb35b51cd80fb225d9fa6b7cd2089d2e8b7b7'::text),
  (7699::bigint,'f3a6dc5f1cded0401ff94576f85372edb0620a849da660f92bfee6e426fddb30'::text),
  (7708::bigint,'b7e23e8fb93d07169d43b71a2f8965601c90df7aab74627d7405a04701605cc1'::text),
  (7716::bigint,'aaf5123a2b2c07e29463a4d71734f51e0dc5854ca3fd10a10450a01befaa1eb6'::text),
  (7717::bigint,'18cc8fe8113714b109cef0860d06ad30c9f46baca04ed2e4f8d2455b64467f03'::text),
  (7723::bigint,'857a0b7f92de6e6ca33720a338df6a8fb77d6b8d0a6474537a425f198fec1133'::text),
  (7724::bigint,'9a753b585a39471adc75010f0622dbe3f7c1e00a262b864cb2ed4eec6b75d16e'::text),
  (7726::bigint,'3275131426e49911dc61f9ac04492d0497694c1dccad6dc193a0ca512fbb5a93'::text),
  (7736::bigint,'72d15f1ab6d570f79492b6251b90107e0e9ee601bd016391a70a4d0595efb851'::text),
  (7737::bigint,'7e1144846b56cd5394ddca5c37bfcadd2316e9f7e2466d16bcaa0eb1b2729775'::text),
  (7745::bigint,'3fdc693b1e829f7e2267a4a59c574e9ea0e7061b738a174df33bb73cd8636465'::text),
  (7746::bigint,'15e5bfc8c63797bdeb91097495b654029132f03766e580b119713f68f9e6d777'::text),
  (7747::bigint,'b5c31a16be7350327f377fb616d96a4783f9c2f6c969cc98e9978794c6a10a2a'::text),
  (7762::bigint,'bff8c57d83ad40c3f172bac4d2e5836f0b037644f304ff23442a86bbc89bb741'::text),
  (7763::bigint,'e6cd8447bd174732fd74dff36e18777d31415163f8283071d8e148542bdbfa23'::text),
  (7764::bigint,'38913eaabfc2752cf981cbf2b0d62f846cfe649b9b28c64c142de79b22d113a3'::text),
  (7765::bigint,'f78cb675df08bf6404045fc5b4c489c09dc59cc9615447057ff4526dbae303d8'::text),
  (7769::bigint,'08dcf765d026d7e929b225f6cc3b1bbe5521268a02001df71949a9d0acb8a874'::text),
  (7774::bigint,'d016e923ec6a48cab3901ffb8c2431f86fdb423ccbdce1b03a7a961ad5b3dc66'::text),
  (7776::bigint,'2118dde77c3177ccf182d9dafb68fb4a9b555e237af36037f3d654eda5931275'::text),
  (7777::bigint,'902a92f9c284e10cb0182327ef7f05d0caac899aae8ed6b5be5e2e2865e455ee'::text),
  (7799::bigint,'284a850919ad41dbaa15062dc82646545e55fd32fc4b6e2bca77939d025c4989'::text),
  (7812::bigint,'c92e7003de6f40b0615df669f4c9977636cafc1359cedf7b7dcec91f635045f5'::text),
  (7813::bigint,'ba78d1433c38fdbc3e0b7fafa3349b9f81e4786f72b245868941901e863989df'::text),
  (7814::bigint,'c98af45477f17e06717d5cbd0082944af97da65560b478312fd5630d66cde062'::text),
  (7823::bigint,'526852d8e794a3655b317071a32f1cbd7cab6ae007704b6541e9fdb074f1daef'::text),
  (7828::bigint,'efda09bf6665fb999ffa28bd17bfbbb641910fd78ad880f695e9b98990d725d0'::text),
  (7829::bigint,'58641c016d8a8543bfa0f06a8bae0a51f21058801010bf7c42907e8209c762da'::text),
  (7835::bigint,'55f106f7678a4695de53082a7ea86a3f2395b5e17bf13142ff304752a99eff1f'::text),
  (7840::bigint,'6b99f0cf68223899fa1f9d7db50cb64dc06654b9484608e66c2cef29f3977702'::text),
  (7841::bigint,'40459047349832363909b45ffc9b28ff0ab79cd49b1a662b1e00d313a54c30bf'::text),
  (7842::bigint,'f2d61348596b10a02f0b58c02771de617a51b1eccf71bec1e34609387fd3f8a3'::text),
  (7850::bigint,'8f0dfabb2fb89f628b1caa5db0b787da4fec8a8c14802a43ac8f61fe4e047613'::text),
  (7851::bigint,'e817e967c9e5bd560f72149862e72eb96326424f03a0c8cfed46f3f14b4662e6'::text),
  (7860::bigint,'6bd1965aa8da94f311f70d84766ecaa77762a26f9c446889d7566278ecc1f2c8'::text),
  (7861::bigint,'2f1899cbbe54e44aa8bed2c42402efd3abd9010df734483c40280dc262d6b588'::text),
  (7862::bigint,'96758506c6b356d2cd6b6668e70ef3567965c0ba809b6534b5323b8cf6802a9a'::text),
  (7863::bigint,'49796621496ff16c60324c62ef5a7948a6f9fd44a5c148ad979327ef7c59aa31'::text),
  (7873::bigint,'409cda0086814355e72f9d10f34d4e288f185fe79cbbc0b610a138e0816f397b'::text),
  (7884::bigint,'32b8172779a666e62e031a6b6488b2ecf0e6e4c382e9000ecb417b54da49eaff'::text),
  (7890::bigint,'5001ebace1b8b26fadf7c2cc26b48c1ebf09d7f519454c03c52b2ff6ccae66e2'::text),
  (7892::bigint,'b29dff06e8e8de7e25e279227fc7c8cb4efb1943308e42ac0790c0e901ffeec2'::text),
  (7893::bigint,'38e8868cb7481b28ae08daed93078d5f4c58cb882604df349faa37c5269954e0'::text),
  (7894::bigint,'b5e9eed746e17b803fd4e2ddd1e86b35fc35da4a8d9d2201ffcf8681f6a322e3'::text),
  (7901::bigint,'41ebf1121701a015766fab0a21bb10cbd2a1bfccbfb874e860a9e721b6b6a6dd'::text),
  (7908::bigint,'62e28e4491895f85798dd367ef53811ff6c76938ed3e661a0f215d79fc761309'::text),
  (7910::bigint,'32a9e7ebfcd2a91ea6ac4be0670a46f779c1cee46fb8345103c9f0328d46cc5b'::text),
  (7923::bigint,'5894a5332f071a8df94e12caae2a10fb6999ae71be63c9a6054915755b38259d'::text),
  (7924::bigint,'256de3197ddea6ff01b6d37d328adee399f0522dea94f72602bf0abd4933f7ee'::text),
  (7925::bigint,'b6fb0828ae8b827bca9c61f16cdbf08eeb2594b5f12604002b212e061fee73e0'::text),
  (7926::bigint,'bcfd7fe929fcf0e46219e3a1fe5083bad3e44718faabe6c932a0d45052d2c0b3'::text),
  (7927::bigint,'27b7fa98b133620a889048fe732578cbf72e328ce2256dab4ffe741754a46cb1'::text),
  (7928::bigint,'a4470e307d66301a3a4398cdb2913d7e4569c826d7248f8ad06e4b01a1fa0479'::text),
  (7929::bigint,'375624587e2339d287d77d3f8d7efd98aa8efbdfb00163710c67e5ed09b9bd9e'::text),
  (7930::bigint,'31e69346506583faf9cb0a75307cdbae679c4b43ade55b2482bda5345d8960a9'::text),
  (7941::bigint,'3e259593d2828a6006bcb182b803537f6a663daa09a850de1736716d4109788c'::text),
  (7948::bigint,'a5de4e05f0c8c4520e33860ddd88c08540a560689bfb28aa5399fcc1c93dad03'::text),
  (7949::bigint,'f9f619358a057cc490060571816b4b82e6a4b50927555ea8cb8ba139762c099f'::text),
  (7950::bigint,'a25408524edfc47d3e38273f202ceb50a8d6c32f3bdf60ea393e674891ddedc2'::text),
  (7951::bigint,'3a14d44c3075394bcf2a273f12411e3b7131b38cb12376b35759899f34747106'::text),
  (7953::bigint,'2eeec947cff68ef8147d10836b4b7b313e6fe9f51fe707613e867fd0148c5628'::text),
  (7955::bigint,'acd4b72721f95a90ea913214a95f949c99ea3ed588d21ddbe7b3d55ce784f671'::text),
  (7956::bigint,'6cf2c81b675ec4df42e73e63f433beb08fde0252ef689ee1a38d6483727bc57b'::text),
  (7970::bigint,'c45c280840f3c960e05290bf45dee920b17dc67ead5b5c759f942e8770256636'::text),
  (7974::bigint,'ea534fdc7ee55bdd4619a0d2acbd038ff8b2e0c01085fe889577569636242586'::text),
  (7977::bigint,'72827695271c0a91a6d10eeb5d1d81465fdb28cbe9cd6f207a867e09c22f44f1'::text),
  (7979::bigint,'37ada15eb5e019a9507c2576f3a24deb3e73dd9fccd699bbdf28ef6a2b0d9a49'::text)
), observed as (
 select e.question_id,
   (m.question_id is not null and q.id is not null
     and q.subject_id=5 and q.is_active is true
     and q.quality_status='published'
     and m.release_version='math_p1_practice_v2_2026_10_07'
     and m.lifecycle_state='published' and m.is_runtime_allowed is true
     and m.qa_math_status='passed' and m.qa_language_status='passed'
     and m.qa_technical_status='passed' and m.qa_tour_separation_status='passed'
     and m.content_key='MATH-P1-PRACTICE2-Q'||lpad((e.question_id-7484)::text,3,'0')) as published_valid,
   (m.content_hash=e.old_content_hash) as old_fingerprint_pinned,
   (select count(*) from public.practice_pool_questions ppq
       join public.practice_pools p on p.id=ppq.pool_id
       where ppq.question_id=e.question_id and ppq.is_active is true
         and p.is_active is true and p.subject_id=5) as current_active_pool_links,
   (select count(*) from public.tour_questions tq where tq.question_id=e.question_id) as tour_links,
   (select count(*) from public.practice_answers a where a.question_id=e.question_id) as classic_answers,
   (select count(*) from public.practice_session_answers_v4 a where a.question_id=e.question_id) as session_answers,
   (select count(*) from public.practice_drill_answers_v4 a where a.question_id=e.question_id) as drill_answers,
   (select count(*) from public.practice_sessions_v4 s where s.subject_id=5
       and s.status='in_progress' and e.question_id=any(s.question_ids)) as open_main_session_refs,
   (select count(*) from public.practice_drill_sessions_v4 s where s.subject_id=5
       and s.status='in_progress' and e.question_id=any(s.question_ids)) as open_drill_session_refs
 from expected e
 left join public.questions q on q.id=e.question_id
 left join private.practice_v2_question_meta m on m.question_id=e.question_id
)
select count(*)::int pinned_id_count,
       count(*) filter (where published_valid)::int current_published_valid,
       count(*) filter (where old_fingerprint_pinned)::int exact_published_hash_match,
       count(*) filter (where current_active_pool_links=1)::int one_active_membership_each,
       coalesce(sum(tour_links),0)::int tour_link_count,
       count(*) filter (where classic_answers+session_answers+drill_answers>0)::int history_bearing_question_count,
       coalesce(sum(classic_answers),0)::int classic_answer_rows,
       coalesce(sum(session_answers),0)::int session_answer_rows,
       coalesce(sum(drill_answers),0)::int drill_answer_rows,
       coalesce(sum(open_main_session_refs),0)::int in_progress_main_session_references,
       coalesce(sum(open_drill_session_refs),0)::int in_progress_drill_session_references,
       coalesce(bool_and(published_valid and old_fingerprint_pinned
                and current_active_pool_links=1 and tour_links=0),false)
                and count(*)=81 as source_version_pin_ready
from observed;

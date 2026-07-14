'use strict';

const ACTIVE_TOUR_VERSION = 'economics-tour5-guard-v4';

const ACTIVE_TOUR_QUESTIONS = [
  {
    id: 'tour5_guard_01',
    stems: {
      ru: 'На рынке труда минимальная заработная плата повышена с 6 до 9 долларов в час. После изменения объём спроса на труд снизился с 800 до 620 работников, а объём предложения труда вырос с 760 до 900. Сколько работников окажутся безработными при этой минимальной зарплате?',
      uz: 'Mehnat bozorida eng kam ish haqi soatiga 6 dollardan 9 dollarga oshirildi. Shundan so‘ng mehnat talabi 800 ishchidan 620 ishchiga kamaydi, mehnat taklifi esa 760 dan 900 ga oshdi. Ushbu eng kam ish haqida nechta ishchi ishsiz qoladi?',
      en: 'In a labour market, the minimum wage is raised from 6 dollars to 9 dollars per hour. Labour demand falls from 800 workers to 620, while labour supply rises from 760 to 900. How many workers are unemployed at this minimum wage?'
    },
    uniqueNumbers: ['6', '9', '800', '620', '760', '900'],
    terms: [
      'minimum wage', 'wage floor', 'labour demand', 'labour supply', 'unemployed', 'unemployment', 'firms want', 'want jobs', 'minimum wage question',
      'минимальн заработн', 'минимальн зарплат', 'минимальн ставк', 'спрос на труд', 'предложение труда', 'безработ', 'фирмы нанимают', 'фирмы готовы нанять', 'работать хотят', 'желающих работать', 'задаче про ставку', 'задачу с минимальной зарплатой',
      'eng kam ish haqi', 'minimal ish haqi', 'mehnat talabi', 'mehnat taklifi', 'ishsiz', 'ishsizlik', 'firmalar', 'yollaydi', 'ishlashni xohlaydi', 'masalada taklifdan talabni', 'masalani yech'
    ],
    optionPatterns: ['140', '240', '280', '380'],
    theoryCard: 'labour_market_policy'
  },
  {
    id: 'tour5_guard_02',
    stems: {
      ru: 'При выпуске 1000 единиц товара предельные внешние издержки составляют 7 долларов на единицу. Какая мера наиболее прямо сблизит частные и общественные издержки?',
      uz: '1000 birlik mahsulot ishlab chiqarilganda chegaraviy tashqi xarajat har bir birlik uchun 7 dollarni tashkil etadi. Qaysi chora xususiy va ijtimoiy xarajatlarni eng bevosita yaqinlashtiradi?',
      en: 'At an output of 1000 units, marginal external cost is 7 dollars per unit. Which measure most directly aligns private and social costs?'
    },
    uniqueNumbers: ['1000', '7'],
    terms: ['marginal external cost', 'private and social costs', 'предельные внешние издержки', 'частные и общественные издержки', 'chegaraviy tashqi xarajat', 'xususiy va ijtimoiy xarajat'],
    optionPatterns: ['tax', 'subsidy', 'налог', 'субсид', 'soliq', 'subsidiya'],
    theoryCard: 'market_failure_policy'
  },
  {
    id: 'tour5_guard_03',
    stems: {
      ru: 'После введения трансферта коэффициент Джини снизился с 0,41 до 0,36, а располагаемый доход нижнего квинтиля вырос на 12 процентов. Какой вывод лучше всего описывает влияние политики на равенство?',
      uz: 'Transfer joriy etilgach, Jini koeffitsiyenti 0,41 dan 0,36 ga kamaydi va eng quyi kvintilning ixtiyoridagi daromadi 12 foizga oshdi. Siyosatning tenglikka ta’sirini qaysi xulosa eng yaxshi ifodalaydi?',
      en: 'After a transfer is introduced, the Gini coefficient falls from 0.41 to 0.36 and the disposable income of the lowest quintile rises by 12 percent. Which conclusion best describes the policy effect on equity?'
    },
    uniqueNumbers: ['0.41', '0.36', '12'],
    terms: ['gini coefficient', 'lowest quintile', 'disposable income', 'equity', 'коэффициент джини', 'нижнего квинтиля', 'располагаемый доход', 'равенств', 'jini koeffitsiyenti', 'quyi kvintil', 'ixtiyoridagi daromad', 'tenglik'],
    optionPatterns: ['more equal', 'less equal', 'более равномер', 'менее равномер', 'tengroq', 'notengroq'],
    theoryCard: 'equity_redistribution'
  },
  {
    id: 'tour5_guard_04',
    stems: {
      ru: 'Монопсонист нанимает 40 работников при ставке 12 долларов. Чтобы нанять 41-го работника, фирма должна повысить ставку всем работникам до 12,50 доллара. Какова предельная стоимость труда 41-го работника?',
      uz: 'Monopsonist 40 ishchini 12 dollar ish haqi bilan yollaydi. 41-ishchini yollash uchun firma barcha ishchilarning ish haqini 12,50 dollarga oshirishi kerak. 41-ishchining chegaraviy mehnat xarajati qancha?',
      en: 'A monopsonist employs 40 workers at a wage of 12 dollars. To employ the 41st worker, the firm must raise the wage for all workers to 12.50 dollars. What is the marginal labour cost of the 41st worker?'
    },
    uniqueNumbers: ['40', '12', '41', '12.50'],
    terms: ['monopsonist', 'marginal labour cost', 'монопсонист', 'предельная стоимость труда', 'chegaraviy mehnat xarajati'],
    optionPatterns: ['12.50', '20', '32.50', '52.50'],
    theoryCard: 'labour_market_policy'
  },
  {
    id: 'tour5_guard_05',
    stems: {
      ru: 'Правительство выплачивает работодателю субсидию 3 доллара за каждый час труда молодых работников. При прочих равных какое первоначальное изменение произойдёт на рынке труда молодых работников?',
      uz: 'Hukumat yosh ishchilarning har bir ish soati uchun ish beruvchiga 3 dollar subsidiya to‘laydi. Boshqa shartlar o‘zgarmasa, yoshlar mehnat bozorida dastlab qanday o‘zgarish yuz beradi?',
      en: 'The government pays employers a subsidy of 3 dollars for each hour worked by young employees. Other things equal, what is the initial change in the youth labour market?'
    },
    uniqueNumbers: ['3'],
    terms: ['employer subsidy', 'youth labour market', 'labour demand', 'субсидию работодателю', 'рынке труда молодых', 'спрос на труд', 'ish beruvchiga subsidiya', 'yoshlar mehnat bozori', 'mehnat talabi'],
    optionPatterns: ['demand shifts', 'supply shifts', 'спрос сдвигается', 'предложение сдвигается', 'talab siljiydi', 'taklif siljiydi'],
    theoryCard: 'labour_market_policy'
  }
];

const SOLUTION_INTENT = [
  'solve', 'calculate', 'answer', 'which option', 'correct option', 'is my answer', 'am i right', 'eliminate', 'remove two', 'check my logic', 'give the letter', 'determine',
  'реши', 'посчитай', 'ответ', 'какой вариант', 'правильный вариант', 'правильно ли', 'проверь мою логику', 'убери два', 'исключи варианты', 'скажи букву', 'определи',
  'yech', 'hisobla', 'javob', 'qaysi variant', 'to‘g‘ri variant', 'togri variant', 'men to‘g‘ri', 'mantiqimni tekshir', 'ikkita variantni olib tashla', 'harfni ayt', 'aniqla'
];

const INJECTION_INTENT = [
  'ignore restrictions', 'ignore previous instructions', 'pretend the tour is over', 'system prompt', 'developer message',
  'игнорируй ограничения', 'игнорируй предыдущие инструкции', 'представь что тур закончился', 'системный промпт',
  'cheklovlarni e’tiborsiz qoldir', 'oldingi ko‘rsatmalarni e’tiborsiz qoldir', 'tur tugagan deb tasavvur qil'
];

function normalize(value) {
  return String(value || '').toLowerCase()
    .replace(/ё/g, 'е').replace(/ў/g, 'o').replace(/ғ/g, 'g').replace(/қ/g, 'q').replace(/ҳ/g, 'h')
    .replace(/[’‘`]/g, "'").replace(/,/g, '.').replace(/[^a-zа-я0-9\s.=><]+/gi, ' ')
    .replace(/\s+/g, ' ').trim();
}

function tokenSet(value) {
  return new Set(normalize(value).split(' ').filter(token => token.length > 2));
}

function phraseHit(text, phrases) {
  const normalized = normalize(text);
  return phrases.find(phrase => normalized.includes(normalize(phrase))) || null;
}

function stemSimilarity(question, stem) {
  const q = tokenSet(question);
  const s = tokenSet(stem);
  if (!q.size || !s.size) return 0;
  let common = 0;
  s.forEach(token => { if (q.has(token)) common += 1; });
  return common / Math.max(1, Math.min(q.size, s.size));
}

function evaluateActiveTourGuard(question, options = {}) {
  const text = normalize(question);
  const scenarioActive = options.scenarioActive === true || options.contextId === 'demo_active_tour5';
  const solutionIntent = phraseHit(text, SOLUTION_INTENT);
  const injectionIntent = phraseHit(text, INJECTION_INTENT);
  const suspiciousIntent = Boolean(solutionIntent || injectionIntent);
  let best = null;

  for (const item of ACTIVE_TOUR_QUESTIONS) {
    const stems = Object.values(item.stems).map(normalize);
    const exact = stems.some(stem => text === stem || (stem.length > 60 && text.includes(stem)));
    const similarity = Math.max(...Object.values(item.stems).map(stem => stemSimilarity(text, stem)));
    const numberHits = item.uniqueNumbers.filter(value => text.includes(normalize(value)));
    const termHits = item.terms.filter(value => text.includes(normalize(value)));
    const optionHits = item.optionPatterns.filter(value => text.includes(normalize(value)));
    const fingerprint = numberHits.length >= Math.min(2, item.uniqueNumbers.length) && termHits.length >= 1;
    const numericIntent = item.uniqueNumbers.length >= 2 && suspiciousIntent && numberHits.length >= Math.min(3, item.uniqueNumbers.length);
    const paraphrase = (numberHits.length >= 1 && similarity >= 0.38 && termHits.length >= 1) || (suspiciousIntent && similarity >= 0.52 && termHits.length >= 2);
    const optionPattern = optionHits.length >= 2 && termHits.length >= 1;
    const activeTopic = termHits.length >= 1;
    const score = (exact ? 100 : 0) + (numericIntent ? 45 : 0) + similarity * 30 + numberHits.length * 7 + termHits.length * 5 + optionHits.length * 3;
    const candidate = { item, exact, similarity, numberHits, termHits, optionHits, fingerprint, numericIntent, paraphrase, optionPattern, activeTopic, score };
    if (!best || candidate.score > best.score) best = candidate;
  }

  const matched = best && (best.exact || best.fingerprint || best.numericIntent || best.paraphrase || best.optionPattern);
  const blocked = Boolean(matched || (best?.activeTopic && suspiciousIntent));
  const theoryAllowed = Boolean(!blocked && scenarioActive);
  let reason = 'allowed_general';
  if (blocked) {
    if (best?.exact) reason = 'exact_stem';
    else if (best?.fingerprint) reason = 'numeric_fingerprint';
    else if (best?.numericIntent) reason = 'numeric_intent_fingerprint';
    else if (best?.optionPattern) reason = 'option_pattern';
    else if (best?.paraphrase) reason = 'paraphrase_match';
    else if (injectionIntent) reason = 'prompt_injection';
    else reason = 'solution_intent';
  } else if (theoryAllowed) reason = 'theory_only';

  return {
    blocked,
    theoryAllowed,
    reason,
    matchedQuestionId: blocked ? best?.item?.id || null : null,
    theoryCard: best?.item?.theoryCard || null,
    signals: {
      exact: Boolean(best?.exact), similarity: Number((best?.similarity || 0).toFixed(3)),
      numbers: best?.numberHits || [], terms: best?.termHits || [], options: best?.optionHits || [],
      solutionIntent, injectionIntent
    },
    version: ACTIVE_TOUR_VERSION
  };
}

module.exports = { ACTIVE_TOUR_VERSION, ACTIVE_TOUR_QUESTIONS, evaluateActiveTourGuard, normalize };

// Hidden President Tech Award diagnostic practice preview.
// Safe by design:
// - uses safe question delivery;
// - uses read-only diagnostic evaluator;
// - does not write to attempts, answers, scores, ratings or certificates;
// - is not linked from the live app UI.

const SUPABASE_URL = 'https://mmmduffgpvwjdpruzikw.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_OUJFpELgfrrmIIw2lF8_Sw_xEFH1M46';
const PILOT_QUESTION_IDS = [1081, 1071, 1115, 1135, 2548, 1018, 1022];

const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

const COPY = {
  en: {
    practice: 'Practice', startSubtitle: '7 questions • from easy to hard', tourPicker: 'Tour selection', tour: 'Tour', subjectLabel: 'Subject', subjectTitle: 'Economics',
    stageMeta: (done, total) => `Tour 6 practice • Completed ${done}/${total} • Remaining ${Math.max(0, total - done)}`,
    bestResult: 'Best result', bestTime: 'Best time', lastAttempts: 'Last attempts', noAttempts: 'No attempts yet', date: 'Date', score: 'Score', time: 'Time', start: 'Start practice', pause: 'Pause',
    difficulty: 'Difficulty', difficulty_easy: 'easy', difficulty_medium: 'medium', difficulty_hard: 'hard', inputLabel: 'Answer', inputPlaceholder: 'Type your answer', answer: 'Answer', checking: 'Checking…', loadError: 'Could not load practice.', loading: 'Loading practice questions…',
    resultTitle: 'Practice result', resultMeta: 'Review your result and mistakes.', scoreLabel: 'score', scoreCaption: (score, total) => `${score} of ${total} correct`, correctShort: 'Correct', errors: 'Errors', topics: 'Topics',
    needsFocus: 'Needs focus', progressMade: 'Good progress', strongResult: 'Strong result', topicWeaknessTitle: 'Needs attention', accuracy: 'accuracy', noWeakTopics: 'No weak topics found',
    reviewErrors: 'Error analysis', reviewErrorsSub: 'Step-by-step logic and explanations', getAi: 'Get AI diagnosis', toPractice: 'Back to practice', backToAiPlan: 'Back to AI plan',
    reviewSubtitle: 'Tap a question to open its detailed review', reviewSummary: 'Review by topics', reviewSummaryCopy: 'Mistakes are grouped by topic. Open a topic and choose a question for detailed explanation.', result: 'Result', questions: 'Questions', mistakes: 'Mistakes',
    aiThinkingTitle: 'AI diagnosis of result', aiThinkingSubtitle: 'Analysing the whole practice attempt', aiThinkingStatus: 'Diagnosing the result…', aiStep1: 'Checking repeated mistakes', aiStep2: 'Finding the main focus', aiStep3: 'Building the next step',
    aiReadyTitle: 'AI diagnosis is ready', aiReadySubtitle: 'Personal next step after the whole practice', aiDiagnostic: 'AI diagnosis result', aiFocus: 'Main focus', aiReason: 'Why this first', aiPlan: 'Learning route', startHere: 'Start here', priorityValue: 'Important', backToResult: 'Back to result',
    aiReasonText: (focus, errors) => `${focus} is the best first focus because ${errors} mistake(s) in this attempt are connected to this result pattern.`,
    miniPlan: (focus) => [`Restore the key idea in ${focus}: what the question asks and which rule should be used.`, 'Compare your mistaken answers with the correct logic in the review.', 'Complete a short mini-training with similar questions to check that the focus is fixed.'],
    routeTitles: ['Review concepts', 'Analyse mistakes', 'Targeted practice'],
    aiSourceActionTitle: 'Open source', aiSourceActionSub: 'Material for review', aiReviewActionTitle: 'Open mistake review', aiReviewActionSub: 'Check the logic in your mistakes', aiMiniActionTitle: 'Start mini-training', aiMiniActionSub: 'Short set on the main focus',
    sourceTitle: 'Source for review', sourceSubtitle: 'This material is connected to the main focus from AI diagnosis', sourcePill: 'Material', sourceTopic: 'Topic', sourceRef: 'Source', sourceNote: 'How to use it', sourceBack: 'Back to AI plan', sourceNoteText: 'Review this source first, then return to the mistake review and mini-training.',
    yourAnswer: 'Your answer', feedback: 'Explanation', weakArea: 'Weakness', reinforcement: 'For reinforcement', nextAction: 'Next action', correct: 'Correct', needsRevision: 'Needs revision', backToReview: 'Back to review', questionReview: 'Question review', questionReviewSub: 'Mistake reason and next step', chooseOption: 'Choose one option first.', typeAnswer: 'Type your answer first.'
  },
  ru: {
    practice: 'Практика', startSubtitle: '7 вопросов • от простого к сложному', tourPicker: 'Выбор тура', tour: 'Тур', subjectLabel: 'Предмет', subjectTitle: 'Экономика',
    stageMeta: (done, total) => `Практика 6 тура • Завершено ${done}/${total} • Осталось ${Math.max(0, total - done)}`,
    bestResult: 'Лучший результат', bestTime: 'Лучшее время', lastAttempts: 'Последние попытки', noAttempts: 'Пока нет попыток', date: 'Дата', score: 'Счёт', time: 'Время', start: 'Начать практику', pause: 'Пауза',
    difficulty: 'Сложность', difficulty_easy: 'легко', difficulty_medium: 'средне', difficulty_hard: 'сложно', inputLabel: 'Ответ', inputPlaceholder: 'Введите ответ', answer: 'Ответить', checking: 'Проверяем…', loadError: 'Не удалось загрузить практику.', loading: 'Загружаем вопросы практики…',
    resultTitle: 'Результат практики', resultMeta: 'Посмотрите итог и разбор ошибок.', scoreLabel: 'результат', scoreCaption: (score, total) => `${score} из ${total} верно`, correctShort: 'Верно', errors: 'Ошибки', topics: 'Темы',
    needsFocus: 'Нужно повторить', progressMade: 'Есть прогресс', strongResult: 'Сильный результат', topicWeaknessTitle: 'Что требует внимания', accuracy: 'точность', noWeakTopics: 'Слабые темы не найдены',
    reviewErrors: 'Разбор ошибок', reviewErrorsSub: 'Правильная логика и объяснения', getAi: 'Получить ИИ-диагностику', toPractice: 'К практике', backToAiPlan: 'Назад к ИИ-плану',
    reviewSubtitle: 'Нажмите на вопрос, чтобы открыть подробный разбор', reviewSummary: 'Разбор по темам', reviewSummaryCopy: 'Ошибки сгруппированы по темам. Откройте тему и выберите вопрос для подробного объяснения.', result: 'Результат', questions: 'Вопросов', mistakes: 'Ошибок',
    aiThinkingTitle: 'ИИ-диагностика результата', aiThinkingSubtitle: 'Анализируем всю попытку практики', aiThinkingStatus: 'Идёт диагностика результата…', aiStep1: 'Проверяем повторяющиеся ошибки', aiStep2: 'Определяем главный фокус', aiStep3: 'Собираем следующий шаг',
    aiReadyTitle: 'ИИ-диагностика готова', aiReadySubtitle: 'Персональный следующий шаг после всей практики', aiDiagnostic: 'ИИ-диагностика результата', aiFocus: 'Главный фокус', aiReason: 'Почему начать с этого', aiPlan: 'Учебный маршрут', startHere: 'Начните отсюда', priorityValue: 'Важно', backToResult: 'Назад к результату',
    aiReasonText: (focus, errors) => `${focus} выбран первым, потому что ${errors} ошибк(и) в этой попытке связаны с этим направлением результата.`,
    miniPlan: (focus) => [`Восстановите ключевую идею темы «${focus}»: что именно спрашивает вопрос и какое правило нужно применить.`, 'Сравните свои ошибки с правильной логикой в разборе.', 'Закрепите тему короткой мини-тренировкой по похожим вопросам.'],
    routeTitles: ['Повторить идею', 'Разобрать ошибки', 'Закрепить практикой'],
    aiSourceActionTitle: 'Открыть источник', aiSourceActionSub: 'Материал для повторения', aiReviewActionTitle: 'Открыть разбор ошибок', aiReviewActionSub: 'Проверьте логику в ошибках', aiMiniActionTitle: 'Начать мини-тренировку', aiMiniActionSub: 'Короткий набор по главному фокусу',
    sourceTitle: 'Источник для повторения', sourceSubtitle: 'Материал связан с главным фокусом ИИ-диагностики', sourcePill: 'Материал', sourceTopic: 'Тема', sourceRef: 'Источник', sourceNote: 'Как использовать', sourceBack: 'Назад к ИИ-плану', sourceNoteText: 'Сначала повторите этот материал, затем вернитесь к разбору ошибок и мини-тренировке.',
    yourAnswer: 'Ваш ответ', feedback: 'Объяснение', weakArea: 'Слабое место', reinforcement: 'Для закрепления', nextAction: 'Следующий шаг', correct: 'Верно', needsRevision: 'Нужно повторить', backToReview: 'Назад к разбору', questionReview: 'Разбор вопроса', questionReviewSub: 'Причина ошибки и следующий шаг', chooseOption: 'Сначала выберите один вариант ответа.', typeAnswer: 'Сначала введите ответ.'
  },
  uz: {
    practice: 'Mashq', startSubtitle: '7 savol • osondan qiyinga', tourPicker: 'Tur tanlash', tour: 'Tur', subjectLabel: 'Fan', subjectTitle: 'Iqtisodiyot',
    stageMeta: (done, total) => `6-tur mashqi • Tugallandi ${done}/${total} • Qoldi ${Math.max(0, total - done)}`,
    bestResult: 'Eng yaxshi natija', bestTime: 'Eng yaxshi vaqt', lastAttempts: 'Oxirgi urinishlar', noAttempts: 'Hozircha urinish yo‘q', date: 'Sana', score: 'Ball', time: 'Vaqt', start: 'Mashqni boshlash', pause: 'Pauza',
    difficulty: 'Qiyinlik', difficulty_easy: 'oson', difficulty_medium: 'o‘rtacha', difficulty_hard: 'qiyin', inputLabel: 'Javob', inputPlaceholder: 'Javobni kiriting', answer: 'Javob berish', checking: 'Tekshirilmoqda…', loadError: 'Mashq yuklanmadi.', loading: 'Mashq savollari yuklanmoqda…',
    resultTitle: 'Mashq natijasi', resultMeta: 'Natijani va xatolar tahlilini ko‘ring.', scoreLabel: 'natija', scoreCaption: (score, total) => `${score} / ${total} to‘g‘ri`, correctShort: 'To‘g‘ri', errors: 'Xatolar', topics: 'Mavzular',
    needsFocus: 'Qayta ko‘rib chiqish kerak', progressMade: 'Yaxshi siljish bor', strongResult: 'Kuchli natija', topicWeaknessTitle: 'E’tibor kerak bo‘lgan joylar', accuracy: 'aniqlik', noWeakTopics: 'Zaif mavzular topilmadi',
    reviewErrors: 'Xatolar tahlili', reviewErrorsSub: 'To‘g‘ri mantiq va izohlar', getAi: 'AI diagnostika olish', toPractice: 'Mashqqa', backToAiPlan: 'AI rejaga qaytish',
    reviewSubtitle: 'Batafsil tahlilni ochish uchun savolni bosing', reviewSummary: 'Mavzular bo‘yicha tahlil', reviewSummaryCopy: 'Xatolar mavzular bo‘yicha guruhlangan. Mavzuni ochib, batafsil izoh uchun savolni tanlang.', result: 'Natija', questions: 'Savollar', mistakes: 'Xatolar',
    aiThinkingTitle: 'Natija AI diagnostikasi', aiThinkingSubtitle: 'Butun mashq urinishi tahlil qilinmoqda', aiThinkingStatus: 'Natija diagnostika qilinmoqda…', aiStep1: 'Takroriy xatolar tekshirilmoqda', aiStep2: 'Asosiy fokus aniqlanmoqda', aiStep3: 'Keyingi qadam tuzilmoqda',
    aiReadyTitle: 'AI diagnostika tayyor', aiReadySubtitle: 'Butun mashqdan keyingi shaxsiy qadam', aiDiagnostic: 'Natija AI diagnostikasi', aiFocus: 'Asosiy fokus', aiReason: 'Nega bundan boshlash kerak', aiPlan: 'O‘quv yo‘nalishi', startHere: 'Shu yerdan boshlang', priorityValue: 'Muhim', backToResult: 'Natijaga qaytish',
    aiReasonText: (focus, errors) => `${focus} birinchi fokus sifatida tanlandi, chunki bu urinishdagi ${errors} ta xato shu yo‘nalish bilan bog‘liq.`,
    miniPlan: (focus) => [`«${focus}» mavzusining asosiy g‘oyasini tiklang: savol nimani so‘rayapti va qaysi qoida kerak.`, 'Xatolaringizni to‘g‘ri mantiq bilan solishtiring.', 'O‘xshash savollar bilan qisqa mini-mashq bajaring.'],
    routeTitles: ['G‘oyani takrorlash', 'Xatolarni tahlil qilish', 'Mashq bilan mustahkamlash'],
    aiSourceActionTitle: 'Manbani ochish', aiSourceActionSub: 'Takrorlash materiali', aiReviewActionTitle: 'Xatolar tahlilini ochish', aiReviewActionSub: 'Xatolardagi mantiqni tekshiring', aiMiniActionTitle: 'Mini-mashqni boshlash', aiMiniActionSub: 'Asosiy fokus bo‘yicha qisqa blok',
    sourceTitle: 'Takrorlash manbasi', sourceSubtitle: 'Material AI diagnostikadagi asosiy fokus bilan bog‘langan', sourcePill: 'Material', sourceTopic: 'Mavzu', sourceRef: 'Manba', sourceNote: 'Qanday ishlatish kerak', sourceBack: 'AI rejaga qaytish', sourceNoteText: 'Avval shu materialni takrorlang, keyin xatolar tahlili va mini-mashqqa qayting.',
    yourAnswer: 'Sizning javobingiz', feedback: 'Izoh', weakArea: 'Zaif joy', reinforcement: 'Mustahkamlash uchun', nextAction: 'Keyingi qadam', correct: 'To‘g‘ri', needsRevision: 'Qayta ko‘rib chiqish kerak', backToReview: 'Tahlilga qaytish', questionReview: 'Savol tahlili', questionReviewSub: 'Xato sababi va keyingi qadam', chooseOption: 'Avval bitta javob variantini tanlang.', typeAnswer: 'Avval javobni kiriting.'
  }
};

const LABELS = {
  topic: { Market:{en:'Market',ru:'Рынок',uz:'Bozor'}, Demand:{en:'Demand',ru:'Спрос',uz:'Talab'}, Basics:{en:'Economics basics',ru:'Основы экономики',uz:'Iqtisodiyot asoslari'}, PPC:{en:'PPC',ru:'Кривая производственных возможностей',uz:'Ishlab chiqarish imkoniyatlari egri chizig‘i'}, Elasticity:{en:'Elasticity',ru:'Эластичность',uz:'Elastiklik'}, 'Government macroeconomic intervention':{en:'Government macroeconomic policy',ru:'Макроэкономическая политика государства',uz:'Davlatning makroiqtisodiy siyosati'}, 'Allocative efficiency':{en:'Allocative efficiency',ru:'Аллокативная эффективность',uz:'Allokativ samaradorlik'}, 'Complementary goods':{en:'Complementary goods',ru:'Дополняющие товары',uz:'To‘ldiruvchi tovarlar'}, 'Consumer surplus':{en:'Consumer surplus',ru:'Потребительский излишек',uz:'Iste’molchi ortiqchaligi'}, 'Income from factors of production':{en:'Income from factors of production',ru:'Доходы факторов производства',uz:'Ishlab chiqarish omillari daromadi'}, 'Fiscal policy':{en:'Fiscal policy',ru:'Фискальная политика',uz:'Fiskal siyosat'}, 'Opportunity cost on the PPC':{en:'Opportunity cost on PPC',ru:'Альтернативная стоимость на PPC',uz:'PPC bo‘yicha muqobil qiymat'}, 'Calculating PED':{en:'Calculating PED',ru:'Расчёт PED',uz:'PED hisoblash'} },
  skill: { 'Allocative efficiency vs average-cost logic':{en:'Allocative efficiency vs average cost',ru:'Аллокативная эффективность и средние издержки',uz:'Allokativ samaradorlik va o‘rtacha xarajat'}, 'Area position on demand diagram':{en:'Area position on demand diagram',ru:'Область на графике спроса',uz:'Talab grafigidagi soha'}, 'Complement demand shift direction':{en:'Direction of demand shift for complements',ru:'Направление сдвига спроса у дополняющих товаров',uz:'To‘ldiruvchi tovarlarda talab siljishi yo‘nalishi'}, 'Consumer surplus vs producer/supply area':{en:'Consumer surplus vs producer area',ru:'Потребительский излишек и область производителя',uz:'Iste’molchi ortiqchaligi va ishlab chiqaruvchi sohasi'}, 'Consumer vs producer surplus':{en:'Consumer surplus vs producer surplus',ru:'Потребительский и производительский излишек',uz:'Iste’molchi va ishlab chiqaruvchi ortiqchaligi'}, 'Demand shift vs elasticity terminology':{en:'Demand shift vs elasticity term',ru:'Сдвиг спроса и термин эластичности',uz:'Talab siljishi va elastiklik termini'}, 'Efficiency vs profit outcome':{en:'Efficiency vs profit result',ru:'Эффективность и результат прибыли',uz:'Samaradorlik va foyda natijasi'}, 'Enterprise vs capital reward':{en:'Enterprise vs capital reward',ru:'Доход предпринимательства и капитала',uz:'Tadbirkorlik va kapital daromadi'}, 'Fiscal vs monetary policy':{en:'Fiscal policy vs monetary policy',ru:'Фискальная и монетарная политика',uz:'Fiskal va monetar siyosat'}, 'Labour vs capital reward':{en:'Labour vs capital reward',ru:'Доход труда и капитала',uz:'Mehnat va kapital daromadi'}, 'Land vs capital reward':{en:'Land vs capital reward',ru:'Доход земли и капитала',uz:'Yer va kapital daromadi'}, 'Macroeconomic policy categories':{en:'Macroeconomic policy categories',ru:'Категории макроэкономической политики',uz:'Makroiqtisodiy siyosat turlari'}, 'Market supply misconception':{en:'Misconception about market supply',ru:'Неверное понимание предложения',uz:'Taklif haqida noto‘g‘ri tushuncha'}, 'Opportunity cost calculation':{en:'Opportunity cost calculation',ru:'Расчёт альтернативной стоимости',uz:'Muqobil qiymatni hisoblash'}, 'PED calculation':{en:'PED calculation',ru:'Расчёт PED',uz:'PED hisoblash'}, 'Policy instrument recognition':{en:'Recognising policy instruments',ru:'Распознавание инструментов политики',uz:'Siyosat instrumentlarini tanish'}, 'Related goods effect':{en:'Effect of related goods',ru:'Влияние связанных товаров',uz:'Bog‘liq tovarlar ta’siri'} },
  mistake: { concept_confusion:{en:'Concept confusion',ru:'Путаница понятий',uz:'Tushuncha chalkashligi'}, diagram_area_direction:{en:'Diagram area error',ru:'Ошибка области на графике',uz:'Diagrammadagi soha xatosi'}, direction_error:{en:'Direction error',ru:'Ошибка направления',uz:'Yo‘nalish xatosi'}, diagram_area_confusion:{en:'Diagram area confusion',ru:'Путаница областей на графике',uz:'Diagramma sohalarini adashtirish'}, producer_surplus_confusion:{en:'Consumer/producer surplus confusion',ru:'Путаница потребительского и производительского излишка',uz:'Iste’molchi va ishlab chiqaruvchi ortiqchaligi chalkashligi'}, term_misuse:{en:'Term misuse',ru:'Неверное использование термина',uz:'Termin noto‘g‘ri ishlatilgan'}, overgeneralisation:{en:'Overgeneralisation',ru:'Слишком общее правило',uz:'Haddan tashqari umumlashtirish'}, factor_reward_confusion:{en:'Factor income confusion',ru:'Путаница доходов факторов',uz:'Omil daromadlari chalkashligi'}, policy_type_confusion:{en:'Policy type confusion',ru:'Путаница типов политики',uz:'Siyosat turlari chalkashligi'}, policy_scope_confusion:{en:'Policy scope confusion',ru:'Путаница области политики',uz:'Siyosat doirasi chalkashligi'}, irrelevant_condition:{en:'Irrelevant condition',ru:'Нерелевантное условие',uz:'Aloqasiz shart'}, calculation_error:{en:'Calculation error',ru:'Ошибка расчёта',uz:'Hisoblash xatosi'}, formula_or_percentage_error:{en:'Formula or percentage error',ru:'Ошибка формулы или процентов',uz:'Formula yoki foiz xatosi'}, missing_link:{en:'Missing link between ideas',ru:'Пропущена связь между идеями',uz:'G‘oyalar orasidagi bog‘lanish tushib qolgan'} }
};

const TERM_FIXES_RU = [['related goods demand shifts','сдвиги спроса из-за связанных товаров'],['demand shifters','факторы сдвига спроса'],['capital vs enterprise','капитал и предпринимательство'],['factors of production and rewards','факторы производства и их доходы'],['PED calculation','расчёт PED'],['PPC opportunity cost','альтернативную стоимость на PPC'],['demand/supply diagram','график спроса и предложения'],['government spending and taxation','государственные расходы и налоги'],['substitutes and complements','заменители и дополняющие товары']];

const state = { lang:'ru', screen:'start', allQuestions:[], questions:[], currentIndex:0, selectedOptionIndex:null, results:[], detailIndex:null, aiTimers:[], aiVariant:0, reviewReturnScreen:'result' };
const $ = (id) => document.getElementById(id);
const els = {
  topbarBack:$('topbar-back'),
  startScreen:$('practice-start-screen'), quizScreen:$('practice-quiz-screen'), resultScreen:$('practice-result-screen'), reviewScreen:$('practice-review-diagnosis-screen'), aiThinkingScreen:$('ai-thinking-screen'), aiResultScreen:$('ai-result-screen'), sourceScreen:$('ai-source-screen'), detailScreen:$('practice-question-detail-screen'),
  startTitle:$('start-title'), startSubtitle:$('start-subtitle'), tourPickerTitle:$('tour-picker-title'), tourActiveChip:$('tour-active-chip'), heroSubjectLabel:$('hero-subject-label'), heroSubjectTitle:$('hero-subject-title'), heroStageMeta:$('hero-stage-meta'), bestResultLabel:$('best-result-label'), bestTimeLabel:$('best-time-label'), lastAttemptsTitle:$('last-attempts-title'), lastAttemptsEmpty:$('last-attempts-empty'), colDate:$('col-date'), colScore:$('col-score'), colTime:$('col-time'), startDemo:$('start-demo'),
  qno:$('practice-qno'), timer:$('practice-timer'), pauseBtn:$('practice-pause-btn'), questionText:$('question-text'), questionDifficulty:$('question-difficulty'), optionsList:$('options-list'), inputWrap:$('input-wrap'), inputLabel:$('input-label'), inputAnswer:$('input-answer'), submitButton:$('submit-answer'),
  resultTitle:$('result-title'), resultMeta:$('practice-result-meta'), scoreRing:$('score-ring'), resultScoreMain:$('result-score-main'), resultScoreLabel:$('result-score-label'), resultScoreCaption:$('result-score-caption'), resultStatusPill:$('result-status-pill'), resultCorrectLabel:$('result-correct-label'), resultCorrectValue:$('result-correct-value'), resultErrorsLabel:$('result-errors-label'), resultErrorsValue:$('result-errors-value'), resultTopicsLabel:$('result-topics-label'), resultTopicsValue:$('result-topics-value'), topicWeaknessTitle:$('topic-weakness-title'), topicWeaknessList:$('topic-weakness-list'),
  openReview:$('open-review-diagnosis'), reviewDiagnosisTitle:$('review-diagnosis-title'), reviewDiagnosisSub:$('review-diagnosis-sub'), reviewDiagnosisCount:$('review-diagnosis-count'), resultPrimaryAction:$('result-primary-action'), backToStart:$('back-to-start'),
  reviewTitle:$('review-title'), reviewSubtitle:$('review-subtitle'), reviewSummaryTitle:$('review-summary-title'), reviewSummaryCopy:$('review-summary-copy'), reviewQuestionList:$('review-question-list'), reviewBackToResult:$('review-back-to-result'),
  aiThinkingTitle:$('ai-thinking-title'), aiThinkingSubtitle:$('ai-thinking-subtitle'), aiThinkingStatus:$('ai-thinking-status'), aiStep1:$('ai-step-1'), aiStep2:$('ai-step-2'), aiStep3:$('ai-step-3'), aiStep1Text:$('ai-step-1-text'), aiStep2Text:$('ai-step-2-text'), aiStep3Text:$('ai-step-3-text'),
  aiResultTitle:$('ai-result-title'), aiResultSubtitle:$('ai-result-subtitle'), aiResultPill:$('ai-result-pill'), aiPriorityLabel:$('ai-priority-label'), aiPriorityValue:$('ai-priority-value'), aiFocusLabel:$('ai-focus-label'), aiFocusTitle:$('ai-focus-title'), aiReasonLabel:$('ai-reason-label'), aiReasonText:$('ai-reason-text'), aiPlanLabel:$('ai-plan-label'), aiPlanList:$('ai-plan-list'), aiBackToResult:$('ai-back-to-result'), aiOpenSource:$('ai-open-source'), aiOpenReview:$('ai-open-review'), startMiniTraining:$('start-mini-training'), aiSourceActionTitle:$('ai-source-action-title'), aiSourceActionSub:$('ai-source-action-sub'), aiReviewActionTitle:$('ai-review-action-title'), aiReviewActionSub:$('ai-review-action-sub'), aiMiniActionTitle:$('ai-mini-action-title'), aiMiniActionSub:$('ai-mini-action-sub'),
  sourceTitle:$('source-title'), sourceSubtitle:$('source-subtitle'), sourcePill:$('source-pill'), sourceFocusTitle:$('source-focus-title'), sourceTopicLabel:$('source-topic-label'), sourceTopicValue:$('source-topic-value'), sourceRefLabel:$('source-ref-label'), sourceRefValue:$('source-ref-value'), sourceNoteLabel:$('source-note-label'), sourceNoteValue:$('source-note-value'), sourceBackToAi:$('source-back-to-ai'),
  detailTitle:$('detail-title'), detailSubtitle:$('detail-subtitle'), detailStatus:$('detail-status'), detailQuestionText:$('detail-question-text'), detailAnswerLabel:$('detail-answer-label'), detailAnswerValue:$('detail-answer-value'), detailFocusLabel:$('detail-focus-label'), detailFocusValue:$('detail-focus-value'), detailFeedbackLabel:$('detail-feedback-label'), detailFeedbackValue:$('detail-feedback-value'), detailNextLabel:$('detail-next-label'), detailNextValue:$('detail-next-value'), detailBackToReview:$('detail-back-to-review'),
  languageButtons:document.querySelectorAll('.language-btn')
};

function copy(){ return COPY[state.lang] || COPY.ru; }
function localField(base){ return `${base}_${state.lang}`; }
function label(value, group='topic'){ return LABELS[group]?.[value]?.[state.lang] || LABELS[group]?.[value]?.ru || LABELS[group]?.[value]?.en || value || ''; }
function escapeHtml(v){ return String(v ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#039;'); }
function formatMMSS(s){ s=Math.max(0, Number(s)||0); return `${String(Math.floor(s/60)).padStart(2,'0')}:${String(s%60).padStart(2,'0')}`; }
function cleanText(text){ let out = String(text || ''); if(state.lang==='ru') TERM_FIXES_RU.forEach(([a,b]) => { out = out.replaceAll(a,b); }); return out; }
function getText(row, base){ return row?.[localField(base)] || row?.[`${base}_ru`] || row?.[`${base}_en`] || row?.[`${base}_uz`] || row?.[base] || ''; }
function getResultText(result, base){ return cleanText(result?.[localField(base)] || result?.[`${base}_ru`] || result?.[`${base}_en`] || result?.[`${base}_uz`] || ''); }
function parseOptions(raw){ if(!raw) return []; if(Array.isArray(raw)) return raw; try{ const p=JSON.parse(raw); return Array.isArray(p)?p:[]; }catch{ return String(raw).split('|').map(x=>x.trim()).filter(Boolean); } }
function countBy(items, getKey){ const m=new Map(); items.forEach(item=>{ const k=getKey(item); if(k) m.set(k,(m.get(k)||0)+1); }); return [...m.entries()].sort((a,b)=>b[1]-a[1]); }

function showScreen(name){
  state.screen=name;
  els.startScreen.classList.toggle('hidden', name!=='start');
  els.quizScreen.classList.toggle('hidden', name!=='quiz');
  els.resultScreen.classList.toggle('hidden', name!=='result');
  els.reviewScreen.classList.toggle('hidden', name!=='review');
  els.aiThinkingScreen.classList.toggle('hidden', name!=='aiThinking');
  els.aiResultScreen.classList.toggle('hidden', name!=='aiResult');
  els.sourceScreen.classList.toggle('hidden', name!=='source');
  els.detailScreen.classList.toggle('hidden', name!=='detail');
  els.topbarBack.classList.toggle('hidden', name==='start');
}

function updateStaticCopy(){
  const t=copy();
  document.documentElement.lang=state.lang;
  els.startTitle.textContent=t.practice; els.startSubtitle.textContent=t.startSubtitle; els.tourPickerTitle.textContent=t.tourPicker; els.tourActiveChip.textContent=`${t.tour} 6`;
  els.heroSubjectLabel.textContent=t.subjectLabel; els.heroSubjectTitle.textContent=t.subjectTitle; els.heroStageMeta.textContent=t.stageMeta(state.results.length, state.questions.length || PILOT_QUESTION_IDS.length);
  els.bestResultLabel.textContent=t.bestResult; els.bestTimeLabel.textContent=t.bestTime; els.lastAttemptsTitle.textContent=t.lastAttempts; els.lastAttemptsEmpty.textContent=t.noAttempts; els.colDate.textContent=t.date; els.colScore.textContent=t.score; els.colTime.textContent=t.time;
  els.startDemo.textContent=state.allQuestions.length?t.start:t.loading; els.pauseBtn.textContent=t.pause; els.inputLabel.textContent=t.inputLabel; els.inputAnswer.placeholder=t.inputPlaceholder; els.submitButton.textContent=t.answer;
  els.resultTitle.textContent=t.resultTitle; els.resultMeta.textContent=t.resultMeta; els.resultScoreLabel.textContent=t.scoreLabel; els.resultCorrectLabel.textContent=t.correctShort; els.resultErrorsLabel.textContent=t.errors; els.resultTopicsLabel.textContent=t.topics; els.topicWeaknessTitle.textContent=t.topicWeaknessTitle;
  els.reviewDiagnosisTitle.textContent=t.reviewErrors; els.reviewDiagnosisSub.textContent=t.reviewErrorsSub; els.resultPrimaryAction.textContent=t.getAi; els.backToStart.textContent=t.toPractice;
  els.reviewTitle.textContent=t.reviewErrors; els.reviewSubtitle.textContent=t.reviewSubtitle; els.reviewSummaryTitle.textContent=t.reviewSummary; els.reviewSummaryCopy.textContent=t.reviewSummaryCopy; els.reviewBackToResult.textContent=state.reviewReturnScreen==='aiResult' ? t.backToAiPlan : t.backToResult;
  els.aiThinkingTitle.textContent=t.aiThinkingTitle; els.aiThinkingSubtitle.textContent=t.aiThinkingSubtitle; els.aiThinkingStatus.textContent=t.aiThinkingStatus; els.aiStep1Text.textContent=t.aiStep1; els.aiStep2Text.textContent=t.aiStep2; els.aiStep3Text.textContent=t.aiStep3;
  els.aiResultTitle.textContent=t.aiReadyTitle; els.aiResultSubtitle.textContent=t.aiReadySubtitle; els.aiResultPill.textContent=t.aiDiagnostic; els.aiPriorityLabel.textContent=t.startHere; els.aiPriorityValue.textContent=t.priorityValue; els.aiFocusLabel.textContent=t.aiFocus; els.aiReasonLabel.textContent=t.aiReason; els.aiPlanLabel.textContent=t.aiPlan; els.aiBackToResult.textContent=t.backToResult;
  els.aiSourceActionTitle.textContent=t.aiSourceActionTitle; els.aiSourceActionSub.textContent=t.aiSourceActionSub; els.aiReviewActionTitle.textContent=t.aiReviewActionTitle; els.aiReviewActionSub.textContent=t.aiReviewActionSub; els.aiMiniActionTitle.textContent=t.aiMiniActionTitle; els.aiMiniActionSub.textContent=t.aiMiniActionSub;
  els.sourceTitle.textContent=t.sourceTitle; els.sourceSubtitle.textContent=t.sourceSubtitle; els.sourcePill.textContent=t.sourcePill; els.sourceTopicLabel.textContent=t.sourceTopic; els.sourceRefLabel.textContent=t.sourceRef; els.sourceNoteLabel.textContent=t.sourceNote; els.sourceNoteValue.textContent=t.sourceNoteText; els.sourceBackToAi.textContent=t.sourceBack;
  els.detailTitle.textContent=t.questionReview; els.detailSubtitle.textContent=t.questionReviewSub; els.detailAnswerLabel.textContent=t.yourAnswer; els.detailFeedbackLabel.textContent=t.feedback; els.detailNextLabel.textContent=t.nextAction; els.detailBackToReview.textContent=t.backToReview;
}

function setSubmitReady(ready){ els.submitButton.disabled=!ready; els.submitButton.classList.toggle('is-ready', !!ready); }
function hasCurrentAnswer(){ const q=state.questions[state.currentIndex]; if(!q) return false; return String(q.qtype||'').toLowerCase()==='input' ? !!String(els.inputAnswer.value||'').trim() : state.selectedOptionIndex!==null; }
function difficultyLabel(d){ return copy()[`difficulty_${String(d||'').toLowerCase()}`] || d || ''; }

async function loadQuestions(){
  updateStaticCopy(); els.startDemo.disabled=true; els.startDemo.textContent=copy().loading;
  const {data,error}=await client.rpc('get_safe_questions_by_ids',{p_question_ids:PILOT_QUESTION_IDS});
  if(error){ console.error(error); els.startDemo.textContent=copy().loadError; return; }
  state.allQuestions=[...(data||[])].sort((a,b)=> (a.request_order??PILOT_QUESTION_IDS.indexOf(Number(a.id))) - (b.request_order??PILOT_QUESTION_IDS.indexOf(Number(b.id))));
  state.questions=[...state.allQuestions];
  els.startDemo.disabled=!state.allQuestions.length;
  updateStaticCopy();
}

function renderQuestion(){
  const t=copy(); const q=state.questions[state.currentIndex];
  if(!q){ renderResult(); return; }
  state.selectedOptionIndex=null; els.inputAnswer.value='';
  els.qno.textContent=`${state.currentIndex+1}/${state.questions.length}`; els.timer.textContent=formatMMSS(Number(q.time_limit_sec||q.timeLimitSec||58));
  els.questionText.textContent=getText(q,'question_text'); els.questionDifficulty.textContent=`${t.difficulty}: ${difficultyLabel(q.difficulty)}`; els.submitButton.textContent=t.answer; setSubmitReady(false); els.optionsList.innerHTML='';
  if(String(q.qtype||'').toLowerCase()==='input'){ els.inputWrap.classList.remove('hidden'); return; }
  els.inputWrap.classList.add('hidden');
  parseOptions(getText(q,'options_text')).forEach((option,index)=>{ const row=document.createElement('label'); row.className='option-row'; row.innerHTML=`<input type="radio" name="diagnostic-option" value="${index}"><span>${String.fromCharCode(65+index)}. ${escapeHtml(option)}</span>`; row.querySelector('input')?.addEventListener('change',()=>{ state.selectedOptionIndex=index; els.optionsList.querySelectorAll('.option-row').forEach(n=>n.classList.remove('is-selected')); row.classList.add('is-selected'); setSubmitReady(true); }); els.optionsList.appendChild(row); });
}

function startDemo(questionSet=null){
  const source = Array.isArray(questionSet) && questionSet.length ? questionSet : state.allQuestions;
  if(!source.length) return;
  state.questions=[...source]; state.currentIndex=0; state.selectedOptionIndex=null; state.results=[]; state.detailIndex=null; state.reviewReturnScreen='result';
  showScreen('quiz'); renderQuestion(); updateStaticCopy();
}

async function submitAnswer(){
  const t=copy(); const q=state.questions[state.currentIndex]; if(!q) return;
  const isInput=String(q.qtype||'').toLowerCase()==='input'; const userAnswer=isInput?els.inputAnswer.value.trim():null;
  if(isInput&&!userAnswer){ alert(t.typeAnswer); return; } if(!isInput&&state.selectedOptionIndex===null){ alert(t.chooseOption); return; }
  els.submitButton.disabled=true; els.submitButton.textContent=t.checking;
  const selectedDisplay=isInput?userAnswer:String.fromCharCode(65+state.selectedOptionIndex);
  const {data,error}=await client.rpc('evaluate_diagnostic_demo_answer',{p_question_id:Number(q.id),p_user_answer:userAnswer,p_picked_index:isInput?null:state.selectedOptionIndex});
  if(error){ console.error(error); alert(t.loadError); setSubmitReady(hasCurrentAnswer()); return; }
  state.results.push({question:q,result:data||{},selectedDisplay}); state.currentIndex+=1; state.currentIndex>=state.questions.length ? renderResult() : renderQuestion();
}

function getStats(){
  const total=state.results.length; const correctCount=state.results.filter(x=>!!x.result.is_correct).length; const wrong=state.results.filter(x=>!x.result.is_correct);
  const weakAreas=countBy(wrong, x=>label(x.result.weak_skill,'skill') || label(x.result.recommended_topic,'topic'));
  const mistakeTypes=countBy(wrong, x=>label(x.result.mistake_type,'mistake'));
  const topicFocus=countBy(wrong, x=>label(x.question.topic,'topic'));
  const rawTopicFocus=countBy(wrong, x=>x.question.topic);
  const percent=total?Math.round((correctCount/total)*100):0;
  return {total,correctCount,wrong,weakAreas,mistakeTypes,topicFocus,rawTopicFocus,percent};
}

function getTopicSummaries(){
  const map = new Map();
  state.results.forEach(item => {
    const name = label(item.question.topic,'topic') || '—';
    if(!map.has(name)) map.set(name,{name,total:0,correct:0,errors:0});
    const row = map.get(name);
    row.total += 1;
    if(item.result.is_correct) row.correct += 1; else row.errors += 1;
  });
  return [...map.values()].map(row => ({...row, accuracy: row.total ? Math.round((row.correct/row.total)*100) : 0})).sort((a,b)=> a.accuracy-b.accuracy || b.errors-a.errors || b.total-a.total);
}

function getFocusItem(){
  const s=getStats();
  const raw=s.rawTopicFocus[0]?.[0];
  const item = raw ? s.wrong.find(x=>x.question.topic===raw) : s.wrong[0];
  return { stats:s, rawTopic: raw, item };
}

function renderResult(){
  const t=copy(); const s=getStats(); showScreen('result');
  els.resultScoreMain.textContent=`${s.percent}%`; els.resultScoreCaption.textContent=t.scoreCaption(s.correctCount, s.total);
  els.scoreRing?.style.setProperty('--score', String(s.percent));
  els.resultCorrectValue.textContent=`${s.correctCount}/${s.total}`; els.resultErrorsValue.textContent=String(s.wrong.length); els.resultTopicsValue.textContent=String(s.topicFocus.length); els.reviewDiagnosisCount.textContent=String(s.wrong.length);
  els.resultStatusPill.className = 'result-status-pill';
  if(s.percent >= 80){ els.resultStatusPill.textContent = t.strongResult; els.resultStatusPill.classList.add('good'); }
  else if(s.percent >= 50){ els.resultStatusPill.textContent = t.progressMade; els.resultStatusPill.classList.add('mid'); }
  else { els.resultStatusPill.textContent = t.needsFocus; }
  renderTopicWeaknessPreview();
}

function renderTopicWeaknessPreview(){
  const t=copy();
  const rows = getTopicSummaries().filter(x=>x.accuracy < 100).slice(0,2);
  els.topicWeaknessList.innerHTML = '';
  if(!rows.length){
    const empty=document.createElement('div'); empty.className='topic-weakness-item'; empty.textContent=t.noWeakTopics; els.topicWeaknessList.appendChild(empty); return;
  }
  rows.forEach(row=>{
    const item=document.createElement('div'); item.className='topic-weakness-item';
    item.innerHTML = `<div class="topic-weakness-top"><span class="topic-weakness-name">${escapeHtml(row.name)}</span><span class="topic-weakness-accuracy">${row.accuracy}% ${escapeHtml(t.accuracy)}</span></div><div class="topic-weakness-bar"><div class="topic-weakness-fill" style="width:${row.accuracy}%"></div></div>`;
    els.topicWeaknessList.appendChild(item);
  });
}

function renderReview(returnTo=state.reviewReturnScreen || 'result'){
  const t=copy(); state.reviewReturnScreen=returnTo; showScreen('review'); updateStaticCopy();
  const byTopic=new Map(); state.results.forEach((item,idx)=>{ const topic=label(item.question.topic,'topic')||'—'; if(!byTopic.has(topic)) byTopic.set(topic,[]); byTopic.get(topic).push({...item,idx}); });
  const topics=[...byTopic.keys()].sort((a,b)=> byTopic.get(b).filter(x=>!x.result.is_correct).length - byTopic.get(a).filter(x=>!x.result.is_correct).length || a.localeCompare(b));
  els.reviewQuestionList.innerHTML='';
  topics.forEach((topic)=>{
    const items=byTopic.get(topic); const wrongCount=items.filter(x=>!x.result.is_correct).length;
    const card=document.createElement('section'); card.className='review-topic-card';
    const head=document.createElement('button'); head.className='review-topic-head'; head.type='button';
    head.innerHTML=`<div><div class="review-topic-title">${escapeHtml(topic)}</div><div class="review-topic-meta">${t.questions}: ${items.length} • ${t.mistakes}: ${wrongCount}</div></div><span class="badge badge-pin">${wrongCount?'❌ '+wrongCount:'✅ 0'}</span>`;
    const body=document.createElement('div'); body.className='review-topic-body';
    head.addEventListener('click',()=>{ body.style.display=body.style.display==='none'?'grid':'none'; });
    items.forEach(item=>{
      const isCorrect=!!item.result.is_correct;
      const row=document.createElement('button'); row.className='review-row'; row.type='button';
      row.innerHTML=`<div class="review-row-main"><span class="review-row-icon ${isCorrect?'good':''}">${isCorrect?'✓':'×'}</span><div><div class="review-row-title">${item.idx+1}. ${escapeHtml(label(item.question.subtopic,'topic') || getText(item.question,'topic') || (isCorrect?t.correct:t.needsRevision))}</div><div class="review-row-text">${escapeHtml(getText(item.question,'question_text'))}</div><div class="review-row-tag ${isCorrect?'good':''}">${escapeHtml(reviewFocusLabel(item))}: ${escapeHtml(itemFocus(item))}</div></div></div>`;
      row.addEventListener('click',()=>renderQuestionDetail(item.idx));
      body.appendChild(row);
    });
    card.appendChild(head); card.appendChild(body); els.reviewQuestionList.appendChild(card);
  });
}

function itemFeedback(item){ const id=Number(item.question.id); const answer=String(item.selectedDisplay||'').trim(); if(!item.result.is_correct && id===1022 && answer){ if(state.lang==='ru') return `Вы ввели ${answer}. Для PED нужно разделить процентное изменение величины спроса на процентное изменение цены: 20 ÷ 10 = 2.`; if(state.lang==='uz') return `Siz ${answer} deb yozdingiz. PED uchun talab miqdoridagi foiz o‘zgarishi narxdagi foiz o‘zgarishiga bo‘linadi: 20 ÷ 10 = 2.`; return `You entered ${answer}. For PED, divide the percentage change in quantity demanded by the percentage change in price: 20 ÷ 10 = 2.`; } if(!item.result.is_correct && id===1018 && answer){ if(state.lang==='ru') return `Вы ввели ${answer}. Для альтернативной стоимости уменьшение Y делится на увеличение X: 12 ÷ 4 = 3.`; if(state.lang==='uz') return `Siz ${answer} deb yozdingiz. Muqobil qiymat uchun Y kamayishi X oshishiga bo‘linadi: 12 ÷ 4 = 3.`; return `You entered ${answer}. For opportunity cost, divide the decrease in Y by the increase in X: 12 ÷ 4 = 3.`; } return getResultText(item.result,'feedback') || '—'; }
function itemNext(item){ return getResultText(item.result,'next_action') || '—'; }
function itemFocus(item){ return label(item.result.weak_skill,'skill') || label(item.result.recommended_topic,'topic') || '—'; }
function reviewFocusLabel(item){ return item.result.is_correct ? copy().reinforcement : copy().weakArea; }

function renderQuestionDetail(idx){
  const item=state.results[idx]; if(!item) return; const t=copy(); state.detailIndex=idx; showScreen('detail');
  els.detailTitle.textContent=t.questionReview; els.detailSubtitle.textContent=t.questionReviewSub; els.detailStatus.textContent=item.result.is_correct?t.correct:t.needsRevision; els.detailStatus.className=`detail-status ${item.result.is_correct?'good':'bad'}`; els.detailQuestionText.textContent=getText(item.question,'question_text');
  els.detailAnswerLabel.textContent=t.yourAnswer; els.detailAnswerValue.textContent=item.selectedDisplay || '—'; els.detailFocusLabel.textContent=reviewFocusLabel(item); els.detailFocusValue.textContent=itemFocus(item); els.detailFeedbackLabel.textContent=t.feedback; els.detailFeedbackValue.textContent=itemFeedback(item); els.detailNextLabel.textContent=t.nextAction; els.detailNextValue.textContent=itemNext(item);
}

function clearAiTimers(){ state.aiTimers.forEach(timer=>clearTimeout(timer)); state.aiTimers=[]; }
function openAiThinking(){
  clearAiTimers(); const t=copy(); showScreen('aiThinking');
  const variants = [[900,2100,3600],[1200,2600,4300],[1500,3200,5200],[1000,2800,4700]];
  state.aiVariant = Math.floor(Math.random()*variants.length);
  const times = variants[state.aiVariant];
  [els.aiStep1, els.aiStep2, els.aiStep3].forEach((el,idx)=>{ el.classList.remove('active','done'); if(idx===0) el.classList.add('active'); });
  els.aiThinkingStatus.textContent=t.aiThinkingStatus;
  state.aiTimers.push(setTimeout(()=>{ els.aiStep1.classList.remove('active'); els.aiStep1.classList.add('done'); els.aiStep2.classList.add('active'); }, times[0]));
  state.aiTimers.push(setTimeout(()=>{ els.aiStep2.classList.remove('active'); els.aiStep2.classList.add('done'); els.aiStep3.classList.add('active'); }, times[1]));
  state.aiTimers.push(setTimeout(()=>{ els.aiStep3.classList.remove('active'); els.aiStep3.classList.add('done'); renderAiResult(); }, times[2]));
}

function renderAiResult(){
  clearAiTimers(); const t=copy(); const s=getStats(); const focus=s.topicFocus[0]?.[0] || '—'; showScreen('aiResult');
  els.aiFocusTitle.textContent=focus; els.aiReasonText.textContent=t.aiReasonText(focus, s.wrong.length || 0);
  els.aiPlanList.innerHTML='';
  t.miniPlan(focus).forEach((step, idx)=>{
    const li=document.createElement('li'); li.className='ai-route-step';
    li.innerHTML = `<div class="route-step-icon">${idx+1}</div><div><div class="route-step-title">${escapeHtml(t.routeTitles[idx] || '')}</div><div class="route-step-text">${escapeHtml(step)}</div></div>`;
    els.aiPlanList.appendChild(li);
  });
}

function renderSource(){
  const t=copy(); const {stats, item}=getFocusItem(); const focus=stats.topicFocus[0]?.[0] || '—'; showScreen('source');
  els.sourceFocusTitle.textContent=focus;
  els.sourceTopicValue.textContent=item ? `${label(item.question.topic,'topic')} / ${label(item.question.subtopic,'topic') || item.question.subtopic || '—'}` : focus;
  els.sourceRefValue.textContent=item?.question?.book_ref || item?.question?.bookRef || 'Book reference will be connected here in the real app.';
  els.sourceNoteValue.textContent=t.sourceNoteText;
}

function startMiniTraining(){
  const s=getStats(); const focusRaw=s.rawTopicFocus[0]?.[0]; const mini=focusRaw ? state.allQuestions.filter(q=>q.topic===focusRaw) : [];
  startDemo(mini.length ? mini : state.allQuestions);
}

function resetToStart(){ state.questions=[...state.allQuestions]; state.currentIndex=0; state.selectedOptionIndex=null; state.results=[]; state.detailIndex=null; state.reviewReturnScreen='result'; clearAiTimers(); showScreen('start'); updateStaticCopy(); }
function returnFromReview(){ return state.reviewReturnScreen==='aiResult' ? renderAiResult() : renderResult(); }
function goBack(){ if(state.screen==='quiz') return resetToStart(); if(state.screen==='result') return resetToStart(); if(state.screen==='review') return returnFromReview(); if(state.screen==='detail') return renderReview(state.reviewReturnScreen); if(state.screen==='aiThinking'){ clearAiTimers(); return renderResult(); } if(state.screen==='aiResult') return renderResult(); if(state.screen==='source') return renderAiResult(); }
function setLanguage(lang){ if(!COPY[lang]) return; state.lang=lang; els.languageButtons.forEach(b=>b.classList.toggle('active',b.dataset.lang===lang)); updateStaticCopy(); if(state.screen==='quiz') renderQuestion(); if(state.screen==='result') renderResult(); if(state.screen==='review') renderReview(state.reviewReturnScreen); if(state.screen==='detail' && state.detailIndex!==null) renderQuestionDetail(state.detailIndex); if(state.screen==='aiThinking') openAiThinking(); if(state.screen==='aiResult') renderAiResult(); if(state.screen==='source') renderSource(); }

els.topbarBack.addEventListener('click',goBack);
els.startDemo.addEventListener('click',()=>startDemo());
els.submitButton.addEventListener('click',submitAnswer);
els.resultPrimaryAction.addEventListener('click',openAiThinking);
els.backToStart.addEventListener('click',resetToStart);
els.openReview.addEventListener('click',()=>renderReview('result'));
els.reviewBackToResult.addEventListener('click',returnFromReview);
els.aiBackToResult.addEventListener('click',renderResult);
els.aiOpenReview.addEventListener('click',()=>renderReview('aiResult'));
els.aiOpenSource.addEventListener('click',renderSource);
els.startMiniTraining.addEventListener('click',startMiniTraining);
els.sourceBackToAi.addEventListener('click',renderAiResult);
els.detailBackToReview.addEventListener('click',()=>renderReview(state.reviewReturnScreen));
els.pauseBtn.addEventListener('click',()=>null);
els.inputAnswer.addEventListener('input',()=>setSubmitReady(hasCurrentAnswer()));
els.inputAnswer.addEventListener('keydown',e=>{ if(e.key==='Enter'&&hasCurrentAnswer()) submitAnswer(); });
els.languageButtons.forEach(b=>b.addEventListener('click',()=>setLanguage(b.dataset.lang)));

updateStaticCopy(); showScreen('start'); loadQuestions();

(function(){
'use strict';
const L=(en,ru,uz)=>({en,ru,uz});
window.ICLUB_DEMO_V12_DATA={
  version:'1.2-gate-3',
  profile:{
    id:'demo-sardor',
    name:L('Sardor Karimov','Сардор Каримов','Sardor Karimov'),
    status:L('Demonstration student','Демонстрационный ученик','Namoyish o‘quvchisi'),
    initials:'СК',
    subject:'economics',
    default_language:'ru'
  },
  history:[
    {id:'p1',kind:'practice',no:1,score:10,total:10,date:'2026-05-12',seconds:482},
    {id:'p2',kind:'practice',no:2,score:10,total:10,date:'2026-05-19',seconds:506},
    {id:'p3',kind:'practice',no:3,score:10,total:10,date:'2026-05-26',seconds:471},
    {id:'t4',kind:'tour',no:4,score:6,total:20,date:'2026-06-02',seconds:1148},
    {id:'p4',kind:'practice',no:4,score:10,total:10,date:'2026-06-06',seconds:524}
  ],
  questions:[
    {
      id:'d1',order:1,difficulty:'easy',seconds:50,
      topic:L('Consumer behaviour','Поведение потребителя','Iste’molchi xulqi'),
      skill:L('Meaning of utility','Понимание полезности','Naflilik mazmuni'),
      ref:'iClub Economics · Consumer choice · Utility',
      q:L(
        'In consumer theory, what does utility mean?',
        'Что означает полезность в теории поведения потребителя?',
        'Iste’molchi nazariyasida naflilik nimani anglatadi?'
      ),
      o:{
        en:['The cost of producing a product','The satisfaction gained from consumption','The profit earned by a firm','The market price of a product'],
        ru:['Издержки производства товара','Удовлетворение от потребления','Прибыль, полученная фирмой','Рыночная цена товара'],
        uz:['Tovarni ishlab chiqarish xarajati','Iste’moldan olinadigan qoniqish','Firma oladigan foyda','Tovarning bozor narxi']
      },
      a:'B',scenario:'C',
      ok:L(
        'Utility is the satisfaction or benefit a consumer receives from consuming a good or service.',
        'Полезность — это удовлетворение или выгода, которую потребитель получает от товара или услуги.',
        'Naflilik — iste’molchi tovar yoki xizmatdan oladigan qoniqish yoki manfaatdir.'
      ),
      bad:L(
        'Profit belongs to firm theory. Utility describes the consumer’s satisfaction from consumption.',
        'Прибыль относится к теории фирмы. Полезность описывает удовлетворение потребителя от потребления.',
        'Foyda firma nazariyasiga tegishli. Naflilik iste’molchining iste’moldan olgan qoniqishini ifodalaydi.'
      ),
      next:L(
        'Separate consumer outcomes such as utility from firm outcomes such as profit.',
        'Разделите результаты потребителя, такие как полезность, и результаты фирмы, такие как прибыль.',
        'Naflilik kabi iste’molchi natijalarini foyda kabi firma natijalaridan ajrating.'
      )
    },
    {
      id:'d2',order:2,difficulty:'medium',seconds:60,
      topic:L('Consumer behaviour','Поведение потребителя','Iste’molchi xulqi'),
      skill:L('Diminishing marginal utility','Убывающая предельная полезность','Kamayib boruvchi chegaraviy naflilik'),
      ref:'iClub Economics · Consumer choice · Marginal utility',
      q:L(
        'Which statement best describes diminishing marginal utility?',
        'Какое утверждение лучше всего описывает убывающую предельную полезность?',
        'Qaysi fikr kamayib boruvchi chegaraviy naflilikni eng yaxshi ifodalaydi?'
      ),
      o:{
        en:['Total utility must fall after every unit','Each additional unit usually adds less satisfaction than the previous unit','The price of the good always falls as consumption rises','A consumer stops receiving any utility after the first unit'],
        ru:['Совокупная полезность обязательно падает после каждой единицы','Каждая дополнительная единица обычно приносит меньше дополнительного удовлетворения, чем предыдущая','Цена товара всегда снижается при росте потребления','После первой единицы потребитель больше не получает полезности'],
        uz:['Har bir birlikdan keyin umumiy naflilik albatta kamayadi','Har bir qo‘shimcha birlik odatda oldingisiga qaraganda kamroq qo‘shimcha qoniqish beradi','Iste’mol oshganda tovar narxi doimo pasayadi','Birinchi birlikdan keyin iste’molchi umuman naflilik olmaydi']
      },
      a:'B',scenario:'B',
      ok:L(
        'Marginal utility is the extra satisfaction from one more unit, and it usually decreases as consumption rises.',
        'Предельная полезность — дополнительное удовлетворение от ещё одной единицы; обычно оно снижается по мере роста потребления.',
        'Chegaraviy naflilik — yana bir birlikdan olinadigan qo‘shimcha qoniqish bo‘lib, iste’mol oshgani sari odatda kamayadi.'
      ),
      bad:L(
        'Diminishing marginal utility concerns the extra satisfaction from the next unit, not an automatic fall in total utility or price.',
        'Закон касается дополнительного удовлетворения от следующей единицы, а не обязательного падения совокупной полезности или цены.',
        'Bu qonun keyingi birlikdan olinadigan qo‘shimcha qoniqishga tegishli, umumiy naflilik yoki narxning avtomatik pasayishiga emas.'
      ),
      next:L(
        'Distinguish total utility from marginal utility.',
        'Различайте совокупную и предельную полезность.',
        'Umumiy naflilik bilan chegaraviy naflilikni ajrating.'
      )
    },
    {
      id:'d3',order:3,difficulty:'easy',seconds:50,
      topic:L('Consumer choice','Потребительский выбор','Iste’molchi tanlovi'),
      skill:L('Indifference curve definition','Определение кривой безразличия','Befarqlik egri chizig‘i ta’rifi'),
      ref:'iClub Economics · Consumer choice · Indifference curves',
      q:L(
        'What does one indifference curve show?',
        'Что показывает одна кривая безразличия?',
        'Bitta befarqlik egri chizig‘i nimani ko‘rsatadi?'
      ),
      o:{
        en:['Combinations of two goods that give the consumer equal satisfaction','Combinations of output that have the same production cost','All affordable combinations at current income and prices','Combinations that maximise a firm’s profit'],
        ru:['Наборы двух товаров, дающие потребителю одинаковое удовлетворение','Наборы объёма выпуска с одинаковыми производственными издержками','Все доступные наборы при текущем доходе и ценах','Наборы, максимизирующие прибыль фирмы'],
        uz:['Iste’molchiga bir xil qoniqish beradigan ikki tovar kombinatsiyalari','Bir xil ishlab chiqarish xarajatiga ega mahsulot hajmlari kombinatsiyalari','Joriy daromad va narxlarda sotib olish mumkin bo‘lgan barcha kombinatsiyalar','Firma foydasini maksimallashtiradigan kombinatsiyalar']
      },
      a:'A',scenario:'B',
      ok:L(
        'Every point on one indifference curve gives the consumer the same level of satisfaction.',
        'Каждая точка одной кривой безразличия даёт потребителю одинаковый уровень удовлетворения.',
        'Bitta befarqlik egri chizig‘idagi har bir nuqta iste’molchiga bir xil qoniqish darajasini beradi.'
      ),
      bad:L(
        'Production cost belongs to firm analysis. An indifference curve represents equal consumer satisfaction.',
        'Производственные издержки относятся к анализу фирмы. Кривая безразличия показывает одинаковое удовлетворение потребителя.',
        'Ishlab chiqarish xarajati firma tahliliga tegishli. Befarqlik egri chizig‘i bir xil iste’molchi qoniqishini ko‘rsatadi.'
      ),
      next:L(
        'Compare the roles of an indifference curve and a budget line.',
        'Сравните роль кривой безразличия и бюджетной линии.',
        'Befarqlik egri chizig‘i va budjet chizig‘ining vazifalarini solishtiring.'
      )
    },
    {
      id:'d4',order:4,difficulty:'medium',seconds:60,
      topic:L('Consumer choice','Потребительский выбор','Iste’molchi tanlovi'),
      skill:L('Budget line after an income rise','Бюджетная линия после роста дохода','Daromad oshgandan keyingi budjet chizig‘i'),
      ref:'iClub Economics · Consumer choice · Budget constraints',
      q:L(
        'A consumer’s income rises while the prices of both goods remain unchanged. What happens to the budget line?',
        'Доход потребителя вырос, а цены обоих товаров не изменились. Что произойдёт с бюджетной линией?',
        'Iste’molchining daromadi oshdi, ikki tovar narxi esa o‘zgarmadi. Budjet chizig‘iga nima bo‘ladi?'
      ),
      o:{
        en:['It shifts outward in a parallel way','It rotates inward around the horizontal intercept','It becomes an indifference curve','It does not change'],
        ru:['Она параллельно сместится наружу','Она повернётся внутрь вокруг горизонтального пересечения','Она станет кривой безразличия','Она не изменится'],
        uz:['U parallel ravishda tashqariga siljiydi','U gorizontal kesishma atrofida ichkariga buriladi','U befarqlik egri chizig‘iga aylanadi','U o‘zgarmaydi']
      },
      a:'A',scenario:'A',
      ok:L(
        'With unchanged prices, higher income increases the maximum affordable quantity of both goods, so the line shifts outward in parallel.',
        'При неизменных ценах рост дохода увеличивает максимально доступное количество обоих товаров, поэтому линия параллельно смещается наружу.',
        'Narxlar o‘zgarmaganda daromad oshishi har ikki tovarning maksimal xarid miqdorini oshiradi, shuning uchun chiziq parallel ravishda tashqariga siljiydi.'
      ),
      bad:L(
        'A price change rotates the budget line. A pure income change shifts it in parallel.',
        'Изменение цены поворачивает бюджетную линию. Изменение только дохода сдвигает её параллельно.',
        'Narx o‘zgarishi budjet chizig‘ini buradi. Faqat daromad o‘zgarishi uni parallel siljitadi.'
      ),
      next:L(
        'Use intercepts to distinguish an income change from a price change.',
        'Используйте точки пересечения, чтобы различать изменение дохода и изменение цены.',
        'Daromad o‘zgarishi bilan narx o‘zgarishini ajratish uchun kesishma nuqtalaridan foydalaning.'
      )
    },
    {
      id:'d5',order:5,difficulty:'medium',seconds:65,
      topic:L('Economic efficiency','Экономическая эффективность','Iqtisodiy samaradorlik'),
      skill:L('Allocative efficiency condition','Условие аллокативной эффективности','Allokativ samaradorlik sharti'),
      ref:'iClub Economics · Efficiency · Allocative efficiency',
      q:L(
        'Which condition indicates allocative efficiency?',
        'Какое условие указывает на аллокативную эффективность?',
        'Qaysi shart allokativ samaradorlikni bildiradi?'
      ),
      o:{
        en:['Price equals marginal cost (P = MC)','Total revenue equals total cost (TR = TC)','Average cost is at its minimum','Marginal revenue equals zero'],
        ru:['Цена равна предельным издержкам (P = MC)','Совокупная выручка равна совокупным издержкам (TR = TC)','Средние издержки минимальны','Предельная выручка равна нулю'],
        uz:['Narx chegaraviy xarajatga teng (P = MC)','Umumiy tushum umumiy xarajatga teng (TR = TC)','O‘rtacha xarajat minimumda','Chegaraviy tushum nolga teng']
      },
      a:'A',scenario:'B',
      ok:L(
        'Allocative efficiency is achieved where the value consumers place on the last unit, shown by price, equals its marginal resource cost.',
        'Аллокативная эффективность достигается, когда ценность последней единицы для потребителей, выраженная ценой, равна её предельным ресурсным издержкам.',
        'Allokativ samaradorlik oxirgi birlikning iste’molchilar uchun qiymati, ya’ni narx, uning chegaraviy resurs xarajatiga teng bo‘lganda yuzaga keladi.'
      ),
      bad:L(
        'TR = TC is a break-even condition. Allocative efficiency uses P = MC.',
        'TR = TC — условие безубыточности. Для аллокативной эффективности используется P = MC.',
        'TR = TC zararsizlik shartidir. Allokativ samaradorlik uchun P = MC ishlatiladi.'
      ),
      next:L(
        'Create a formula map: allocative efficiency P = MC; break-even TR = TC.',
        'Составьте карту формул: аллокативная эффективность — P = MC; безубыточность — TR = TC.',
        'Formulalar xaritasini tuzing: allokativ samaradorlik — P = MC; zararsizlik — TR = TC.'
      )
    },
    {
      id:'d6',order:6,difficulty:'hard',seconds:75,
      topic:L('Economic efficiency','Экономическая эффективность','Iqtisodiy samaradorlik'),
      skill:L('Productive efficiency condition','Условие производственной эффективности','Ishlab chiqarish samaradorligi sharti'),
      ref:'iClub Economics · Efficiency · Productive efficiency',
      q:L(
        'At which point is a firm productively efficient?',
        'В какой точке фирма производственно эффективна?',
        'Firma qaysi nuqtada ishlab chiqarish jihatidan samarali bo‘ladi?'
      ),
      o:{
        en:['At the minimum point of average cost','Where price equals marginal cost','Where total revenue equals total cost','Where marginal revenue equals marginal cost'],
        ru:['В точке минимума средних издержек','Где цена равна предельным издержкам','Где совокупная выручка равна совокупным издержкам','Где предельная выручка равна предельным издержкам'],
        uz:['O‘rtacha xarajatning minimum nuqtasida','Narx chegaraviy xarajatga teng bo‘lgan joyda','Umumiy tushum umumiy xarajatga teng bo‘lgan joyda','Chegaraviy tushum chegaraviy xarajatga teng bo‘lgan joyda']
      },
      a:'A',scenario:'B',
      ok:L(
        'Productive efficiency means producing at the lowest possible average cost.',
        'Производственная эффективность означает выпуск при минимально возможных средних издержках.',
        'Ishlab chiqarish samaradorligi eng past mumkin bo‘lgan o‘rtacha xarajatda ishlab chiqarishni anglatadi.'
      ),
      bad:L(
        'P = MC is the condition for allocative efficiency. Productive efficiency uses minimum average cost.',
        'P = MC — условие аллокативной эффективности. Производственная эффективность требует минимума средних издержек.',
        'P = MC allokativ samaradorlik shartidir. Ishlab chiqarish samaradorligi o‘rtacha xarajat minimumini talab qiladi.'
      ),
      next:L(
        'Keep neighbouring conditions separate: minimum AC, P = MC, MR = MC and TR = TC.',
        'Разделите соседние условия: минимум AC, P = MC, MR = MC и TR = TC.',
        'Yaqin shartlarni ajrating: minimum AC, P = MC, MR = MC va TR = TC.'
      )
    },
    {
      id:'d7',order:7,difficulty:'hard',seconds:75,
      topic:L('Growth of firms','Рост фирмы','Firma o‘sishi'),
      skill:L('Internal versus external growth','Внутренний и внешний рост','Ichki va tashqi o‘sish'),
      ref:'iClub Economics · Firms · Internal and external growth',
      q:L(
        'A firm uses retained profit to open a new branch of its own. How should this growth be classified?',
        'Фирма использует нераспределённую прибыль, чтобы открыть собственный новый филиал. Как классифицируется такой рост?',
        'Firma taqsimlanmagan foydadan foydalanib o‘zining yangi filialini ochdi. Bu o‘sish qanday tasniflanadi?'
      ),
      o:{
        en:['Internal growth financed internally','External growth financed externally','External growth through a merger','No growth because ownership is unchanged'],
        ru:['Внутренний рост с внутренним финансированием','Внешний рост с внешним финансированием','Внешний рост через слияние','Роста нет, потому что собственник не изменился'],
        uz:['Ichki manba bilan moliyalashtirilgan ichki o‘sish','Tashqi manba bilan moliyalashtirilgan tashqi o‘sish','Qo‘shilish orqali tashqi o‘sish','Egalik o‘zgarmagani uchun o‘sish yo‘q']
      },
      a:'A',scenario:'B',
      ok:L(
        'Opening a new branch within the same firm is internal growth, and retained profit is an internal source of finance.',
        'Открытие нового филиала внутри той же фирмы — внутренний рост, а нераспределённая прибыль — внутренний источник финансирования.',
        'Bir firma ichida yangi filial ochish ichki o‘sish, taqsimlanmagan foyda esa ichki moliyalashtirish manbaidir.'
      ),
      bad:L(
        'Retained profit is not external finance. External growth normally involves merger or takeover of another business.',
        'Нераспределённая прибыль не является внешним финансированием. Внешний рост обычно связан со слиянием или поглощением другой фирмы.',
        'Taqsimlanmagan foyda tashqi moliya emas. Tashqi o‘sish odatda boshqa biznes bilan qo‘shilish yoki uni sotib olish orqali yuz beradi.'
      ),
      next:L(
        'Separate the method of growth from the source of finance.',
        'Разделите способ роста фирмы и источник его финансирования.',
        'Firma o‘sish usuli bilan moliyalashtirish manbasini ajrating.'
      )
    }
  ]
};

try {
  const prefix = 'iclub_demo_v12.';
  const cacheKey = prefix + 'cache';
  const historyKey = prefix + 'history';
  const stateKey = prefix + 'state';
  const current = JSON.parse(localStorage.getItem(cacheKey) || '{}');

  if (current.datasetVersion !== window.ICLUB_DEMO_V12_DATA.version) {
    const previousState = JSON.parse(localStorage.getItem(stateKey) || '{}');
    localStorage.setItem(historyKey, JSON.stringify({
      datasetVersion: window.ICLUB_DEMO_V12_DATA.version,
      baseline: window.ICLUB_DEMO_V12_DATA.history,
      diagnostics: []
    }));
    localStorage.setItem(stateKey, JSON.stringify({
      plan: previousState.plan || 'free',
      lang: previousState.lang || 'ru',
      screen: 'hub'
    }));
    localStorage.setItem(cacheKey, JSON.stringify({
      datasetVersion: window.ICLUB_DEMO_V12_DATA.version,
      currentAttemptId: null,
      answerEvents: [],
      autofillRemaining: false
    }));
  }
} catch {}
})();

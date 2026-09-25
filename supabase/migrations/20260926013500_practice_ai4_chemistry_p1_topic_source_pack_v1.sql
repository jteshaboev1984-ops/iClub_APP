-- AI-4 Chemistry Practice 1 broad governed source pack v1.
-- Original iClub summaries grounded in the current Chemistry Practice 1 topic map.
-- Broad fallback only: question_id and subtopic are intentionally NULL.
-- This migration does not add diagnostic mappings, enable AI, grant entitlements,
-- change scoring, or mutate learner academic/history state.

insert into private.practice_ai_source_cards(
  source_card_key,subject_key,question_id,topic,subtopic,card_type,locale,source_version,
  title,body_text,approval_status,rights_status,is_runtime_allowed,content_hash,approved_at,updated_at
)
values
(
  'practice:chemistry:p1:topic:atomic-structure:en:v1','chemistry',null,'Atomic structure',null,
  'answer_explanation','en','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Atomic structure and subatomic particles',
  'Atoms contain a very small positively charged nucleus with protons and neutrons, while negatively charged electrons occupy the space around it. Atomic number equals the number of protons, and mass number equals protons plus neutrons. A neutral atom has equal numbers of protons and electrons. Positive ions form by losing electrons and negative ions by gaining electrons. Isotopes have the same number of protons but different numbers of neutrons. Relative atomic mass is a weighted mean compared with one twelfth of the mass of a carbon-12 atom.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Atoms contain a very small positively charged nucleus with protons and neutrons, while negatively charged electrons occupy the space around it. Atomic number equals the number of protons, and mass number equals protons plus neutrons. A neutral atom has equal numbers of protons and electrons. Positive ions form by losing electrons and negative ions by gaining electrons. Isotopes have the same number of protons but different numbers of neutrons. Relative atomic mass is a weighted mean compared with one twelfth of the mass of a carbon-12 atom.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:atomic-structure:ru:v1','chemistry',null,'Atomic structure',null,
  'answer_explanation','ru','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Строение атома и субатомные частицы',
  'Атом содержит очень маленькое положительно заряженное ядро с протонами и нейтронами, а отрицательно заряженные электроны находятся вокруг ядра. Атомный номер равен числу протонов, а массовое число — сумме протонов и нейтронов. В нейтральном атоме число протонов равно числу электронов. Положительные ионы образуются при потере электронов, отрицательные — при их присоединении. Изотопы имеют одинаковое число протонов, но разное число нейтронов. Относительная атомная масса — это средневзвешенная масса по сравнению с одной двенадцатой массы атома углерода-12.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Атом содержит очень маленькое положительно заряженное ядро с протонами и нейтронами, а отрицательно заряженные электроны находятся вокруг ядра. Атомный номер равен числу протонов, а массовое число — сумме протонов и нейтронов. В нейтральном атоме число протонов равно числу электронов. Положительные ионы образуются при потере электронов, отрицательные — при их присоединении. Изотопы имеют одинаковое число протонов, но разное число нейтронов. Относительная атомная масса — это средневзвешенная масса по сравнению с одной двенадцатой массы атома углерода-12.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:atomic-structure:uz:v1','chemistry',null,'Atomic structure',null,
  'answer_explanation','uz','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Atom tuzilishi va subatom zarrachalar',
  'Atom juda kichik musbat zaryadlangan yadrodan iborat bo‘lib, yadroda proton va neytronlar joylashadi, manfiy zaryadlangan elektronlar esa uning atrofida bo‘ladi. Atom raqami protonlar soniga, massa soni esa protonlar va neytronlar yig‘indisiga teng. Neytral atomda protonlar soni elektronlar soniga teng. Musbat ion elektron yo‘qotish, manfiy ion esa elektron qabul qilish orqali hosil bo‘ladi. Izotoplarda protonlar soni bir xil, neytronlar soni esa turlicha bo‘ladi. Nisbiy atom massasi uglerod-12 atomi massasining o‘n ikkidan bir qismiga nisbatan olingan og‘irliklangan o‘rtacha massadir.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Atom juda kichik musbat zaryadlangan yadrodan iborat bo‘lib, yadroda proton va neytronlar joylashadi, manfiy zaryadlangan elektronlar esa uning atrofida bo‘ladi. Atom raqami protonlar soniga, massa soni esa protonlar va neytronlar yig‘indisiga teng. Neytral atomda protonlar soni elektronlar soniga teng. Musbat ion elektron yo‘qotish, manfiy ion esa elektron qabul qilish orqali hosil bo‘ladi. Izotoplarda protonlar soni bir xil, neytronlar soni esa turlicha bo‘ladi. Nisbiy atom massasi uglerod-12 atomi massasining o‘n ikkidan bir qismiga nisbatan olingan og‘irliklangan o‘rtacha massadir.','UTF8'),'sha256'),'hex'),
  now(),now()
),

(
  'practice:chemistry:p1:topic:electrons-in-atoms:en:v1','chemistry',null,'Electrons in atoms',null,
  'answer_explanation','en','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Electron arrangements and periodic trends',
  'Electrons occupy shells, subshells and orbitals. Each orbital can hold a maximum of two electrons; an s subshell contains one orbital and a p subshell contains three, so their maximum capacities are 2 and 6 electrons. Ground-state electron configurations fill available orbitals in increasing energy order. Valence electrons help explain similar chemical behaviour within a group. Across a period, increasing nuclear charge with broadly similar shielding generally strengthens attraction to outer electrons, so atomic radius tends to decrease and first ionisation energy tends to increase. Down a group, additional shells and greater shielding generally increase radius and lower ionisation energy. Large jumps in successive ionisation energies can reveal the number of valence electrons.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Electrons occupy shells, subshells and orbitals. Each orbital can hold a maximum of two electrons; an s subshell contains one orbital and a p subshell contains three, so their maximum capacities are 2 and 6 electrons. Ground-state electron configurations fill available orbitals in increasing energy order. Valence electrons help explain similar chemical behaviour within a group. Across a period, increasing nuclear charge with broadly similar shielding generally strengthens attraction to outer electrons, so atomic radius tends to decrease and first ionisation energy tends to increase. Down a group, additional shells and greater shielding generally increase radius and lower ionisation energy. Large jumps in successive ionisation energies can reveal the number of valence electrons.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:electrons-in-atoms:ru:v1','chemistry',null,'Electrons in atoms',null,
  'answer_explanation','ru','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Электронное строение и периодические тенденции',
  'Электроны занимают энергетические уровни, подуровни и орбитали. На одной орбитали может находиться не более двух электронов; s-подуровень содержит одну орбиталь, а p-подуровень — три, поэтому их максимальная вместимость равна 2 и 6 электронам. Электронная конфигурация основного состояния заполняет доступные орбитали в порядке возрастания энергии. Валентные электроны помогают объяснить сходные химические свойства элементов одной группы. В периоде рост заряда ядра при примерно сходном экранировании обычно усиливает притяжение внешних электронов, поэтому атомный радиус уменьшается, а первая энергия ионизации в целом возрастает. Вниз по группе дополнительные оболочки и усиление экранирования обычно увеличивают радиус и уменьшают энергию ионизации. Большой скачок между последовательными энергиями ионизации может указывать на число валентных электронов.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Электроны занимают энергетические уровни, подуровни и орбитали. На одной орбитали может находиться не более двух электронов; s-подуровень содержит одну орбиталь, а p-подуровень — три, поэтому их максимальная вместимость равна 2 и 6 электронам. Электронная конфигурация основного состояния заполняет доступные орбитали в порядке возрастания энергии. Валентные электроны помогают объяснить сходные химические свойства элементов одной группы. В периоде рост заряда ядра при примерно сходном экранировании обычно усиливает притяжение внешних электронов, поэтому атомный радиус уменьшается, а первая энергия ионизации в целом возрастает. Вниз по группе дополнительные оболочки и усиление экранирования обычно увеличивают радиус и уменьшают энергию ионизации. Большой скачок между последовательными энергиями ионизации может указывать на число валентных электронов.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:electrons-in-atoms:uz:v1','chemistry',null,'Electrons in atoms',null,
  'answer_explanation','uz','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Elektron tuzilishi va davriy tendensiyalar',
  'Elektronlar energetik qavatlar, qavatchalar va orbitallarda joylashadi. Har bir orbital ko‘pi bilan ikki elektron sig‘diradi; s-qavatchada bitta orbital, p-qavatchada esa uchta orbital bo‘ladi, shu sababli ularning maksimal sig‘imi mos ravishda 2 va 6 elektron. Asosiy holat elektron konfiguratsiyasida mavjud orbitallar energiyasi ortib borish tartibida to‘ldiriladi. Valent elektronlar bir guruhdagi elementlarning o‘xshash kimyoviy xossalarini tushuntirishga yordam beradi. Davr bo‘ylab yadro zaryadi ortib, ekranlanish taxminan o‘xshash qolganida tashqi elektronlarga tortish kuchi odatda kuchayadi; atom radiusi kamayib, birinchi ionlanish energiyasi umumiy holda ortadi. Guruh bo‘ylab pastga tushganda qo‘shimcha qavatlar va kuchliroq ekranlanish radiusni oshirib, ionlanish energiyasini kamaytiradi. Ketma-ket ionlanish energiyalaridagi katta sakrash valent elektronlar sonini ko‘rsatishi mumkin.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Elektronlar energetik qavatlar, qavatchalar va orbitallarda joylashadi. Har bir orbital ko‘pi bilan ikki elektron sig‘diradi; s-qavatchada bitta orbital, p-qavatchada esa uchta orbital bo‘ladi, shu sababli ularning maksimal sig‘imi mos ravishda 2 va 6 elektron. Asosiy holat elektron konfiguratsiyasida mavjud orbitallar energiyasi ortib borish tartibida to‘ldiriladi. Valent elektronlar bir guruhdagi elementlarning o‘xshash kimyoviy xossalarini tushuntirishga yordam beradi. Davr bo‘ylab yadro zaryadi ortib, ekranlanish taxminan o‘xshash qolganida tashqi elektronlarga tortish kuchi odatda kuchayadi; atom radiusi kamayib, birinchi ionlanish energiyasi umumiy holda ortadi. Guruh bo‘ylab pastga tushganda qo‘shimcha qavatlar va kuchliroq ekranlanish radiusni oshirib, ionlanish energiyasini kamaytiradi. Ketma-ket ionlanish energiyalaridagi katta sakrash valent elektronlar sonini ko‘rsatishi mumkin.','UTF8'),'sha256'),'hex'),
  now(),now()
),

(
  'practice:chemistry:p1:topic:stoichiometry:en:v1','chemistry',null,'Stoichiometry',null,
  'answer_explanation','en','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Moles and quantitative chemistry',
  'Stoichiometry links measured quantities through the mole. For a substance, amount in moles can be found from n = m/M, where mass and molar mass use consistent units. Number of particles equals moles multiplied by the Avogadro constant. Solution concentration is c = n/V when volume is in dm3. Gas calculations use the molar gas volume stated for the specified conditions. Balanced chemical equations provide mole ratios between reacting and produced substances. Empirical formulae come from the simplest whole-number mole ratio of elements, while molecular formulae use the empirical-formula mass together with Mr. Unit conversion should be completed before substituting values.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Stoichiometry links measured quantities through the mole. For a substance, amount in moles can be found from n = m/M, where mass and molar mass use consistent units. Number of particles equals moles multiplied by the Avogadro constant. Solution concentration is c = n/V when volume is in dm3. Gas calculations use the molar gas volume stated for the specified conditions. Balanced chemical equations provide mole ratios between reacting and produced substances. Empirical formulae come from the simplest whole-number mole ratio of elements, while molecular formulae use the empirical-formula mass together with Mr. Unit conversion should be completed before substituting values.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:stoichiometry:ru:v1','chemistry',null,'Stoichiometry',null,
  'answer_explanation','ru','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Количество вещества и количественные расчёты',
  'Стехиометрия связывает измеряемые величины через количество вещества в молях. Количество вещества можно найти по формуле n = m/M, если масса и молярная масса выражены в согласованных единицах. Число частиц равно количеству молей, умноженному на постоянную Авогадро. Концентрация раствора определяется как c = n/V, если объём выражен в дм3. В расчётах газов используется молярный объём, указанный для данных условий. Сбалансированные химические уравнения задают мольные отношения реагентов и продуктов. Эмпирическую формулу получают из простейшего целочисленного отношения количеств элементов, а молекулярную формулу — с использованием массы эмпирической формулы и Mr. Перед подстановкой значений нужно привести единицы к нужному виду.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Стехиометрия связывает измеряемые величины через количество вещества в молях. Количество вещества можно найти по формуле n = m/M, если масса и молярная масса выражены в согласованных единицах. Число частиц равно количеству молей, умноженному на постоянную Авогадро. Концентрация раствора определяется как c = n/V, если объём выражен в дм3. В расчётах газов используется молярный объём, указанный для данных условий. Сбалансированные химические уравнения задают мольные отношения реагентов и продуктов. Эмпирическую формулу получают из простейшего целочисленного отношения количеств элементов, а молекулярную формулу — с использованием массы эмпирической формулы и Mr. Перед подстановкой значений нужно привести единицы к нужному виду.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:stoichiometry:uz:v1','chemistry',null,'Stoichiometry',null,
  'answer_explanation','uz','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Modda miqdori va miqdoriy hisoblashlar',
  'Stoxiometriya o‘lchanadigan kattaliklarni mol orqali bog‘laydi. Modda miqdori n = m/M formulasi bilan topiladi, bunda massa va molyar massa mos birliklarda bo‘lishi kerak. Zarrachalar soni mol miqdorini Avogadro doimiysiga ko‘paytirish orqali topiladi. Eritma konsentratsiyasi hajm dm3 da berilganda c = n/V bilan hisoblanadi. Gaz hisoblarida aynan berilgan sharoit uchun ko‘rsatilgan molyar gaz hajmi ishlatiladi. Tenglashtirilgan kimyoviy tenglamalar reaktant va mahsulotlar orasidagi mol nisbatlarini beradi. Empirik formula elementlarning eng sodda butun sonli mol nisbatidan, molekulyar formula esa empirik formula massasi va Mr yordamida topiladi. Qiymatlarni formulaga qo‘yishdan oldin birliklarni moslashtirish zarur.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Stoxiometriya o‘lchanadigan kattaliklarni mol orqali bog‘laydi. Modda miqdori n = m/M formulasi bilan topiladi, bunda massa va molyar massa mos birliklarda bo‘lishi kerak. Zarrachalar soni mol miqdorini Avogadro doimiysiga ko‘paytirish orqali topiladi. Eritma konsentratsiyasi hajm dm3 da berilganda c = n/V bilan hisoblanadi. Gaz hisoblarida aynan berilgan sharoit uchun ko‘rsatilgan molyar gaz hajmi ishlatiladi. Tenglashtirilgan kimyoviy tenglamalar reaktant va mahsulotlar orasidagi mol nisbatlarini beradi. Empirik formula elementlarning eng sodda butun sonli mol nisbatidan, molekulyar formula esa empirik formula massasi va Mr yordamida topiladi. Qiymatlarni formulaga qo‘yishdan oldin birliklarni moslashtirish zarur.','UTF8'),'sha256'),'hex'),
  now(),now()
),

(
  'practice:chemistry:p1:topic:atoms-molecules-stoichiometry:en:v1','chemistry',null,'Atoms, molecules and stoichiometry',null,
  'answer_explanation','en','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Particles, formula masses and mole relationships',
  'Chemical formulae show the relative numbers of atoms in substances, and relative formula mass Mr is found by adding the relevant relative atomic masses. Mass and amount are linked by n = m/M. Particle number is linked to amount by the Avogadro constant. For gases, amount can be related to volume using the molar gas volume stated for the conditions in the question. In hydrated salts, the value of x is found by comparing the moles of water lost with the moles of anhydrous salt remaining and reducing the ratio to small whole numbers.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Chemical formulae show the relative numbers of atoms in substances, and relative formula mass Mr is found by adding the relevant relative atomic masses. Mass and amount are linked by n = m/M. Particle number is linked to amount by the Avogadro constant. For gases, amount can be related to volume using the molar gas volume stated for the conditions in the question. In hydrated salts, the value of x is found by comparing the moles of water lost with the moles of anhydrous salt remaining and reducing the ratio to small whole numbers.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:atoms-molecules-stoichiometry:ru:v1','chemistry',null,'Atoms, molecules and stoichiometry',null,
  'answer_explanation','ru','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Частицы, формульные массы и мольные соотношения',
  'Химические формулы показывают относительное число атомов в веществе, а относительную формульную массу Mr находят суммированием соответствующих относительных атомных масс. Масса и количество вещества связаны формулой n = m/M. Число частиц связано с количеством вещества через постоянную Авогадро. Для газов количество вещества можно связать с объёмом с помощью молярного объёма, указанного для условий задачи. Для кристаллогидратов значение x находят, сравнивая количество молей потерянной воды с количеством молей оставшейся безводной соли и приводя отношение к небольшим целым числам.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Химические формулы показывают относительное число атомов в веществе, а относительную формульную массу Mr находят суммированием соответствующих относительных атомных масс. Масса и количество вещества связаны формулой n = m/M. Число частиц связано с количеством вещества через постоянную Авогадро. Для газов количество вещества можно связать с объёмом с помощью молярного объёма, указанного для условий задачи. Для кристаллогидратов значение x находят, сравнивая количество молей потерянной воды с количеством молей оставшейся безводной соли и приводя отношение к небольшим целым числам.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:atoms-molecules-stoichiometry:uz:v1','chemistry',null,'Atoms, molecules and stoichiometry',null,
  'answer_explanation','uz','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Zarrachalar, formula massalari va mol nisbatlari',
  'Kimyoviy formulalar moddadagi atomlarning nisbiy sonini ko‘rsatadi, nisbiy formula massasi Mr esa tegishli nisbiy atom massalarini qo‘shish orqali topiladi. Massa va modda miqdori n = m/M formulasi bilan bog‘langan. Zarrachalar soni modda miqdori bilan Avogadro doimiysi orqali bog‘lanadi. Gazlarda modda miqdorini savolda berilgan sharoit uchun molyar gaz hajmi yordamida hajm bilan bog‘lash mumkin. Kristallogidratlarda x qiymati yo‘qotilgan suv mollari bilan qolgan suvsiz tuz mollari nisbatini topib, uni kichik butun sonlarga keltirish orqali aniqlanadi.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Kimyoviy formulalar moddadagi atomlarning nisbiy sonini ko‘rsatadi, nisbiy formula massasi Mr esa tegishli nisbiy atom massalarini qo‘shish orqali topiladi. Massa va modda miqdori n = m/M formulasi bilan bog‘langan. Zarrachalar soni modda miqdori bilan Avogadro doimiysi orqali bog‘lanadi. Gazlarda modda miqdorini savolda berilgan sharoit uchun molyar gaz hajmi yordamida hajm bilan bog‘lash mumkin. Kristallogidratlarda x qiymati yo‘qotilgan suv mollari bilan qolgan suvsiz tuz mollari nisbatini topib, uni kichik butun sonlarga keltirish orqali aniqlanadi.','UTF8'),'sha256'),'hex'),
  now(),now()
),

(
  'practice:chemistry:p1:topic:chemical:en:v1','chemistry',null,'Chemical',null,
  'answer_explanation','en','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Core chemical relationships',
  'This broad topic currently contains several different introductory relationships, so the exact rule depends on the stated subtopic. Across a period, increasing nuclear charge with broadly similar shielding generally strengthens attraction to outer electrons, tending to reduce atomic radius and raise ionisation energy. Mass number equals protons plus neutrons, and isotopes of an element differ in neutron number. Quantitative questions may use n = m/M, concentration c = n/V with volume in dm3, or a molar gas volume explicitly stated for the conditions. Use the question subtopic and given conditions before selecting a relationship.',
  'approved','original_iclub',true,
  encode(digest(convert_to('This broad topic currently contains several different introductory relationships, so the exact rule depends on the stated subtopic. Across a period, increasing nuclear charge with broadly similar shielding generally strengthens attraction to outer electrons, tending to reduce atomic radius and raise ionisation energy. Mass number equals protons plus neutrons, and isotopes of an element differ in neutron number. Quantitative questions may use n = m/M, concentration c = n/V with volume in dm3, or a molar gas volume explicitly stated for the conditions. Use the question subtopic and given conditions before selecting a relationship.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:chemical:ru:v1','chemistry',null,'Chemical',null,
  'answer_explanation','ru','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Основные химические взаимосвязи',
  'Этот широкий раздел сейчас объединяет несколько разных вводных взаимосвязей, поэтому точное правило зависит от конкретной подтемы. В периоде увеличение заряда ядра при примерно сходном экранировании обычно усиливает притяжение внешних электронов, что в целом уменьшает атомный радиус и повышает энергию ионизации. Массовое число равно сумме протонов и нейтронов, а изотопы одного элемента различаются числом нейтронов. В количественных задачах могут использоваться n = m/M, концентрация c = n/V при объёме в дм3 или молярный объём газа, явно указанный для данных условий. Перед выбором зависимости нужно учитывать подтему и условия конкретного вопроса.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Этот широкий раздел сейчас объединяет несколько разных вводных взаимосвязей, поэтому точное правило зависит от конкретной подтемы. В периоде увеличение заряда ядра при примерно сходном экранировании обычно усиливает притяжение внешних электронов, что в целом уменьшает атомный радиус и повышает энергию ионизации. Массовое число равно сумме протонов и нейтронов, а изотопы одного элемента различаются числом нейтронов. В количественных задачах могут использоваться n = m/M, концентрация c = n/V при объёме в дм3 или молярный объём газа, явно указанный для данных условий. Перед выбором зависимости нужно учитывать подтему и условия конкретного вопроса.','UTF8'),'sha256'),'hex'),
  now(),now()
),
(
  'practice:chemistry:p1:topic:chemical:uz:v1','chemistry',null,'Chemical',null,
  'answer_explanation','uz','iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25',
  'Asosiy kimyoviy bog‘lanishlar',
  'Bu keng mavzu hozir bir nechta turli boshlang‘ich bog‘lanishlarni birlashtiradi, shuning uchun aniq qoida savoldagi subtopicga bog‘liq. Davr bo‘ylab yadro zaryadi ortib, ekranlanish taxminan o‘xshash qolsa, tashqi elektronlarga tortish kuchi odatda kuchayadi; natijada atom radiusi kamayishga, ionlanish energiyasi esa ortishga moyil bo‘ladi. Massa soni protonlar va neytronlar yig‘indisiga teng, bir element izotoplari esa neytronlar soni bilan farqlanadi. Miqdoriy savollarda n = m/M, hajm dm3 da bo‘lganda c = n/V yoki aynan berilgan sharoit uchun ko‘rsatilgan molyar gaz hajmi ishlatilishi mumkin. Bog‘lanishni tanlashdan oldin savolning subtopicini va berilgan sharoitlarini tekshirish kerak.',
  'approved','original_iclub',true,
  encode(digest(convert_to('Bu keng mavzu hozir bir nechta turli boshlang‘ich bog‘lanishlarni birlashtiradi, shuning uchun aniq qoida savoldagi subtopicga bog‘liq. Davr bo‘ylab yadro zaryadi ortib, ekranlanish taxminan o‘xshash qolsa, tashqi elektronlarga tortish kuchi odatda kuchayadi; natijada atom radiusi kamayishga, ionlanish energiyasi esa ortishga moyil bo‘ladi. Massa soni protonlar va neytronlar yig‘indisiga teng, bir element izotoplari esa neytronlar soni bilan farqlanadi. Miqdoriy savollarda n = m/M, hajm dm3 da bo‘lganda c = n/V yoki aynan berilgan sharoit uchun ko‘rsatilgan molyar gaz hajmi ishlatilishi mumkin. Bog‘lanishni tanlashdan oldin savolning subtopicini va berilgan sharoitlarini tekshirish kerak.','UTF8'),'sha256'),'hex'),
  now(),now()
)
on conflict(source_card_key) do update
set subject_key=excluded.subject_key,
    question_id=excluded.question_id,
    topic=excluded.topic,
    subtopic=excluded.subtopic,
    card_type=excluded.card_type,
    locale=excluded.locale,
    source_version=excluded.source_version,
    title=excluded.title,
    body_text=excluded.body_text,
    approval_status=excluded.approval_status,
    rights_status=excluded.rights_status,
    is_runtime_allowed=excluded.is_runtime_allowed,
    content_hash=excluded.content_hash,
    approved_at=coalesce(private.practice_ai_source_cards.approved_at,excluded.approved_at),
    updated_at=now();

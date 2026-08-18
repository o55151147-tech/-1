Config = {}

-- الأمر اللي يفتح قائمة التصنيع (يفضل يبقى كخيار احتياطي حتى مع طاولة التصنيع)
Config.Command = 'craft'

-- طاولات التصنيع بالخريطة. قف بالمكان اللي تبي تحط فيه الطاولة وشغّل الأمر /getcoords
-- بالشات عشان يطلع لك الإحداثيات والهيدنج بكونسول F8، ثم عدّل القيم هنا
-- تقدر تضيف أكثر من طاولة بأكثر من موقع
Config.CraftingTables = {
    {
        coords = vector3(-423.52, 2064.85, 119.01),
        heading = 0.0,
        prop = 'prop_tool_bench02_ld',
    },
}

-- أقصى مسافة للتفاعل مع طاولة التصنيع عبر qb-target
Config.TableInteractDistance = 2.0

-- أقصى مسافة للتفاعل مع المركبة عبر qb-target
Config.MaxSearchDistance = 2.5

-- المركبة لازم تكون تالفة عشان تقدر تفتشها عن سكراب (مو أي مركبة شغالة عادي)
-- لو صحة المحرك أو الهيكل أقل من هذا الرقم (من أصل 1000) أو المركبة مو قابلة للقيادة، تصير قابلة للتفتيش
Config.ScrapVehicleMaxHealth = 400.0

-- وقت شريط التقدم عند تفتيش مركبة (مللي ثانية)
Config.SearchTime = 8000

-- كم ثانية لازم تمر قبل ما تقدر تفتش نفس المركبة مرة ثانية
Config.VehicleCooldown = 300

-- أقصى عدد يقدر اللاعب يصنعه دفعة وحدة من نفس العنصر
Config.MaxCraftAmount = 10

-- نظام مستوى بسيط: كل وصفة تصنيع لها مستوى مطلوب خاص فيها (requiredLevel بالأسفل).
-- الخبرة تُكتسب من التفتيش عن سكراب ومن التصنيع نفسه، وتُخزّن بميتاداتا اللاعب (metadata.craftxp)
-- فتبقى محفوظة حتى بعد الخروج
-- النظام تراكمي: المستوى N يحتاج (N × xpPerLevel) نقطة خبرة، يعني كل مستوى أصعب من اللي قبله
-- مثال بـ xpPerLevel=100: مستوى1=100، مستوى2=200، مستوى3=300... (تراكمي: مجموع لين توصله)
Config.Leveling = {
    maxLevel = 10,          -- أعلى مستوى ممكن يوصله اللاعب (يستخدم للعرض بالواجهة فقط)
    xpPerLevel = 100,       -- الوحدة الأساسية لحساب صعوبة كل مستوى (شوف الشرح فوق)
    xpPerSearch = 15,       -- الخبرة اللي تاخذها من كل عملية تفتيش ناجحة (مركبة أو حطام)
    xpPerCraft = 10,        -- الخبرة اللي تاخذها في كل مرة تصنع فيها عنصر (لكل نسخة واحدة تصنعها)
}

-- موديلات حطام السيارات الثابتة (props) اللي تقدر تفتشها عن سكراب، مثل اللي بمقابر الخردة
-- هذي موديلات فانيلا رسمية باللعبة. لو خريطتك تستخدم موديلات مخصصة (custom junkyard map)
-- شغّل الأمر /scrapfind وانت واقف جنب الحطام عشان تطلع لك الهاشات بالكونسول (F8) وتضيفها هنا
Config.ScrapProps = {
    'prop_rub_buswreck_0',
    'prop_rub_carwreck_1',
    'prop_rub_carwreck_2',
    'prop_rub_carwreck_3',
    'prop_rub_carwreck_4',
    'prop_rub_carwreck_5',
    'prop_rub_carwreck_6',
    'prop_rub_carwreck_7',
    'prop_rub_carwreck_8',
    'prop_rub_carwreck_9',
    'prop_rub_carwreck_10',
    'prop_rub_carwreck_11',
    'prop_rub_carwreck_12',
    'prop_rub_carwreck_13',
    'prop_rub_carwreck_14',
    'prop_rub_carwreck_15',
    'prop_rub_carwreck_16',
}

-- المواد اللي ممكن تطلع من تفتيش مركبة، كل مادة عندها نسبة احتمال مستقلة
-- تأكد إن كل item موجود أصلاً بـ qb-core/shared/items.lua
Config.ScrapItems = {
    { item = 'metalscrap', min = 1, max = 3, chance = 70 },
    { item = 'plastic',    min = 1, max = 2, chance = 55 },
    { item = 'rubber',     min = 1, max = 2, chance = 45 },
    { item = 'cloth',      min = 1, max = 2, chance = 45 },
    { item = 'copperwire', min = 1, max = 2, chance = 30 },
}

-- وصفات التصنيع. name لازم يطابق اسم item موجود بـ qb-core/shared/items.lua
Config.CraftingItems = {
    {
        name = 'lockpick',
        label = 'فاتح اقفال متقدم',
        description = 'أداة لفتح الأقفال يدوياً',
        category = 'tools',
        amount = 1,
        time = 6000,
        requiredLevel = 0,
        ingredients = {
            { item = 'metalscrap', amount = 3 },
            { item = 'plastic',    amount = 1 },
        }
    },
    {
        name = 'bandage',
        label = 'ضمادة',
        description = 'تستخدم لعلاج الجروح البسيطة',
        category = 'medical',
        amount = 2,
        time = 4000,
        requiredLevel = 1,
        ingredients = {
            { item = 'cloth', amount = 3 },
        }
    },
    {
        name = 'handcuffs_b',
        label = 'كلبشه',
        description = '  ',
        category = 'utility',
        amount = 1,
        time = 6000,
        requiredLevel = 3,
        ingredients = {
            { item = 'plastic',    amount = 2 },
            { item = 'metalscrap', amount = 1 },
        }
    },
    {
        name = 'weapon_bat',
        label = 'عجره ',
        description = 'أداة دفاع شخصي بسيطة',
        category = 'defense',
        amount = 1,
        time = 8000,
        requiredLevel = 4,
        ingredients = {
            { item = 'metalscrap', amount = 2 },
            { item = 'cloth',      amount = 2 },
        }
    },
    {
        name = 'weapon_snspistol',
        label = ' جلوك 21',
        description = 'يستخدم لتصليح المركبات ميدانياً',
        category = 'tools',
        amount = 1,
        time = 20000,
        requiredLevel = 7,
        ingredients = {
            { item = 'metalscrap', amount = 99 },
            { item = 'copperwire', amount = 99 },
            { item = 'rubber',     amount = 99 },
        }
    },
}

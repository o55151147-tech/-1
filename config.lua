Config = {}

-- الأمر اللي يفتح قائمة التصنيع (ممكن تربطه بدل كذا بعنصر "حقيبة أدوات" لو تحب)
Config.Command = 'craft'

-- أقصى مسافة للتفاعل مع المركبة عبر qb-target
Config.MaxSearchDistance = 2.5

-- وقت شريط التقدم عند تفتيش مركبة (مللي ثانية)
Config.SearchTime = 8000

-- كم ثانية لازم تمر قبل ما تقدر تفتش نفس المركبة مرة ثانية
Config.VehicleCooldown = 300

-- أقصى عدد يقدر اللاعب يصنعه دفعة وحدة من نفس العنصر
Config.MaxCraftAmount = 10

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
        label = 'Lockpick',
        description = 'أداة لفتح الأقفال يدوياً',
        category = 'tools',
        amount = 1,
        time = 6000,
        ingredients = {
            { item = 'metalscrap', amount = 3 },
            { item = 'plastic',    amount = 1 },
        }
    },
    {
        name = 'weapon_bat',
        label = 'عصا بيسبول',
        description = 'أداة دفاع شخصي بسيطة',
        category = 'defense',
        amount = 1,
        time = 8000,
        ingredients = {
            { item = 'metalscrap', amount = 2 },
            { item = 'cloth',      amount = 2 },
        }
    },
    {
        name = 'repairkit',
        label = 'طقم تصليح',
        description = 'يستخدم لتصليح المركبات ميدانياً',
        category = 'tools',
        amount = 1,
        time = 7000,
        ingredients = {
            { item = 'metalscrap', amount = 4 },
            { item = 'copperwire', amount = 2 },
            { item = 'rubber',     amount = 1 },
        }
    },
    {
        name = 'bandage',
        label = 'ضمادة',
        description = 'تستخدم لعلاج الجروح البسيطة',
        category = 'medical',
        amount = 2,
        time = 4000,
        ingredients = {
            { item = 'cloth', amount = 3 },
        }
    },
    {
        name = 'binoculars',
        label = 'منظار',
        description = 'للمراقبة عن بعد',
        category = 'utility',
        amount = 1,
        time = 6000,
        ingredients = {
            { item = 'plastic',    amount = 2 },
            { item = 'metalscrap', amount = 1 },
        }
    },
}

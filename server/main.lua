local QBCore = exports['qb-core']:GetCoreObject()

-- ============ نظام المستوى (يقفل التصنيع لين أعلى مستوى) ============

-- كل مستوى يحتاج خبرة أكثر من اللي قبله (تراكمي): المستوى N يحتاج N * xpPerLevel
local function XpNeededForLevel(level)
    return Config.Leveling.xpPerLevel * level
end

local function GetLevelInfo(Player)
    local xp = (Player.PlayerData.metadata and Player.PlayerData.metadata.craftxp) or 0
    local level = 0
    local remaining = xp

    while level < Config.Leveling.maxLevel do
        local needed = XpNeededForLevel(level + 1)
        if remaining < needed then break end
        remaining = remaining - needed
        level = level + 1
    end

    local xpForNextLevel = level < Config.Leveling.maxLevel and XpNeededForLevel(level + 1) or 0

    return {
        level = level,
        xp = xp,
        xpIntoLevel = remaining,
        xpForNextLevel = xpForNextLevel,
        maxLevel = Config.Leveling.maxLevel,
        xpPerLevel = Config.Leveling.xpPerLevel,
    }
end

local function AddCraftXp(src, Player, amount)
    local before = GetLevelInfo(Player)
    local newXp = before.xp + amount
    Player.Functions.SetMetaData('craftxp', newXp)

    local after = GetLevelInfo(Player)
    if after.level > before.level then
        TriggerClientEvent('QBCore:Notify', src, ('ترقيت للمستوى %d/%d'):format(after.level, after.maxLevel), 'success')
    end
end

-- ============ إعطاء مكافأة السكراب (مشترك بين المركبات والحطام الثابت) ============

local function GiveScrapRewards(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local given = {}
    for _, scrap in ipairs(Config.ScrapItems) do
        if math.random(100) <= scrap.chance then
            local amount = math.random(scrap.min, scrap.max)
            if Player.Functions.AddItem(scrap.item, amount) then
                local itemInfo = QBCore.Shared.Items[scrap.item]
                if itemInfo then
                    TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add', amount)
                end
                table.insert(given, { item = scrap.item, amount = amount })
            end
        end
    end

    if #given > 0 then
        AddCraftXp(src, Player, Config.Leveling.xpPerSearch)
        TriggerClientEvent('QBCore:Notify', src, 'حصلت على مواد سكراب', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'ما لقيت شي مفيد هذي المرة', 'error')
    end
end

RegisterNetEvent('scrap-crafting:server:giveScrapReward', function(netId)
    local src = source

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    -- تحقق مسافة سيرفر-سايد لمنع استدعاء الحدث مباشرة بدون تفاعل فعلي
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local vehCoords = GetEntityCoords(vehicle)
    if #(pedCoords - vehCoords) > (Config.MaxSearchDistance + 3.0) then
        return
    end

    -- تحقق إن المركبة فعلاً تالفة، مو مركبة سليمة يحاول يفتشها بتلاعب بالعميل
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local wrecked = (not IsVehicleDriveable(vehicle, false)) or engineHealth < Config.ScrapVehicleMaxHealth or bodyHealth < Config.ScrapVehicleMaxHealth
    if not wrecked then
        return
    end

    GiveScrapRewards(src)
end)

-- حطام مقابر الخردة (props) ثابت بالخريطة ومالها netId، فنعتمد على كولداون
-- بسيط لكل لاعب بدل التحقق من موقع الغرض نفسه
local lastPropSearch = {}

RegisterNetEvent('scrap-crafting:server:givePropScrapReward', function()
    local src = source

    local last = lastPropSearch[src]
    if last and (os.time() - last) < math.floor(Config.SearchTime / 1000) then
        return
    end
    lastPropSearch[src] = os.time()

    GiveScrapRewards(src)
end)

AddEventHandler('playerDropped', function()
    lastPropSearch[source] = nil
end)

-- ============ التصنيع ============

QBCore.Functions.CreateCallback('scrap-crafting:server:craftItem', function(source, cb, itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        cb(false, 'خطأ في بيانات اللاعب')
        return
    end

    amount = math.floor(tonumber(amount) or 1)
    if amount < 1 then amount = 1 end
    if amount > Config.MaxCraftAmount then amount = Config.MaxCraftAmount end

    local recipe = nil
    for _, v in pairs(Config.CraftingItems) do
        if v.name == itemName then
            recipe = v
            break
        end
    end

    if not recipe then
        cb(false, 'وصفة غير موجودة')
        return
    end

    local levelInfo = GetLevelInfo(Player)
    local requiredLevel = recipe.requiredLevel or 0
    if levelInfo.level < requiredLevel then
        cb(false, ('لازم مستوى %d عشان تصنع هذا العنصر (مستواك الحالي: %d)'):format(requiredLevel, levelInfo.level))
        return
    end

    for _, ing in ipairs(recipe.ingredients) do
        local needed = ing.amount * amount
        local item = Player.Functions.GetItemByName(ing.item)
        if not item or item.amount < needed then
            cb(false, 'لا تملك المواد الكافية')
            return
        end
    end

    for _, ing in ipairs(recipe.ingredients) do
        local needed = ing.amount * amount
        Player.Functions.RemoveItem(ing.item, needed)
        local itemInfo = QBCore.Shared.Items[ing.item]
        if itemInfo then
            TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'remove', needed)
        end
    end

    local produced = recipe.amount * amount
    if Player.Functions.AddItem(recipe.name, produced) then
        local itemInfo = QBCore.Shared.Items[recipe.name]
        if itemInfo then
            TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add', produced)
        end
        local craftXpGained = Config.Leveling.xpPerCraft * amount
        AddCraftXp(src, Player, craftXpGained)
        TriggerClientEvent('QBCore:Notify', src, ('+%d خبرة تصنيع'):format(craftXpGained), 'primary')
        cb(true, 'تم تصنيع ' .. produced .. 'x ' .. recipe.label)
    else
        -- الإنفنتوري ممتلئ، رجّع المواد
        for _, ing in ipairs(recipe.ingredients) do
            Player.Functions.AddItem(ing.item, ing.amount * amount)
        end
        cb(false, 'الإنفنتوري ممتلئ')
    end
end)

-- ============ أمر اختبار: يزيد مستواك يدوياً (Admin فقط) ============
-- استخدم /addlevel لإضافة مستوى وحد، أو /addlevel 3 لإضافة 3 مستويات دفعة وحدة
-- شيل هذا الأمر أو قيّده أكثر قبل ما تفتح السيرفر للاعبين فعلياً

RegisterCommand('addlevel', function(source, args)
    local src = source
    if src == 0 then return end

    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'ما عندك صلاحية لهذا الأمر', 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local levels = tonumber(args[1]) or 1
    local before = GetLevelInfo(Player)
    local targetLevel = math.min(before.level + levels, Config.Leveling.maxLevel)

    local totalXpNeeded = 0
    for i = 1, targetLevel do
        totalXpNeeded = totalXpNeeded + XpNeededForLevel(i)
    end

    AddCraftXp(src, Player, math.max(totalXpNeeded - before.xp, 0))

    local after = GetLevelInfo(Player)
    TriggerClientEvent('QBCore:Notify', src, ('[اختبار] مستواك الحين: %d/%d'):format(after.level, after.maxLevel), 'success')
end, false)

-- ============ إرجاع عدد المواد الحالية للاعب (لعرضها بالواجهة) ============

QBCore.Functions.CreateCallback('scrap-crafting:server:getCounts', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        cb({ counts = {}, level = { level = 0, xp = 0, xpIntoLevel = 0, xpForNextLevel = Config.Leveling.xpPerLevel, maxLevel = Config.Leveling.maxLevel, xpPerLevel = Config.Leveling.xpPerLevel } })
        return
    end

    local counts = {}
    for _, recipe in ipairs(Config.CraftingItems) do
        for _, ing in ipairs(recipe.ingredients) do
            if not counts[ing.item] then
                local item = Player.Functions.GetItemByName(ing.item)
                counts[ing.item] = item and item.amount or 0
            end
        end
    end

    cb({ counts = counts, level = GetLevelInfo(Player) })
end)

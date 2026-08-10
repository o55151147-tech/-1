local QBCore = exports['qb-core']:GetCoreObject()

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
        cb(true, 'تم تصنيع ' .. produced .. 'x ' .. recipe.label)
    else
        -- الإنفنتوري ممتلئ، رجّع المواد
        for _, ing in ipairs(recipe.ingredients) do
            Player.Functions.AddItem(ing.item, ing.amount * amount)
        end
        cb(false, 'الإنفنتوري ممتلئ')
    end
end)

-- ============ إرجاع عدد المواد الحالية للاعب (لعرضها بالواجهة) ============

QBCore.Functions.CreateCallback('scrap-crafting:server:getCounts', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        cb({})
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

    cb(counts)
end)

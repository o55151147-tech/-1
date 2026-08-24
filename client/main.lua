local QBCore = exports['qb-core']:GetCoreObject()

local searchedVehicles = {}
local craftMenuOpen = false
local isBusy = false

-- ============ تفتيش المركبات عن سكراب ============

-- المركبة تعتبر تالفة (وبالتالي قابلة للتفتيش) لو صحة المحرك أو الهيكل تحت الحد المسموح، أو ما تقدر تنقاد أصلاً
local function IsVehicleWrecked(vehicle)
    if not IsVehicleDriveable(vehicle, false) then return true end

    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    return engineHealth < Config.ScrapVehicleMaxHealth or bodyHealth < Config.ScrapVehicleMaxHealth
end

CreateThread(function()
    exports['qb-target']:AddGlobalVehicle({
        options = {
            {
                icon = 'fas fa-search',
                label = 'تفتيش عن سكراب',
                action = function(entity)
                    SearchVehicleForScrap(entity)
                end,
                canInteract = function(entity)
                    return DoesEntityExist(entity)
                        and not IsPedInVehicle(PlayerPedId(), entity, false)
                        and not isBusy
                        and IsVehicleWrecked(entity)
                end,
            },
        },
        distance = Config.MaxSearchDistance,
    })
end)

-- يراقب زر ESC صراحة أثناء أي إجراء (تفتيش/تصنيع) ويلغيه فوراً بدل الاعتماد
-- على آلية الإلغاء المدمجة بـ qb-core اللي قد ما تستجيب لـ ESC بكل النسخ
local function WatchEscCancel(isFinished, onCancelled)
    CreateThread(function()
        while isBusy and not isFinished() do
            if IsControlJustPressed(0, 200) then -- ESC
                onCancelled()
                return
            end
            Wait(0)
        end
    end)
end

function SearchVehicleForScrap(vehicle)
    if isBusy or not DoesEntityExist(vehicle) then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local lastSearch = searchedVehicles[netId]
    if lastSearch and (GetGameTimer() - lastSearch) < (Config.VehicleCooldown * 1000) then
        QBCore.Functions.Notify('قمت بتفتيش هذه المركبة مؤخراً', 'error')
        return
    end

    local ped = PlayerPedId()
    isBusy = true
    local finished = false
    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(500)

    WatchEscCancel(function() return finished end, function()
        finished = true
        ClearPedTasks(ped)
        isBusy = false
        QBCore.Functions.Notify('تم إلغاء التفتيش', 'error')
    end)

    QBCore.Functions.Progressbar('search_vehicle_scrap', 'جاري تفتيش المركبة...', Config.SearchTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'mini@repair',
        anim = 'fixing_a_ped',
        flags = 16,
    }, {}, {}, function() -- Done
        if finished then return end
        finished = true
        ClearPedTasks(ped)
        isBusy = false
        searchedVehicles[netId] = GetGameTimer()
        TriggerServerEvent('scrap-crafting:server:giveScrapReward', netId)
    end, function() -- Cancel
        if finished then return end
        finished = true
        ClearPedTasks(ped)
        isBusy = false
        QBCore.Functions.Notify('تم إلغاء التفتيش', 'error')
    end)
end

-- ============ تفتيش حطام السيارات الثابت (props بمقابر الخردة) ============

local searchedProps = {}

CreateThread(function()
    if not Config.ScrapProps or #Config.ScrapProps == 0 then return end

    exports['qb-target']:AddTargetModel(Config.ScrapProps, {
        options = {
            {
                icon = 'fas fa-search',
                label = 'تفتيش عن سكراب',
                action = function(entity)
                    SearchWreckForScrap(entity)
                end,
                canInteract = function(entity)
                    return DoesEntityExist(entity) and not isBusy
                end,
            },
        },
        distance = Config.MaxSearchDistance,
    })
end)

function SearchWreckForScrap(entity)
    if isBusy or not DoesEntityExist(entity) then return end

    local lastSearch = searchedProps[entity]
    if lastSearch and (GetGameTimer() - lastSearch) < (Config.VehicleCooldown * 1000) then
        QBCore.Functions.Notify('قمت بتفتيش هذا الحطام مؤخراً', 'error')
        return
    end

    local ped = PlayerPedId()
    isBusy = true
    local finished = false
    TaskTurnPedToFaceEntity(ped, entity, 1000)
    Wait(500)

    WatchEscCancel(function() return finished end, function()
        finished = true
        ClearPedTasks(ped)
        isBusy = false
        QBCore.Functions.Notify('تم إلغاء التفتيش', 'error')
    end)

    QBCore.Functions.Progressbar('search_wreck_scrap', 'جاري تفتيش الحطام...', Config.SearchTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'mini@repair',
        anim = 'fixing_a_ped',
        flags = 16,
    }, {}, {}, function() -- Done
        if finished then return end
        finished = true
        ClearPedTasks(ped)
        isBusy = false
        searchedProps[entity] = GetGameTimer()
        TriggerServerEvent('scrap-crafting:server:givePropScrapReward')
    end, function() -- Cancel
        if finished then return end
        finished = true
        ClearPedTasks(ped)
        isBusy = false
        QBCore.Functions.Notify('تم إلغاء التفتيش', 'error')
    end)
end

-- أمر تشخيصي: قف جنب أي غرض ما يشتغل عليه التفتيش، شغّل /scrapfind
-- وشوف الهاشات بكونسول F8 عشان تعرف اسم الموديل الصحيح وتضيفه بـ Config.ScrapProps
RegisterCommand('scrapfind', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local objects = GetGamePool('CObject')
    local found = {}

    for _, obj in ipairs(objects) do
        local dist = #(coords - GetEntityCoords(obj))
        if dist < 6.0 then
            table.insert(found, { model = GetEntityModel(obj), dist = dist })
        end
    end

    if #found == 0 then
        QBCore.Functions.Notify('ما فيه أغراض قريبة منك', 'error')
        return
    end

    table.sort(found, function(a, b) return a.dist < b.dist end)

    print('^3[scrap-crafting]^0 أقرب موديلات حولك (استخدم هاش الموديل عشان تلقى اسمه بموقع gtax.dev/browser/props):')
    for i = 1, math.min(#found, 10) do
        print(('  #%d  model hash: %s   distance: %.2f'):format(i, found[i].model, found[i].dist))
    end

    QBCore.Functions.Notify('شوف كونسول F8 للهاشات', 'primary')
end, false)

-- ============ طاولة التصنيع ============

local spawnedTables = {}

CreateThread(function()
    if not Config.CraftingTables or #Config.CraftingTables == 0 then return end

    local uniqueModels = {}

    for _, loc in ipairs(Config.CraftingTables) do
        local model = GetHashKey(loc.prop)
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 100 do
            Wait(10)
            attempts = attempts + 1
        end

        if HasModelLoaded(model) then
            local obj = CreateObject(model, loc.coords.x, loc.coords.y, loc.coords.z, false, false, false)
            SetEntityHeading(obj, loc.heading or 0.0)
            SetEntityCollision(obj, true, true)
            PlaceObjectOnGroundProperly(obj) -- يحط الغرض بالضبط على سطح الأرض بدل ما يعتمد على z اليدوي
            FreezeEntityPosition(obj, true)
            spawnedTables[#spawnedTables + 1] = obj
        end

        SetModelAsNoLongerNeeded(model)
        uniqueModels[loc.prop] = true
    end

    local modelList = {}
    for modelName in pairs(uniqueModels) do
        modelList[#modelList + 1] = modelName
    end

    exports['qb-target']:AddTargetModel(modelList, {
        options = {
            {
                icon = 'fas fa-hammer',
                label = 'فتح ورشة التصنيع',
                action = function()
                    OpenCraftingMenu()
                end,
            },
        },
        distance = Config.TableInteractDistance,
    })
end)

-- يحذف الطاولات المسبونة صراحة عند إيقاف/إعادة تشغيل المورد
-- (بدل الاعتماد على تنظيف اللعبة التلقائي، اللي ما يصير أحياناً)
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, obj in ipairs(spawnedTables) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
end)

-- أمر مساعد يطبع إحداثيات موقعك الحالي بكونسول F8 عشان تحدد مكان طاولة التصنيع بالضبط
RegisterCommand('getcoords', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    print(('^3[scrap-crafting]^0 coords = vector3(%.2f, %.2f, %.2f), heading = %.2f'):format(coords.x, coords.y, coords.z, heading))
    QBCore.Functions.Notify('انسخ الإحداثيات من كونسول F8', 'primary')
end, false)

-- ============ قائمة التصنيع ============

RegisterCommand(Config.Command, function()
    OpenCraftingMenu()
end, false)

function OpenCraftingMenu()
    if craftMenuOpen then return end

    QBCore.Functions.TriggerCallback('scrap-crafting:server:getCounts', function(result)
        craftMenuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            items = Config.CraftingItems,
            counts = result.counts,
            level = result.level,
            maxAmount = Config.MaxCraftAmount,
            xpPerCraft = Config.Leveling.xpPerCraft,
        })
    end)
end

RegisterNUICallback('close', function(_, cb)
    craftMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- تستدعيها الواجهة (زر "إلغاء التصنيع") بنفس ما يسويه زر ESC بالضبط
local cancelActiveCraft = nil

RegisterNUICallback('cancelCraft', function(_, cb)
    if cancelActiveCraft then cancelActiveCraft() end
    cb('ok')
end)

RegisterNUICallback('craft', function(data, cb)
    if isBusy then
        cb('busy')
        return
    end

    local recipeName = data.item
    local amount = math.floor(tonumber(data.amount) or 1)
    if amount < 1 then amount = 1 end
    if amount > Config.MaxCraftAmount then amount = Config.MaxCraftAmount end

    local recipe = nil
    for _, v in pairs(Config.CraftingItems) do
        if v.name == recipeName then
            recipe = v
            break
        end
    end

    if not recipe then
        cb('invalid')
        return
    end

    isBusy = true
    local finished = false
    local ped = PlayerPedId()
    local craftTime = math.min(recipe.time * amount, 60000)

    local function doCancel()
        if finished then return end
        finished = true
        cancelActiveCraft = nil
        ClearPedTasks(ped)
        isBusy = false
        SendNUIMessage({ action = 'craftResult', success = false, message = 'تم الإلغاء', item = recipeName })
    end

    cancelActiveCraft = doCancel
    WatchEscCancel(function() return finished end, doCancel)

    QBCore.Functions.Progressbar('craft_item_' .. recipeName, 'جاري تصنيع: ' .. recipe.label .. ' x' .. amount, craftTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'mini@repair',
        anim = 'fixing_a_ped',
        flags = 16,
    }, {}, {}, function() -- Done
        if finished then return end
        finished = true
        cancelActiveCraft = nil
        ClearPedTasks(ped)
        QBCore.Functions.TriggerCallback('scrap-crafting:server:craftItem', function(success, message)
            isBusy = false
            QBCore.Functions.TriggerCallback('scrap-crafting:server:getCounts', function(result)
                SendNUIMessage({
                    action = 'craftResult',
                    success = success,
                    message = message,
                    item = recipeName,
                    counts = result.counts,
                    level = result.level,
                })
            end)
        end, recipeName, amount)
    end, doCancel) -- Cancel (نفس دالة الإلغاء اللي يستخدمها ESC وزر الواجهة)

    cb('ok')
end)

CreateThread(function()
    while true do
        if craftMenuOpen then
            if IsControlJustPressed(0, 200) then -- ESC
                craftMenuOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'close' })
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

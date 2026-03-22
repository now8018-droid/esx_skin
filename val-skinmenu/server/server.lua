ESX = nil
local callbacksRegistered = false
local callbackPrefix = scriptName or GetCurrentResourceName()
local registeredUsableItems = {}

CreateThread(function()
    while ESX == nil do
        TriggerEvent(Config["Router"], function(obj)
            ESX = obj
        end)
        Wait(200)
    end
end)

local function getPlayerFromSource(source)
    if source == nil then
        return nil
    end

    return ESX.GetPlayerFromId(source)
end

local function getPrice(skinIndex, priceType)
    if not skinIndex or not priceType then
        return nil
    end

    local shop = Config["SkinPosition"][skinIndex]
    if not shop or not shop.Price then
        return nil
    end

    local price = shop.Price[priceType]
    if type(price) ~= "number" then
        return nil
    end

    if price < 0 then
        return nil
    end

    return math.floor(price)
end

local function hasEnoughMoney(xPlayer, amount)
    return xPlayer.getMoney() >= amount
end

local function isValidMenuType(menuType)
    return type(menuType) == "string" and Config["SkinPosition"] and Config["SkinPosition"][menuType] ~= nil
end

local function openMenuForPlayer(playerId, menuType)
    if not playerId or not isValidMenuType(menuType) then
        return false
    end

    TriggerClientEvent(callbackPrefix .. ':OpenMenuByType', playerId, menuType)
    return true
end

local function registerUsableItems()
    if not ESX or type(ESX.RegisterUsableItem) ~= "function" then
        return
    end

    local itemsConfig = Config["Items"]
    if type(itemsConfig) ~= "table" or not itemsConfig.enabled then
        return
    end

    for _, itemData in pairs(itemsConfig) do
        if type(itemData) == "table" then
            local itemName = itemData.name
            local menuType = itemData.menu or "SURGERY"

            if type(itemName) == "string" and itemName ~= "" and not registeredUsableItems[itemName] and isValidMenuType(menuType) then
                registeredUsableItems[itemName] = true

                ESX.RegisterUsableItem(itemName, function(source)
                    local xPlayer = getPlayerFromSource(source)
                    if not xPlayer then
                        return
                    end

                    if itemData.consume then
                        xPlayer.removeInventoryItem(itemName, 1)
                    end

                    openMenuForPlayer(source, menuType)
                end)
            end
        end
    end
end

local function registerHandlers()
    if callbacksRegistered or ESX == nil then
        return
    end

    callbacksRegistered = true

    ESX.RegisterServerCallback(callbackPrefix .. '::CheckMoneyBuy', function(source, cb, skinIndex)
        local xPlayer = getPlayerFromSource(source)
        if not xPlayer then
            cb(false)
            return
        end

        local price = getPrice(skinIndex, "BuyPrice")
        if not price then
            cb(false)
            return
        end

        cb(hasEnoughMoney(xPlayer, price))
    end)

    ESX.RegisterServerCallback(callbackPrefix .. '::CheckMoneyAddFavorite', function(source, cb, skinIndex)
        local xPlayer = getPlayerFromSource(source)
        if not xPlayer then
            cb(false)
            return
        end

        local price = getPrice(skinIndex, "AddFavorite")
        if not price then
            cb(false)
            return
        end

        cb(hasEnoughMoney(xPlayer, price))
    end)

    RegisterNetEvent(callbackPrefix .. ':RemoveMoney')
    AddEventHandler(callbackPrefix .. ':RemoveMoney', function(skinIndex, priceType)
        local source = source
        local xPlayer = getPlayerFromSource(source)
        if not xPlayer then
            return
        end

        local price = getPrice(skinIndex, priceType)
        if not price or price <= 0 then
            return
        end

        if not hasEnoughMoney(xPlayer, price) then
            return
        end

        xPlayer.removeMoney(price)
    end)

    RegisterNetEvent(callbackPrefix .. ':OpenMenuByType')
    AddEventHandler(callbackPrefix .. ':OpenMenuByType', function(menuType)
        local playerId = source

        if not isValidMenuType(menuType) then
            return
        end

        openMenuForPlayer(playerId, menuType)
    end)

    registerUsableItems()
end

CreateThread(function()
    while ESX == nil do
        Wait(200)
    end

    registerHandlers()
end)

local function GetPlayerFromSource(playerSource)
    if ESX.Player then
        return ESX.Player(playerSource)
    end

    if ESX.GetPlayerFromId then
        return ESX.GetPlayerFromId(playerSource)
    end

    return nil
end

local function SetPlayerMaxWeight(xPlayer, weight)
    if xPlayer.setMaxWeight then
        xPlayer.setMaxWeight(weight)
        return
    end

    if xPlayer.set and type(xPlayer.set) == "function" then
        xPlayer.set("maxWeight", weight)
    end
end

local function GetBackpackWeightModifier(skin)
    if not skin or type(skin) ~= "table" then
        return nil
    end

    return Config.BackpackWeight[skin.bags_1]
end

RegisterNetEvent("esx_skin:save", function(skin)
    if not skin or type(skin) ~= "table" then
        return
    end

    local xPlayer = GetPlayerFromSource(source)

    if not xPlayer then
        return
    end

    if not ESX.GetConfig().CustomInventory then
        local defaultMaxWeight = ESX.GetConfig().MaxWeight
        local backpackModifier = GetBackpackWeightModifier(skin)

        if backpackModifier then
            SetPlayerMaxWeight(xPlayer, defaultMaxWeight + backpackModifier)
        else
            SetPlayerMaxWeight(xPlayer, defaultMaxWeight)
        end
    end

    MySQL.update("UPDATE users SET skin = @skin WHERE identifier = @identifier", {
        ["@skin"] = json.encode(skin),
        ["@identifier"] = xPlayer.getIdentifier(),
    })
end)

RegisterNetEvent("esx_skin:setWeight", function(skin)
    local xPlayer = GetPlayerFromSource(source)

    if not xPlayer then
        return
    end

    if not ESX.GetConfig().CustomInventory then
        local defaultMaxWeight = ESX.GetConfig().MaxWeight
        local backpackModifier = GetBackpackWeightModifier(skin)

        if backpackModifier then
            SetPlayerMaxWeight(xPlayer, defaultMaxWeight + backpackModifier)
        else
            SetPlayerMaxWeight(xPlayer, defaultMaxWeight)
        end
    end
end)

ESX.RegisterServerCallback("esx_skin:getPlayerSkin", function(source, cb)
    local xPlayer = GetPlayerFromSource(source)

    if not xPlayer then
        cb(nil, nil)
        return
    end

    MySQL.query("SELECT skin FROM users WHERE identifier = @identifier", {
        ["@identifier"] = xPlayer.getIdentifier(),
    }, function(users)
        local user, skin = users[1], nil

        local jobSkin = {
            skin_male = xPlayer.getJob().skin_male,
            skin_female = xPlayer.getJob().skin_female,
        }

        if user.skin then
            skin = json.decode(user.skin)
        end

        cb(skin, jobSkin)
    end)
end)

local function IsAdmin(xPlayer)
    if not xPlayer or type(xPlayer.getGroup) ~= "function" then
        return false
    end

    local group = xPlayer.getGroup()
    return group == "admin" or group == "superadmin"
end

RegisterCommand("skin", function(source, args)
    local xPlayer = GetPlayerFromSource(source)

    if not xPlayer then
        return
    end

    local targetId = tonumber(args[1]) or source
    if targetId ~= source and not IsAdmin(xPlayer) then
        targetId = source
    end

    local targetPlayer = GetPlayerFromSource(targetId)
    if not targetPlayer then
        targetPlayer = xPlayer
    end

    targetPlayer.triggerEvent("val-skinmenu:OpenMenuByType", "SURGERY")
end, false)

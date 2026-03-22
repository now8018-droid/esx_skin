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

local function NotifyPlayer(xPlayer, message)
    if xPlayer and type(xPlayer.showNotification) == "function" then
        xPlayer.showNotification(message)
    end
end

local function OpenSkinMenuForPlayer(playerSource)
    if type(playerSource) ~= "number" or playerSource <= 0 then
        return false
    end

    if GetResourceState("val-skinmenu") == "started" then
        TriggerClientEvent("val-skinmenu:OpenMenuByType", playerSource, "SURGERY")
        return true
    end

    if GetResourceState("skinchanger") == "started" then
        TriggerClientEvent("esx_skin:openSaveableMenu", playerSource)
        return true
    end

    return false
end

RegisterCommand("skin", function(source, args)
    if source == 0 then
        local targetId = tonumber(args[1])

        if not targetId then
            print("[esx_skin] Usage from console: skin <playerId>")
            return
        end

        if not OpenSkinMenuForPlayer(targetId) then
            print("[esx_skin] Unable to open the skin menu because no compatible skin menu resource is started.")
        end

        return
    end

    local xPlayer = GetPlayerFromSource(source)

    if not xPlayer then
        return
    end

    local targetId = tonumber(args[1]) or source
    if targetId ~= source and not IsAdmin(xPlayer) then
        targetId = source
    end

    local targetPlayer = GetPlayerFromSource(targetId) or xPlayer

    if not OpenSkinMenuForPlayer(targetPlayer.source or source) then
        NotifyPlayer(xPlayer, "Skin menu resource is not available right now.")
    end
end, false)

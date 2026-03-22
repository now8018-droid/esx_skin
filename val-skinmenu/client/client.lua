Keys 					  = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX			    		= nil
local ScriptEntity		= {}
local Accessories		= {}

local skinMenuTextUiState = {
	isOpen = false,
	key = nil,
	text = nil
}
local ACCESSORIES_KVP_KEY = "Set_Accessories_32"
local TEXTURE_OVERRIDES = {
	['arms_2'] = 'arms',
	['hair_color_2'] = 'hair_color_1',
	['hair_2'] = 'hair_1',
	['bodyb_2'] = 'bodyb_1',
	['blemishes_2'] = 'blemishes_1',
	['age_2'] = 'age_1',
	['complexion_2'] = 'complexion_1',
	['sun_2'] = 'sun_1',
	['moles_2'] = 'moles_1',
	['eyebrows_2'] = 'eyebrows_1',
	['eyebrows_4'] = 'eyebrows_3',
	['eyebrows_6'] = 'eyebrows_5',
	['makeup_2'] = 'makeup_1',
	['makeup_4'] = 'makeup_3',
	['lipstick_2'] = 'lipstick_1',
	['lipstick_4'] = 'lipstick_3',
	['chest_3'] = 'chest_2',
	['blush_2'] = 'blush_1',
	['beard_2'] = 'beard_1',
	['beard_4'] = 'beard_3',
}

local hideOtherPlayers = false
local activeNearbyFx = nil
local activeSkinMenuZone = nil
local skinMenuZones = {}
local favoriteMenuZones = {}
local skinPositionByName = {}
local PlayerPedCache = PlayerPedId()
local resourceConfig = Config.ExportResources or {}
local textUIResource = resourceConfig.textUI or ''
local inventoryResource = resourceConfig.inventory or ''
local notifyResource = resourceConfig.notify or ''
local carHUDResource = resourceConfig.carHUD or ''
local playerHUDResource = resourceConfig.playerHUD or ''

local function isStartedResource(resourceName)
	return type(resourceName) == "string" and resourceName ~= "" and GetResourceState(resourceName) == "started"
end

local function notifySetRight(state)
	if isStartedResource(notifyResource) then
		TriggerEvent(("%s:setright"):format(notifyResource), "skinmenu", state)
	end
end

local function setScreenUI(state)
	if isStartedResource(playerHUDResource) then
		TriggerEvent(("%s:screenui"):format(playerHUDResource), state)
	end
end

local function setCarHUDVisible(hidden)
	if isStartedResource(carHUDResource) then
		exports[carHUDResource]:hidefast(hidden)
	end
end

local function setMenuNuiFocus(state)
	SetNuiFocus(state, state)
	SetNuiFocusKeepInput(false)
end

local function disableSkinMenuControls()
	local controls = {
		1, 2, 24, 25, 30, 31, 32, 33, 34, 35, 36, 37, 44, 45, 68, 69, 70, 71, 72, 73, 75, 91, 92,
		106, 114, 140, 141, 142, 143, 257, 263, 264, 331
	}

	for i = 1, #controls do
		DisableControlAction(0, controls[i], true)
	end
end

local function isPlayerUnavailableForSkinMenu(ped)
	local playerPed = ped or PlayerPedId()
	return IsEntityDead(playerPed) or IsPedDeadOrDying(playerPed, true)
end

local function getPlayerPedCached()
	if not DoesEntityExist(PlayerPedCache) then
		PlayerPedCache = PlayerPedId()
	end

	return PlayerPedCache
end

local function getDistanceSquared(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	local dz = a.z - b.z

	return (dx * dx) + (dy * dy) + (dz * dz)
end

local function buildMenuZones()
	skinMenuZones = {}
	favoriteMenuZones = {}
	skinPositionByName = {}

	for name, zone in pairs(Config["SkinPosition"]) do
		skinPositionByName[name] = zone

		for positionIndex = 1, #(zone.Position or {}) do
			local position = zone.Position[positionIndex]
			skinMenuZones[#skinMenuZones + 1] = {
				name = name,
				config = zone,
				coords = position.coords,
				size = position.size or 1.0,
				sizeSq = (position.size or 1.0) * (position.size or 1.0),
				heading = position.heading,
				blip = position.blip,
			}
		end
	end

	local favoriteConfig = Config["FavoritePosition"]
	for positionIndex = 1, #(favoriteConfig.Position or {}) do
		local position = favoriteConfig.Position[positionIndex]
		favoriteMenuZones[#favoriteMenuZones + 1] = {
			config = favoriteConfig,
			coords = position.coords,
			size = position.size or 1.0,
			sizeSq = (position.size or 1.0) * (position.size or 1.0),
			heading = position.heading,
		}
	end
end

local function openMenuFromZone(menuType, zoneData, menuMode)
	local playerPed = getPlayerPedCached()

	TriggerEvent("skinchanger:getSkin", function(skin)
		MenuType = menuMode or "Normal"
		LastSkin = skin
		SkinIndex = menuType
		activeSkinMenuZone = zoneData and {
			coords = zoneData.coords,
			size = zoneData.size
		} or nil

		if zoneData and zoneData.heading then
			SetEntityHeading(playerPed, zoneData.heading)
		end

		ClearPedTasks(playerPed)
		ToggleSkinMenu(true)
	end)
end

local function loadAccessoriesFromStorage()
	local rawAccessories = GetResourceKvpString(ACCESSORIES_KVP_KEY)
	if not rawAccessories or rawAccessories == "" then
		return {}
	end

	local decodedAccessories = json.decode(rawAccessories)
	if type(decodedAccessories) ~= "table" then
		return {}
	end

	return decodedAccessories
end

local function saveAccessoriesToStorage()
	SetResourceKvp(ACCESSORIES_KVP_KEY, json.encode(Accessories))
end

local function setOtherPlayersVisible(status)
	local visible = status == true
	for _, player in ipairs(GetActivePlayers()) do
		if player ~= PlayerId() then
			local ped = GetPlayerPed(player)
			if ped and ped ~= 0 and ped ~= PlayerPedId() then
				SetEntityVisible(ped, visible)
			end
		end
	end
end

local function showSkinMenuTextUI(keyText, text)
	local safeKey = tostring(keyText or 'E')
	local safeText = tostring(text or '')

	if safeText == '' then
		return
	end

	if skinMenuTextUiState.isOpen and skinMenuTextUiState.key == safeKey and skinMenuTextUiState.text == safeText then
		return
	end

	if isStartedResource(textUIResource) then
		exports[textUIResource]:open({
			key = safeKey,
			text = safeText
		})
	end

	skinMenuTextUiState.isOpen = true
	skinMenuTextUiState.key = safeKey
	skinMenuTextUiState.text = safeText
end

local function hideSkinMenuTextUI()
	if not skinMenuTextUiState.isOpen then
		return
	end

	if isStartedResource(textUIResource) then
		exports[textUIResource]:close()
	end
	skinMenuTextUiState.isOpen = false
	skinMenuTextUiState.key = nil
	skinMenuTextUiState.text = nil
end

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent(Config["Router"], function(obj) ESX = obj end)
		Citizen.Wait(200)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
    ESX.PlayerData = ESX.GetPlayerData()
	buildMenuZones()
    ScriptWork()

	Citizen.Wait(5000)
	Accessories = loadAccessoriesFromStorage()
	UpdateAccessories()
end)

function ScriptWork()

	print("^7 [^4Scripts^7][^2"..string.upper(GetCurrentResourceName()).."^7][^4Loaded Success^7]")

    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
			for k,v in pairs(ScriptEntity) do
				DeleteEntity(v)
			end
			ToggleSkinMenu(false)
        end
    end)

    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        ESX.PlayerData = xPlayer
    end)

    RegisterNetEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(job)
        ESX.PlayerData.job = job
    end)

	RegisterNetEvent(scriptName .. ':OpenMenuByType')
	AddEventHandler(scriptName .. ':OpenMenuByType', function(menuType)
		if ToggleMenu then
			return
		end

		if isPlayerUnavailableForSkinMenu(getPlayerPedCached()) then
			Config["Notify"]("คุณเสียชีวิตอยู่ ไม่สามารถเปิดเมนูแต่งตัวได้", "error")
			return
		end

		if not skinPositionByName[menuType] then
			return
		end

		openMenuFromZone(menuType, nil, "Normal")
	end)

	RegisterNetEvent('val-skinmenu:DeleteAccessories')
    AddEventHandler('val-skinmenu:DeleteAccessories', function(index)
        if Accessories[index] then

			Accessories[index] = nil

			local NewTable = {}
			for k,v in pairs(Accessories) do
				table.insert(NewTable, Accessories[k])
			end
			Accessories = NewTable
			saveAccessoriesToStorage()
			UpdateAccessories()

		end
    end)

	function UpdateAccessories()
		if isStartedResource(inventoryResource) then
			exports[inventoryResource]:SetAccessory(Accessories)
		end
	end

	RegisterCommand("clearaccessories", function()
		Accessories = {}
		saveAccessoriesToStorage()
		UpdateAccessories()
	end)

	local ListIndex = {

		['sex'] = 1,['face'] = 2,['skin'] = 3,
		['hair_1'] = 4,['hair_color_1'] = 5,
		['torso_1'] = 6,['tshirt_1'] = 7,['decals_1'] = 8,
		['arms'] = 9,['pants_1'] = 10,['shoes_1'] = 11,['mask_1'] = 12,
		['bproof_1'] = 13,['chain_1'] = 14,['helmet_1'] = 15,['glasses_1'] = 16,
		['watches_1'] = 17,['bracelets_1'] = 18,['bags_1'] = 19,['ears_1'] = 20,
		['bodyb_1'] = 21,['blemishes_1'] = 22,['age_1'] = 23,['complexion_1'] = 24,
		['sun_1'] = 25,['moles_1'] = 26,['eye_squint'] = 27,['eye_color'] = 28,['eyebrows_1'] = 29,
		['eyebrows_3'] = 30,['eyebrows_5'] = 31,['makeup_1'] = 32,['makeup_3'] = 33,['lipstick_1'] = 34,
		['lipstick_3'] = 35,['chest_1'] = 36,['blush_1'] = 37,['blush_3'] = 38,['beard_1'] = 39,['beard_3'] = 40,
        ['nose_1'] = 41 , ['nose_2'] = 42 , ['nose_3'] = 43 , ['nose_4'] = 44 , ['nose_5'] = 45 , ['nose_6'] = 46, 
        ['cheeks_1'] = 47 , ['cheeks_2'] = 48 , ['cheeks_3'] = 49,
        ['lip_thickness'] = 50 , ['jaw_1'] = 51 , ['jaw_2'] = 52,
        ['chin_1'] = 53 , ['chin_2'] = 54 , ['chin_3'] = 55 , ['chin_4'] = 56 , ['neck_thickness'] = 57,
	}

	local ListCheck = {
        ['sex'] = {
            ["name"] = "sex",
        }, 
		['face'] = {
            ["name"] = "face",
        },
        ['skin'] = {
            ["name"] = "skin",
        },  
        ['hair'] = {
            ["name"] = "hair_1",
        },  
        ['hair_color'] = {
            ["name"] = "hair_color_1",
        }, 
        ['torso'] = {
            ["name"] = "torso_1",
        },  
        ['tshirt'] = {
            ["name"] = "tshirt_1",
        }, 
        ['decals'] = {
            ["name"] = "decals_1",
        },  
        ['arms'] = {
            ["name"] = "arms",
        }, 
        ['pants'] = {
            ["name"] = "pants_1",
        },  
        ['shoes'] = {
            ["name"] = "shoes_1",
        }, 
        ['mask'] = {
            ["name"] = "mask_1",
        },  
        ['bproof'] = {
            ["name"] = "bproof_1",
        }, 
        ['chain'] = {
            ["name"] = "chain_1",
        },  
        ['helmet'] = {
            ["name"] = "helmet_1",
        }, 
        ['glasses'] = {
            ["name"] = "glasses_1",
        },  
        ['watches'] = {
            ["name"] = "watches_1",
        }, 
        ['bracelets'] = {
            ["name"] = "bracelets_1",
        },  
        ['bags'] = {
            ["name"] = "bags_1",
        }, 
        ['ears'] = {
            ["name"] = "ears_1",
        },  
        ['bodyb'] = {
            ["name"] = "bodyb_1",
        }, 
        ['blemishes'] = {
            ["name"] = "blemishes_1",
        },  
        ['age'] = {
            ["name"] = "age_1",
        }, 
        ['complexion'] = {
            ["name"] = "complexion_1",
        },  
        ['sun'] = {
            ["name"] = "sun_1",
        }, 
        ['moles'] = {
            ["name"] = "moles_1",
        },  
		['eye_squint'] = {
            ["name"] = "eye_squint",
        }, 
        ['eye_color'] = {
            ["name"] = "eye_color",
        }, 
        ['eyebrows_1'] = {
            ["name"] = "eyebrows_1",
        },  
        ['eyebrows_3'] = {
            ["name"] = "eyebrows_3",
        }, 
		['eyebrows_5'] = {
            ["name"] = "eyebrows_5",
        }, 
        ['makeup_1'] = {
            ["name"] = "makeup_1",
        },  
        ['makeup_3'] = {
            ["name"] = "makeup_3",
        }, 
        ['lipstick_1'] = {
            ["name"] = "lipstick_1",
        },  
        ['lipstick_3'] = {
            ["name"] = "lipstick_3",
        }, 
        ['chest'] = {
            ["name"] = "chest_1",
        },  
        ['blush'] = {
            ["name"] = "blush_1",
        }, 
        ['blush_2'] = {
            ["name"] = "blush_3",
        }, 
        ['beard_1'] = {
            ["name"] = "beard_1",
        },  
        ['beard_3'] = {
            ["name"] = "beard_3",
        },
        ['nose_1'] = {
            ["name"] = "nose_1",
        },
        ['nose_2'] = {
            ["name"] = "nose_2",
        },
        ['nose_3'] = {
            ["name"] = "nose_3",
        },
        ['nose_4'] = {
            ["name"] = "nose_4",
        },
        ['nose_5'] = {
            ["name"] = "nose_5",
        },
        ['nose_6'] = {
            ["name"] = "nose_6",
        },
        ['cheeks_1'] = {
            ["name"] = "cheeks_1",
        },
        ['cheeks_2'] = {
            ["name"] = "cheeks_2",
        },
        ['cheeks_3'] = {
            ["name"] = "cheeks_3",
        },
        ['lip_thickness'] = {
            ["name"] = "lip_thickness",
        },
        ['jaw_1'] = {
            ["name"] = "jaw_1",
        },
        ['jaw_2'] = {
            ["name"] = "jaw_2",
        },
        ['chin_1'] = {
            ["name"] = "chin_1",
        },
        ['chin_2'] = {
            ["name"] = "chin_2",
        },
        ['chin_3'] = {
            ["name"] = "chin_3",
        },
        ['chin_4'] = {
            ["name"] = "chin_4",
        },
        ['neck_thickness'] = {
            ["name"] = "neck_thickness",
        },
    }

	function GetSkinData(restrict)

		local elements, lits_setup, accept_data = {}, {}, {}
		local loadedSkinData = false
		local playerPed = getPlayerPedCached()

		TriggerEvent("skinchanger:getData", function(components, maxVals)
            while maxVals == nil do Wait(300) end

			for i = 1, #components do
				local component = components[i]
				local componentId = component.componentId
				local value = component.value

				if componentId == 0 then
					value = GetPedPropIndex(playerPed, componentId)
				end

				elements[#elements + 1] = {
					label = component.label,
					name = component.name,
					value = value,
					min = component.min,
					max = maxVals[component.name],
					textureof = TEXTURE_OVERRIDES[component.name] or component.textureof,
				}
			end

			for i = 1, #elements do
				local data = elements[i]
				local setupIndex = data.textureof and ListIndex[data.textureof] or ListIndex[data.name]

				if setupIndex then
					local bucket = lits_setup[setupIndex] or {}
					lits_setup[setupIndex] = bucket
					bucket[data.textureof and 'item2' or 'item1'] = {
						name = data.name,
						label = data.label,
						minvalue = data.min,
						maxvalue = data.max,
						value = data.value,
					}
				end
			end

			if restrict then
				local check_index = {}
				for _, setup in pairs(lits_setup) do
					if setup.item1 then
						for restrictKey, enabled in pairs(restrict) do
							if enabled and ListCheck[restrictKey] then
								local name_real = ListCheck[restrictKey]["name"]
								if name_real and name_real == setup.item1.name and not check_index[name_real] then
									check_index[name_real] = true
									accept_data[#accept_data + 1] = setup
								end
							end
						end
					end
				end
			else
				accept_data = lits_setup
			end

			loadedSkinData = true
		end)

		local timeoutAt = GetGameTimer() + 2000
		while not loadedSkinData and GetGameTimer() < timeoutAt do
			Citizen.Wait(10)
		end

		return accept_data or {}
	end	

	-- Citizen.CreateThread(function()
	-- 	-- GetSkinData(Config["Costume"]["default"])
	-- 	Citizen.Wait(1000)
	-- 	ToggleSkinMenu(true)
	-- end)

	-- RegisterCommand("forceskin", function()
	-- 	TriggerEvent("skinchanger:getSkin", function(skin)
	-- 		LastSkin = skin
	-- 		SkinIndex = "default"	
	-- 		ToggleSkinMenu(true)
	-- 	end)
	-- end)

	function ForceSkinMenu(index)
		TriggerEvent("skinchanger:getSkin", function(skin)
			LastSkin = skin
			SkinIndex = index	
			ToggleSkinMenu(true)
		end)
	end

	function ToggleSkinMenu(status)
		UI_TYPE = "MENU"
		local CustumeList = nil
		local CFG = Config["SkinPosition"][SkinIndex]
		if status and isPlayerUnavailableForSkinMenu(PlayerPedId()) then
			hideSkinMenuTextUI()
			Config["Notify"]("คุณเสียชีวิตอยู่ ไม่สามารถเปิดเมนูแต่งตัวได้", "error")
			return
		end
		if status then
			hideOtherPlayers = false
			setOtherPlayersVisible(true)
			hideSkinMenuTextUI()
			CustumeList = GetSkinData(Config["Costume"][CFG.CustumeType])
			FreezeEntityPosition(PlayerPedId(), true)
			notifySetRight(31)
			setCarHUDVisible(true)
			setScreenUI(true)
		else
			hideOtherPlayers = false
			setOtherPlayersVisible(true)
			activeSkinMenuZone = nil
			SkinIndex = nil
			lastcampos = nil
			FreezeEntityPosition(PlayerPedId(), false)
			notifySetRight(false)
			DeleteCam()
			for k,v in pairs(ScriptEntity) do DeleteEntity(v) end
			setCarHUDVisible(false)
			setScreenUI(false)
		end
		ToggleMenu = status
		setMenuNuiFocus(ToggleMenu)
		ClearPedTasks(PlayerPedId())
		-- SendNUIMessage({
		-- 	type = 'ToggleSkinMenu',
		-- 	status = ToggleMenu,
		-- 	skin_list = CustumeList,
		-- 	CFG = CFG
		-- })
        SendNUIMessage({
            action = 'ToggleSkinMenu',
            data = {
                status = ToggleMenu,
                skin_list = CustumeList,
                CFG = CFG
            }
        })
	end

	RegisterNUICallback('valuechangeskin', function(data, cb)
		-- print(ESX.DumpTable(data))
		if data.data.item1.name == "sex" then
			if data.data.item1.value >= 2 then
				if ESX.PlayerData and Config["Admin"][ESX.PlayerData.identifier] then

				else
					data.data.item1.value = 1
				end
			end
		end
		if data.data and data.index then
			if data.update == false then
				for _, v in pairs(data.data) do
					if v and v.name ~= nil and v.value ~= nil then
						TriggerEvent("skinchanger:change", v.name, v.value)
					end
				end

				cb("ok")
				return
			end

			TriggerEvent("skinchanger:getData", function(_, maxVals)
				local update = false
				for _, v in pairs(data.data) do
					local maxValue = maxVals[v.name]
					if maxValue ~= nil then
						v.maxvalue = maxValue
						if v.value > v.maxvalue then
							v.value = v.maxvalue
						end
						TriggerEvent("skinchanger:change", v.name , v.value)
						update = true
					end
				end
				if update then
					-- SendNUIMessage({
					-- 	type = 'UpdateMaxValue',
					-- 	data = data.data,
					-- 	index = data.index
					-- })
                    SendNUIMessage({
                        action = 'UpdateMaxValue',
                        data = {
                            data = data.data,
                            index = data.index
                        }
                    })
				end
			end)
		end
        cb("ok")
    end)

	RegisterNUICallback('print', function(data, cb)
        --print(ESX.DumpTable(data.text))
    end)

	RegisterNUICallback('exit', function(data, cb)
		if UI_TYPE == "MENU" then
			ToggleSkinMenu(false)
		elseif UI_TYPE == "FAVORITE" then
			ToggleFavorite(false)
		end
		TriggerEvent('skinchanger:loadSkin', LastSkin)

		ESX.Streaming.RequestAnimDict("clothingshirt", function()
			TaskPlayAnim(PlayerPedId(), "clothingshirt", "try_shirt_positive_d", 1.0, -1, -1, 49, 0, 0, 0, 0, false, false, false)
		end)
		Citizen.Wait(5000)
		ClearPedTasks(PlayerPedId())
        cb("ok")
    end)

	RegisterNUICallback('buy', function(data, cb)
		if not Waiting then
			Waiting = true
			if UI_TYPE == "MENU" then
				ESX.TriggerServerCallback(scriptName..'::CheckMoneyBuy',function(success)
					if success then
						TriggerEvent("skinchanger:getSkin", function(skin)
							--print(ESX.DumpTable(skin))
							local noblock = true
							for k,v in pairs(skin) do
								if Config["BlackList"][skin["sex"]] and Config["BlackList"][skin["sex"]][k] and Config["BlackList"][skin["sex"]][k][v] then
									noblock = false
								end
							end
							if noblock then
								TriggerServerEvent("esx_skin:save", skin)
								TriggerServerEvent(scriptName..':RemoveMoney', SkinIndex, "BuyPrice")

								if SkinIndex then
									if Config["SkinPosition"][SkinIndex].Accessories then

										TriggerEvent("skinchanger:getData", function(components)
											local accessoryConfig = Config["SkinPosition"][SkinIndex].Accessories
											local save_accessories = {}
											local label = "Accessories"
											for _, component in pairs(components) do
												if accessoryConfig.label == component.name then
													label = component.label
												end
											end
											for componentName in pairs(accessoryConfig.skin or {}) do
												if skin[componentName] ~= nil then
													save_accessories[componentName] = skin[componentName]
												end
											end
											table.insert(Accessories, {
												label = label,
												name = accessoryConfig.label,
												skin = save_accessories,
												anime = accessoryConfig.anime,
												default = accessoryConfig.default
											})
											saveAccessoriesToStorage()
											UpdateAccessories()
										end)

									end
								end

								ToggleSkinMenu(false)
							else
								Config["Notify"]("มีชุดบางรายการระบบไม่อนุญาตให้สวมใส่", "error")
							end
						end)
					else
						Config["Notify"]("คุณมีเงินไม่เพียงพอ "..Config["SkinPosition"][SkinIndex].Price.BuyPrice.." ", "error")
					end
				end, SkinIndex)
			elseif UI_TYPE == "FAVORITE" then
				TriggerEvent("skinchanger:getSkin", function(skin)
					TriggerServerEvent("esx_skin:save", skin)
				end)
				ToggleFavorite(false)
			end
			Citizen.Wait(1000)
			Waiting = false
		else
			Config["Notify"]("รอสักครู่", "error")
		end
		cb("ok")
    end)

	RegisterNUICallback('loadfavorite', function(data, cb)
		favoritelist = data.data
		SendNUIMessage({action = 'refreshfavorite', data = favoritelist})
        cb("ok")
    end)

	RegisterNUICallback('addfavorite', function(data, cb)
		if not Waiting then
			Waiting = true
			if Config["SkinPosition"][SkinIndex].Price.AddFavorite then
				if #data.name > 0 and SkinIndex then
					if not favoritelist[data.name] then
						local favorite = 0
						for k,v in pairs(favoritelist) do
							favorite = favorite + 1
						end
						if favorite < 11 then
							TriggerEvent("skinchanger:getSkin", function(skin)
								local noblock = true
								for k,v in pairs(skin) do
									if Config["BlackList"][skin["sex"]] and Config["BlackList"][skin["sex"]][k] and Config["BlackList"][skin["sex"]][k][v] then
										noblock = false
									end
								end
								if noblock then
									ESX.TriggerServerCallback(scriptName..'::CheckMoneyAddFavorite',function(success)
										if success then
											TriggerEvent("skinchanger:getSkin", function(skin)
												local CFG = Config["SkinPosition"][SkinIndex]
												local custumelist = GetSkinData(Config["Costume"][CFG.CustumeType])
												local savelist = {}
												for k,v in pairs(custumelist) do
													if v.item1 then
														if skin[v.item1.name] then
															savelist[v.item1.name] = skin[v.item1.name]
														end
													end
													if v.item2 then
														if skin[v.item2.name] then
															savelist[v.item2.name] = skin[v.item2.name]
														end
													end
												end
												favoritelist[data.name] = savelist
												SendNUIMessage({action = 'savefavoritelist', data = favoritelist})
												TriggerServerEvent(scriptName..':RemoveMoney', SkinIndex, "AddFavorite")
												Config["Notify"]("บันทึกชุดของคุณ เรียบร้อยแล้ว", "success")
											end)
										else
											Config["Notify"]("คุณมีเงินไม่เพียงพอ "..Config["SkinPosition"][SkinIndex].Price.AddFavorite.." ", "error")
										end
									end, SkinIndex)
								else
									Config["Notify"]("มีชุดบางรายการระบบไม่อนุญาตให้สวมใส่", "error")
								end
							end)
						else
							Config["Notify"]("ไม่สามารถบันทึกได้ เนื่องจากชุดที่คุณบันทึกไว้เกิน 11 ชุดแล้ว", "error")
						end
					else
						Config["Notify"]("ตรวจสอบเจอชื่อซ้ำกับชุดเดิมของคุณ", "error")
					end
				else
					Config["Notify"]("กรุณาระบุชื่อชุดของคุณ", "error")
				end
			else
				Config["Notify"]("ระบบไม่อนุญาตให้เพิ่มรายชื่อ", "error")
			end
			Citizen.Wait(1000)
			Waiting = false
		else
			Config["Notify"]("รอสักครู่", "error")
		end
		cb("ok")
    end)

	RegisterNUICallback('daletefavorite', function(data, cb)
		if Config["SkinPosition"][SkinIndex].Price.AddFavorite then
			favoritelist[data.name] = nil
			--SendNUIMessage({type = 'savefavoritelist', data = favoritelist})
            SendNUIMessage({
                action = 'savefavoritelist',
                data = favoritelist
            })
			Config["Notify"]("ลบชุดของคุณ เรียบร้อยแล้ว", "error")
		end
        cb("ok")
    end)

	RegisterNUICallback('loadskinfavorite', function(data, cb)
		local success = false
		if MenuType == "Normal" then
			if Config["SkinPosition"][SkinIndex].Price.AddFavorite then
				success = true
			end
		elseif MenuType == "Favorite" then
			success = true
		end
		if success then
			if favoritelist[data.name] then
				for k,v in pairs(favoritelist[data.name]) do
					TriggerEvent("skinchanger:change", k , v)
				end
				TriggerEvent("skinchanger:getSkin", function(skin)
					TriggerServerEvent("esx_skin:save", skin)
				end)
				Config["Notify"]("ใส่ชุด "..data.name.." แล้ว", "success")
			end
		else
			Config["Notify"]("ไม่อนุญาต", "error")
		end
        cb("ok")
    end)

	Citizen.CreateThread(function()
		for k,v in pairs(Config["SkinPosition"]) do
			if v.Blip then
				if v.Blip.enabled then
					for _, i in pairs(v.Position) do
						if i.blip then
							local Blip = AddBlipForCoord(i.coords)
							SetBlipHighDetail(Blip, true)
							SetBlipSprite(Blip, v.Blip.sprite)
							SetBlipScale(Blip, v.Blip.scale)
							SetBlipColour(Blip, v.Blip.color)
							SetBlipAsShortRange(Blip, true)
							SetBlipAsMissionCreatorBlip(Blip, true)
							BeginTextCommandSetBlipName("STRING")
							AddTextComponentString(v.Blip.text)
							EndTextCommandSetBlipName(Blip)
						end
					end
				end
			end
		end
		for _, i in pairs(Config["FavoritePosition"].Position) do
			local v = Config["FavoritePosition"]
			if v.Blip and v.Blip.enabled then
				local Blip = AddBlipForCoord(i.coords)
				SetBlipHighDetail(Blip, true)
				SetBlipSprite(Blip, v.Blip.sprite)
				SetBlipScale(Blip, v.Blip.scale)
				SetBlipColour(Blip, v.Blip.color)
				SetBlipAsShortRange(Blip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(v.Blip.text)
				EndTextCommandSetBlipName(Blip)
			end
		end
	end)

	Citizen.CreateThread(function()
        while true do
            local sleep = 1500

			if not ToggleMenu then
				local playerPed = getPlayerPedCached()
				if isPlayerUnavailableForSkinMenu(playerPed) then
					hideSkinMenuTextUI()
				else
					local coords = GetEntityCoords(playerPed)
					local shouldShowTextUI = false
					local openedMenu = false

					for i = 1, #skinMenuZones do
						local zone = skinMenuZones[i]
						local cfg = zone.config
						local distanceSq = getDistanceSquared(coords, zone.coords)
						local markerShow = cfg.Marker and cfg.Marker.show or 0.0

						if markerShow > 0.0 and distanceSq < (markerShow * markerShow) then
							sleep = 0
							local marker = cfg.Marker
							DrawMarker(marker.type, zone.coords.x, zone.coords.y, zone.coords.z + marker.hight, 0.0, 0.0, 0.0, 0, 0.0, 0.0, marker.size.x, marker.size.y, marker.size.z, marker.colors.r, marker.colors.g, marker.colors.b, marker.colors.a, false, true, 2, true, false, false, false)
						end

						if distanceSq < zone.sizeSq then
							sleep = 0
							shouldShowTextUI = true
							showSkinMenuTextUI(cfg.Key, cfg.Text)
							if not openedMenu and IsDisabledControlJustReleased(0, Keys[cfg.Key]) then
								openMenuFromZone(zone.name, zone, "Normal")
								openedMenu = true
								Citizen.Wait(1000)
								break
							end
						end
					end

					if not openedMenu then
						local favoriteConfig = Config["FavoritePosition"]
						for i = 1, #favoriteMenuZones do
							local zone = favoriteMenuZones[i]
							local distanceSq = getDistanceSquared(coords, zone.coords)
							local markerShow = favoriteConfig.Marker and favoriteConfig.Marker.show or 0.0

							if markerShow > 0.0 and distanceSq < (markerShow * markerShow) then
								sleep = 0
								local marker = favoriteConfig.Marker
								DrawMarker(marker.type, zone.coords.x, zone.coords.y, zone.coords.z + marker.hight, 0.0, 0.0, 0.0, 0, 0.0, 0.0, marker.size.x, marker.size.y, marker.size.z, marker.colors.r, marker.colors.g, marker.colors.b, marker.colors.a, false, true, 2, true, false, false, false)
							end

							if distanceSq < zone.sizeSq then
								sleep = 0
								shouldShowTextUI = true
								showSkinMenuTextUI(favoriteConfig.Key, favoriteConfig.Text)
								if IsDisabledControlJustReleased(0, Keys[favoriteConfig.Key]) then
									TriggerEvent("skinchanger:getSkin", function(skin)
										MenuType = "Favorite"
										LastSkin = skin
										activeSkinMenuZone = {
											coords = zone.coords,
											size = zone.size,
										}
										if zone.heading then
											SetEntityHeading(playerPed, zone.heading)
										end
										ClearPedTasks(playerPed)
										ToggleFavorite(true)
									end)
									Citizen.Wait(1000)
									openedMenu = true
									break
								end
							end
						end
					end

					if not shouldShowTextUI then
						hideSkinMenuTextUI()
					end
					if ToggleEffect then
						ToggleEffect = false
						if activeNearbyFx then
							StopParticleFxLooped(activeNearbyFx, false)
							activeNearbyFx = nil
						end
					end
				end
			else
				sleep = 5
				local playerPed = getPlayerPedCached()
				disableSkinMenuControls()
				FreezeEntityPosition(playerPed, true)
				if IsPedDeadOrDying(playerPed) and not IsPedInAnyVehicle(playerPed, false) then
					ToggleSkinMenu(false)
					TriggerEvent('skinchanger:loadSkin', LastSkin)
				end

				if activeSkinMenuZone and activeSkinMenuZone.coords then
					local currentCoords = GetEntityCoords(playerPed)
					local maxDistance = (activeSkinMenuZone.size or 1.0) + 0.2
					if getDistanceSquared(currentCoords, activeSkinMenuZone.coords) > (maxDistance * maxDistance) then
						ToggleSkinMenu(false)
						TriggerEvent('skinchanger:loadSkin', LastSkin)
						Config["Notify"]("ออกนอกระยะเมนูแต่งตัว ระบบปิดเมนูอัตโนมัติ", "error")
					end
				end
			end

            Citizen.Wait(sleep)
        end
    end)

	function LoadFX(FX)
		while not HasNamedPtfxAssetLoaded(FX) do
			RequestNamedPtfxAsset(FX)
			Citizen.Wait(10)
		end
	end

	function ToggleFavorite(status)
		UI_TYPE = "FAVORITE"
		if status then
			hideOtherPlayers = false
			setOtherPlayersVisible(true)
			hideSkinMenuTextUI()
			FreezeEntityPosition(PlayerPedId(), true)
			notifySetRight(28)
			setCarHUDVisible(true)
			setScreenUI(true)
		else
			hideOtherPlayers = false
			setOtherPlayersVisible(true)
			SkinIndex = nil
			lastcampos = nil
			FreezeEntityPosition(PlayerPedId(), false)
			notifySetRight(false)
			DeleteCam()
			for k,v in pairs(ScriptEntity) do DeleteEntity(v) end
			setCarHUDVisible(false)
			setScreenUI(false)
		end
		ToggleMenu = status
		setMenuNuiFocus(ToggleMenu)
		ClearPedTasks(PlayerPedId())
		SendNUIMessage({
			action = 'ToggleFavorite',
			status = ToggleMenu,
			CFG = Config["FavoritePosition"]
		})
	end

	RegisterNUICallback('setcamera', function(data, cb)
		SetCamera(data.pos)
        cb("ok")
    end)

    local CamHeight = 0.0
    local CameraYawOffset = 0.0
    local ActiveCameraPos = nil

    local function ResolveCameraCollision(focusCoords, desiredCoords, ignoreEntity)
        local ray = StartShapeTestRay(
            focusCoords.x, focusCoords.y, focusCoords.z,
            desiredCoords.x, desiredCoords.y, desiredCoords.z,
            511,
            ignoreEntity or 0,
            7
        )

        local _, hit, hitCoords = GetShapeTestResult(ray)
        if hit == 1 then
            local rayDirection = desiredCoords - focusCoords
            local rayLength = #(rayDirection)
            if rayLength > 0.001 then
                local normalized = rayDirection / rayLength
                local safeCoords = hitCoords - (normalized * 0.18)
                local focusToSafe = #(safeCoords - focusCoords)
                if focusToSafe < 0.35 then
                    safeCoords = focusCoords + (normalized * 0.35)
                end
                return safeCoords, true
            end
        end

        return desiredCoords, false
    end

    local function UpdateCameraPosition()
        if not ActiveCameraPos or not Cam or not Config["CameraPos"][ActiveCameraPos] then
            return
        end

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local cfgcam = Config["CameraPos"][ActiveCameraPos]
        local yaw = math.rad(CameraYawOffset)

        local localOffsetX = (cfgcam.x * math.cos(yaw)) - (cfgcam.y * math.sin(yaw))
        local localOffsetY = (cfgcam.x * math.sin(yaw)) + (cfgcam.y * math.cos(yaw))
        local camX, camY, camZ = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, localOffsetX, localOffsetY, cfgcam.z))
        local focusCoords = vector3(coords.x, coords.y, coords.z + cfgcam.height)
        local desiredCoords = vector3(camX, camY, camZ)
        local finalCoords = ResolveCameraCollision(focusCoords, desiredCoords, playerPed)

        SetCamCoord(Cam, finalCoords.x, finalCoords.y, finalCoords.z)
        PointCamAtCoord(Cam, focusCoords.x, focusCoords.y, focusCoords.z)
        CamHeight = cfgcam.height
    end

	function SetCamera(pos)
		if Config["CameraPos"][pos] then
			DestroyCam(Cam, false)
            CameraYawOffset = 0.0
            ActiveCameraPos = pos

			local playerPed = PlayerPedId()
			local cfgcam = Config["CameraPos"][pos]
			Cam = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0, false, 0)
            UpdateCameraPosition()
			-- AttachCamToPedBone(Cam,playerPed, 0 , 6.0, 0.0, 0.0 ,false)

			CenterHeading = GetEntityHeading(playerPed)

			if lastcampos == nil or pos ~= lastcampos then
				lastcampos = pos
                local coords = GetEntityCoords(playerPed)
				LightCamera(coords)
			end

			SetCamFov(Cam, cfgcam.fov)
			SetCamActive(Cam, true)
			RenderScriptCams(true, true, 0, true, true)
			CameraActive = true
		end
	end

	function DeleteCam() 
        CameraActive = false
        if Cam then
            SetCamActive(Cam, false)
            RenderScriptCams(false, true, 0, true, true)
            DestroyCam(Cam, false)
        end
        Cam = nil
        ActiveCameraPos = nil
        CameraYawOffset = 0.0
    end

	function LightCamera(coords)
		for k,v in pairs(ScriptEntity) do DeleteEntity(v) end
        local prop = "prop_wall_light_13a"
        local lightcam1 = CreateObject(GetHashKey(prop), coords.x,coords.y,coords.z+1, false, false, false)
        AttachEntityToEntity(lightcam1, PlayerPedId(),  -1 , 0.0,4.0,2.5, 0.0, 90.0, 0.0, true, false, false, true, 1, true)
        DetachEntity(lightcam1)
        FreezeEntityPosition(lightcam1,true)
        SetEntityAlpha(lightcam1,1)
        table.insert(ScriptEntity, lightcam1)

        local lightcam2 = CreateObject(GetHashKey(prop), coords.x,coords.y,coords.z+1, false, false, false)
        AttachEntityToEntity(lightcam2, PlayerPedId(),  -1 , 0.0,-3.0,2.5, 180.0, 120.0, 0.0, true, false, false, true, 1, true)
        DetachEntity(lightcam2)
        FreezeEntityPosition(lightcam2,true)
        SetEntityAlpha(lightcam2,1)
        table.insert(ScriptEntity, lightcam2)
    end

	RegisterNUICallback('rotation', function(data, cb)
        CameraYawOffset = tonumber(data.range) or 0.0
        UpdateCameraPosition()
        cb("ok")
    end)

	

    function V3MulQuat(self,quat)    
        local num   = quat.x * 2
        local num2  = quat.y * 2
        local num3  = quat.z * 2
        local num4  = quat.x * num
        local num5  = quat.y * num2
        local num6  = quat.z * num3
        local num7  = quat.x * num2
        local num8  = quat.x * num3
        local num9  = quat.y * num3
        local num10 = quat.w * num
        local num11 = quat.w * num2
        local num12 = quat.w * num3
        
        local x = (((1 - (num5 + num6)) * self.x) + ((num7 - num12) * self.y)) + ((num8 + num11) * self.z)
        local y = (((num7 + num12) * self.x) + ((1 - (num4 + num6)) * self.y)) + ((num9 - num10) * self.z)
        local z = (((num8 - num11) * self.x) + ((num9 + num10) * self.y)) + ((1 - (num4 + num5)) * self.z)
        
        self = vector3(x, y, z) 
        return self
    end
    function V3Mul(self,q)
        if type(q) == "number" then
            self = self * q
        else
            self = V3MulQuat(self,q)
        end
        return self
    end
    function V3SqrMagnitude(self)
        return self.x * self.x + self.y * self.y + self.z * self.z
    end
    function V3ClampMagnitude(self,max)
        if V3SqrMagnitude(self) > (max * max) then
            self = V3SetNormalize(self)
            self = V3Mul(self,max)
        end
        return self
    end
    function V3Div(self,d)
        self = vector3(self.x / d,self.y / d,self.z / d)
        
        return self
    end
    function V3Magnitude(self)
        return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
    end
    function V3SetNormalize(self)
        local num = V3Magnitude(self)
        if num == 1 then
            return self
        elseif num > 1e-5 then
            self = V3Div(self,num)
        else
            self = vector3(0.0,0.0,0.0)
        end
        return self
    end
    local brightness = 0.0
    Citizen.CreateThread(function()
        while true do
            if not CameraActive then
                Citizen.Wait(1000)
            else
                Citizen.Wait(0)
            end
            if CameraActive then
                local camCoords = GetCamCoord(Cam)
                local pedCoords = GetEntityCoords(PlayerPedId()) + vector3(0.0,0.0,CamHeight)
                local direction = pedCoords - camCoords
                local normal = V3SetNormalize(direction)
                DrawSpotLight(camCoords.x, camCoords.y, camCoords.z, normal.x, normal.y, normal.z, 255, 255, 255, 10.0, brightness, 0.0, 10.0, 1.0)
            end
        end
    end)
    RegisterNUICallback('brightness', function(data, cb)
        brightness = data.value + 0.0
        cb("ok")
    end)
    RegisterNUICallback('characterrotation', function(data, cb)
        if CenterHeading then
            local delta = tonumber(data.delta) or 0.0
            if delta ~= 0.0 then
                local playerPed = PlayerPedId()
                CenterHeading = CenterHeading + (delta * 0.35)
                SetEntityHeading(playerPed, CenterHeading)
            end
        end
        cb("ok")
    end)
    RegisterNUICallback('camerarotation', function(data, cb)
        local delta = tonumber(data.delta) or 0.0
        if delta ~= 0.0 then
            CameraYawOffset = CameraYawOffset + (delta * 0.35)
            if CameraYawOffset > 180.0 then
                CameraYawOffset = CameraYawOffset - 360.0
            elseif CameraYawOffset < -180.0 then
                CameraYawOffset = CameraYawOffset + 360.0
            end
            UpdateCameraPosition()
        end
        cb("ok")
    end)
end

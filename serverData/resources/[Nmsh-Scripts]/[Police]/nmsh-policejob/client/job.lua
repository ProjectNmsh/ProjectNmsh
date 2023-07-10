-- Variables
local currentGarage = 0
local inFingerprint = false
local FingerPrintSessionId = nil
local inStash = false
local inTrash = false
local inArmoury = false
local inHelicopter = false
local inImpound = false
local inGarage = false
local GaragePed = {}
local HeliPed = {}
local Heli = nil
local PDCar = {}

local function loadAnimDict(dict) -- interactions, job,
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

local function GetClosestPlayer() -- interactions, job, tracker
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

local function openFingerprintUI()
    SendNUIMessage({
        type = "fingerprintOpen"
    })
    inFingerprint = true
    SetNuiFocus(true, true)
end

local function SetCarItemsInfo()
    local items = {}
    for _, item in pairs(Config.CarItems) do
        local itemInfo = QBCore.Shared.Items[item.name:lower()]
        items[item.slot] = {
            name = itemInfo["name"],
            amount = tonumber(item.amount),
            info = item.info,
            label = itemInfo["label"],
            description = itemInfo["description"] and itemInfo["description"] or "",
            weight = itemInfo["weight"],
            type = itemInfo["type"],
            unique = itemInfo["unique"],
            useable = itemInfo["useable"],
            image = itemInfo["image"],
            slot = item.slot,
        }
    end
    Config.CarItems = items
end

local function closeMenuFull()
    exports['nmsh-menu']:closeMenu()
end

local function doCarDamage(currentVehicle, veh)
    local smash = false
    local damageOutside = false
    local damageOutside2 = false
    local engine = veh.engine + 0.0
    local body = veh.body + 0.0

    if engine < 200.0 then engine = 200.0 end
    if engine  > 1000.0 then engine = 950.0 end
    if body < 150.0 then body = 150.0 end
    if body < 950.0 then smash = true end
    if body < 920.0 then damageOutside = true end
    if body < 920.0 then damageOutside2 = true end

    Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)

    if smash then
        SmashVehicleWindow(currentVehicle, 0)
        SmashVehicleWindow(currentVehicle, 1)
        SmashVehicleWindow(currentVehicle, 2)
        SmashVehicleWindow(currentVehicle, 3)
        SmashVehicleWindow(currentVehicle, 4)
    end

    if damageOutside then
        SetVehicleDoorBroken(currentVehicle, 1, true)
        SetVehicleDoorBroken(currentVehicle, 6, true)
        SetVehicleDoorBroken(currentVehicle, 4, true)
    end

    if damageOutside2 then
        SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
        SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
        SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
        SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
    end

    if body < 1000 then
        SetVehicleBodyHealth(currentVehicle, 985.1)
    end
end

local function TakeOutImpound(vehicle)
    local coords = Config.Locations["impound"][currentGarage]
    if coords then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            QBCore.Functions.TriggerCallback('nmsh-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)
                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetVehicleDirtLevel(veh, 0.0)
                SetEntityHeading(veh, coords.w)
                exports['LegacyFuel']:SetFuel(veh, vehicle.fuel)
                doCarDamage(veh, vehicle)
                TriggerServerEvent('police:server:TakeOutImpound', vehicle.plate, currentGarage)
                closeMenuFull()
                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                SetVehicleEngineOn(veh, true, true)
            end, vehicle.plate)
        end, vehicle.vehicle, coords, true)
    end
end

local function PerformanceUpgradeVehicle(vehicle)
    local max
    local mods = {}
    if Config.CarMods.engine then
        mods[#mods+1] = 11
    end
    if Config.CarMods.brakes then
        mods[#mods+1] = 12
    end
    if Config.CarMods.gearbox then
        mods[#mods+1] = 13
    end
    if Config.CarMods.armour then
        mods[#mods+1] = 14
    end
    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        for _,modType in pairs(mods) do
            max = GetNumVehicleMods(vehicle, modType) - 1
            SetVehicleMod(vehicle, modType, max, false)
        end
        if Config.CarMods.turbo then
            ToggleVehicleMod(vehicle, 18, true)
        end
    end
end

local function TakeOutVehicle(vehicleInfo)
    local coords = Config.Locations["vehspawn"][currentGarage]
    if coords then
        if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 2.0) then
            QBCore.Functions.Notify(Lang:t("error.clearspawnpoint"), "error", 4500)
            return
        end
        QBCore.Functions.TriggerCallback('police:server:PayForVehicle', function(result)
            if not result then return QBCore.Functions.Notify(Lang:t('error.not_enough_money'), 'error', 4500) end
            QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
                local veh = NetToVeh(netId)
                SetCarItemsInfo()
                SetVehicleNumberPlateText(veh, Lang:t('info.police_plate')..tostring(math.random(1000, 9999)))
                SetEntityHeading(veh, coords.w)
                exports['LegacyFuel']:SetFuel(veh, 100.0)
                closeMenuFull()
                if Config.EnableMods then
                    PerformanceUpgradeVehicle(veh)
                end
                if Config.EnableExtras then
                    if Config.CarExtras.extras ~= nil then
                        QBCore.Shared.SetDefaultVehicleExtras(veh, Config.CarExtras.extras)
                    end
                end
                PDCar[#PDCar+1] = {veh = veh, model = vehicleInfo.vehicle}
                SetVehicleLivery(veh,vehicleInfo.livery)
                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                TriggerServerEvent("inventory:server:addTrunkItems", QBCore.Functions.GetPlate(veh), Config.CarItems)
                SetVehicleEngineOn(veh, true, true)
            end, vehicleInfo.vehicle, coords, true)
        end,vehicleInfo.price)
    end
end

local function SetWeaponSeries()
    for k, _ in pairs(Config.Items.items) do
        if k < 6 then
            Config.Items.items[k].info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
        end
    end
end

local function MenuGarage(currentSelection)
    local vehicleMenu = {
        {
            header = Lang:t('menu.garage_title'),
            isMenuHeader = true
        }
    }

    local authorizedVehicles = Config.AuthorizedVehicles[currentSelection]
    for veh, data in pairs(authorizedVehicles) do
        if PDCar and next(PDCar) then
            for l, b in pairs(PDCar) do
                if b.model == veh then
                    for _,v in pairs(data.ranks) do
                        if v == PlayerJob.grade.level then
                            vehicleMenu[#vehicleMenu+1] = {
                                header = data.label,
                                txt = "",
                                params = {
                                    event = "police:client:VehicleSubMenu",
                                    args = {
                                        vehicle = veh,
                                        vehlabel = veh,
                                        currentSelection = currentSelection,
                                        livery = data.livery,
                                        car = b.veh,
                                        tableid = l,
                                        out = true
                                    }
                                }
                            }
                        end
                    end
                end
            end
        else
            for _,v in pairs(data.ranks) do
                if v == PlayerJob.grade.level then
                    local vehprice, pricetext
                    if data.price then
                        vehprice = data.price
                        pricetext = "- Price : $"..data.price
                    else
                        vehprice = 0
                        pricetext = "- Price : Free"
                    end
                    vehicleMenu[#vehicleMenu+1] = {
                        header = data.label,
                        txt = pricetext,
                        params = {
                            event = "police:client:VehicleSubMenu",
                            args = {
                                vehicle = veh,
                                vehlabel = veh,
                                currentSelection = currentSelection,
                                livery = data.livery,
                                out = false,
                                price = vehprice
                            }
                        }
                    }
                end
            end
        end
    end

    vehicleMenu[#vehicleMenu+1] = {
        header = Lang:t('menu.close'),
        txt = "",
        params = {
            event = "nmsh-menu:client:closeMenu"
        }

    }
    exports['nmsh-menu']:openMenu(vehicleMenu)
end

local function MenuImpound(currentSelection)
    local impoundMenu = {
        {
            header = Lang:t('menu.impound'),
            isMenuHeader = true
        }
    }
    QBCore.Functions.TriggerCallback("police:GetImpoundedVehicles", function(result)
        local shouldContinue = false
        if result == nil then
            QBCore.Functions.Notify(Lang:t("error.no_impound"), "error", 5000)
        else
            shouldContinue = true
            for _ , v in pairs(result) do
                local enginePercent = QBCore.Shared.Round(v.engine / 10, 0)
                local currentFuel = v.fuel
                local vname = QBCore.Shared.Vehicles[v.vehicle].name

                impoundMenu[#impoundMenu+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt =  Lang:t('info.vehicle_info', {value = enginePercent, value2 = currentFuel}),
                    params = {
                        event = "police:client:TakeOutImpound",
                        args = {
                            vehicle = v,
                            currentSelection = currentSelection
                        }
                    }
                }
            end
        end


        if shouldContinue then
            impoundMenu[#impoundMenu+1] = {
                header = Lang:t('menu.close'),
                txt = "",
                params = {
                    event = "nmsh-menu:client:closeMenu"
                }
            }
            exports['nmsh-menu']:openMenu(impoundMenu)
        end
    end)

end

local function syncVehicle(entity)
	SetVehicleModKit(entity, 0)
	if entity ~= 0 and DoesEntityExist(entity) then
		if not NetworkHasControlOfEntity(entity) then
			NetworkRequestControlOfEntity(entity)
			local timeout = 2000
			while timeout > 0 and not NetworkHasControlOfEntity(entity) do
				Wait(100)
				timeout = timeout - 100
			end
		end
		if not IsEntityAMissionEntity(entity) then
			SetEntityAsMissionEntity(entity, true, true)
			local timeout = 2000
			while timeout > 0 and not IsEntityAMissionEntity(entity) do
				Wait(100)
				timeout = timeout - 100
			end
		end
	end
end

local function getVehicleLiveries(vehicle)
    local validMods = {}
    if GetNumVehicleMods(vehicle, 48) == 0 and GetVehicleLiveryCount(vehicle) ~= 0 then
        oldlivery = true
        for i = 0, GetVehicleLiveryCount(vehicle)-1 do
            if i ~= 0 then validMods[i] = { id = i, name = "Livery "..i } end
        end
    else
        oldlivery = false
        for i = 1, GetNumVehicleMods(vehicle, 48) do
            local modName = GetLabelText(GetModTextLabel(vehicle, 48, (i - 1)))
            validMods[i] = { id = (i - 1), name = modName }
        end
    end
    return validMods
end

local function getVehicleExtras(vehicle)
    local validExtras = {}
    for i=1, 21, 1 do
        if DoesExtraExist(vehicle, i) then
            validExtras[i] = {id = i}
        end
    end
    return validExtras
end

--NUI Callbacks
RegisterNUICallback('closeFingerprint', function(_, cb)
    SetNuiFocus(false, false)
    inFingerprint = false
    cb('ok')
end)

--Events
RegisterNetEvent('police:client:showFingerprint', function(playerId)
    openFingerprintUI()
    FingerPrintSessionId = playerId
end)

RegisterNetEvent('police:client:showFingerprintId', function(fid)
    SendNUIMessage({
        type = "updateFingerprintId",
        fingerprintId = fid
    })
    PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
end)

RegisterNUICallback('doFingerScan', function(_, cb)
    TriggerServerEvent('police:server:showFingerprintId', FingerPrintSessionId)
    cb("ok")
end)

RegisterNetEvent('police:client:SendEmergencyMessage', function(coords, message)
    TriggerServerEvent("police:server:SendEmergencyMessage", coords, message)
    TriggerEvent("police:client:CallAnim")
end)

RegisterNetEvent('police:client:EmergencySound', function()
    PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
end)

RegisterNetEvent('police:client:CallAnim', function()
    local isCalling = true
    local callCount = 5
    loadAnimDict("cellphone@")
    TaskPlayAnim(PlayerPedId(), 'cellphone@', 'cellphone_call_listen_base', 3.0, -1, -1, 49, 0, false, false, false)
    Wait(1000)
    CreateThread(function()
        while isCalling do
            Wait(1000)
            callCount = callCount - 1
            if callCount <= 0 then
                isCalling = false
                StopAnimTask(PlayerPedId(), 'cellphone@', 'cellphone_call_listen_base', 1.0)
            end
        end
    end)
end)

RegisterNetEvent('police:client:ImpoundVehicle', function(fullImpound, price)
    local vehicle = QBCore.Functions.GetClosestVehicle()
    local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
    local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
    local totalFuel = exports['LegacyFuel']:GetFuel(vehicle)
    if vehicle ~= 0 and vehicle then
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local vehpos = GetEntityCoords(vehicle)
        if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(ped) then
           QBCore.Functions.Progressbar('impound', Lang:t('progressbar.impound'), 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = 'missheistdockssetup1clipboard@base',
                anim = 'base',
                flags = 1,
            }, {
                model = 'prop_notepad_01',
                bone = 18905,
                coords = { x = 0.1, y = 0.02, z = 0.05 },
                rotation = { x = 10.0, y = 0.0, z = 0.0 },
            },{
                model = 'prop_pencil_01',
                bone = 58866,
                coords = { x = 0.11, y = -0.02, z = 0.001 },
                rotation = { x = -120.0, y = 0.0, z = 0.0 },
            }, function() -- Play When Done
                local plate = QBCore.Functions.GetPlate(vehicle)
                TriggerServerEvent("police:server:Impound", plate, fullImpound, price, bodyDamage, engineDamage, totalFuel)
                while NetworkGetEntityOwner(vehicle) ~= 128 do  -- Ensure we have entity ownership to prevent inconsistent vehicle deletion
                    NetworkRequestControlOfEntity(vehicle)
                    Wait(100)
                end
                QBCore.Functions.DeleteVehicle(vehicle)
                TriggerEvent('QBCore:Notify', Lang:t('success.impounded'), 'success')
                ClearPedTasks(ped)
            end, function() -- Play When Cancel
                ClearPedTasks(ped)
                TriggerEvent('QBCore:Notify', Lang:t('error.canceled'), 'error')
            end)
        end
    end
end)

RegisterNetEvent('police:client:CheckStatus', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == "leo" then
            local player, distance = GetClosestPlayer()
            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)
                QBCore.Functions.TriggerCallback('police:GetPlayerStatus', function(result)
                    if result then
                        for _, v in pairs(result) do
                            QBCore.Functions.Notify(''..v..'')
                        end
                    end
                end, playerId)
            else
                QBCore.Functions.Notify(Lang:t("error.none_nearby"), "error")
            end
        end
    end)
end)

RegisterNetEvent("police:client:VehicleMenuHeader", function (data)
    MenuGarage(data.currentSelection)
    currentGarage = data.currentSelection
end)


RegisterNetEvent("police:client:ImpoundMenuHeader", function (data)
    MenuImpound(data.currentSelection)
    currentGarage = data.currentSelection
end)

RegisterNetEvent('police:client:TakeOutImpound', function(data)
    if inImpound then
        local vehicle = data.vehicle
        TakeOutImpound(vehicle)
    end
end)

RegisterNetEvent('police:client:VehicleSubMenu', function(data)
    local SubMenu = {}
    SubMenu[#SubMenu+1] = {header = data.vehlabel.." Menu", txt = "Take out or return your vehicle", isMenuHeader = true}
    if data.out then
        SubMenu[#SubMenu+1] = {header = 'Return '..data.vehlabel, txt = "", params = {event = "police:client:ReturnVehicle", args = {car = data.car}}}
        table.remove(PDCar, data.tableid)
    else
        SubMenu[#SubMenu+1] = {header = 'Take out '..data.vehlabel, txt = "Take out for $"..data.price, params = {event = "police:client:TakeOutVehicle", args = {vehicle = data.vehicle, currentSelection = data.currentSelection, livery = data.livery, price = data.price}}}
    end
    exports['nmsh-menu']:openMenu(SubMenu)
end)

RegisterNetEvent('police:client:TakeOutVehicle', function(data)
    if Config.UseTarget then
        TakeOutVehicle(data)
    else
        if inGarage then
            TakeOutVehicle(data)
        end
    end
end)

RegisterNetEvent('police:client:ReturnVehicle', function(data)
    QBCore.Functions.DeleteVehicle(data.car)
end)

RegisterNetEvent('police:client:EvidenceStashDrawer', function(data)
    local currentEvidence = data.number
    local currentType = data.type
    local pos = GetEntityCoords(PlayerPedId())
    local takeLoc = Config.Locations["evidence"][currentEvidence]

    if not takeLoc then return end

    if #(pos - takeLoc) <= 1.0 then
        if currentType == 'drawer' then
            local drawer = exports['nmsh-input']:ShowInput({
                header = Lang:t('info.evidence_stash', {value = currentEvidence}),
                submitText = "open",
                inputs = {
                    {
                        type = 'number',
                        isRequired = true,
                        name = 'slot',
                        text = Lang:t('info.slot')
                    }
                }
            })
            if drawer then
                if not drawer.slot then return end
                TriggerServerEvent("inventory:server:OpenInventory", "stash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawer.slot}), {
                    maxweight = 4000000,
                    slots = 500,
                })
                TriggerEvent("inventory:client:SetCurrentStash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawer.slot}))
            else return end
        elseif currentType == 'stash' then
            TriggerServerEvent("inventory:server:OpenInventory", "stash", Lang:t('info.general_current_evidence', {value = currentEvidence}), {maxweight = 4000000, slots = 300,})
            TriggerEvent("inventory:client:SetCurrentStash", Lang:t('info.general_current_evidence', {value = currentEvidence}))
        end

    else
        exports['nmsh-menu']:closeMenu()
    end
end)

RegisterNetEvent('nmsh-policejob:ToggleDuty', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local dutymenu = {}

    if PlayerData.job.onduty then dutystatus = '🟢 ' .. Lang:t('menu.dty_onduty') else dutystatus = '🔴 ' .. Lang:t('menu.dty_offduty') end

    dutymenu[#dutymenu + 1] = {isMenuHeader = true, header = PlayerData.job.label, txt = 'Your duty status: '..dutystatus}

    if PlayerData.job.onduty then
        dutymenu[#dutymenu + 1] = { header = '', txt = Lang:t('menu.dty_beonduty'), icon = 'fa-solid fa-signature', disabled = true,
            params = {event = '', args = { }}}
        dutymenu[#dutymenu + 1] = {header = '', txt = Lang:t('menu.dty_beoffduty'), icon = 'fa-solid fa-signature',
            params = {isServer = true, event = 'police:server:changeDuty', args = { duty = false}}}
    else
        dutymenu[#dutymenu + 1] = {header = '', txt = Lang:t('menu.dty_beonduty'), icon = 'fa-solid fa-signature',
            params = {isServer = true, event = 'police:server:changeDuty',args = {duty = true}}}
        dutymenu[#dutymenu + 1] = {header = '', txt = Lang:t('menu.dty_beoffduty'), icon = 'fa-solid fa-signature', disabled = true,
            params = {event = '', args = { }}}
    end exports['nmsh-menu']:openMenu(dutymenu)

    TriggerServerEvent("police:server:UpdateCurrentCops")
    TriggerServerEvent("police:server:UpdateBlips")
end)

RegisterNetEvent('nmsh-police:client:scanFingerPrint', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent("police:server:showFingerprint", playerId)
    else
        QBCore.Functions.Notify(Lang:t("error.none_nearby"), "error")
    end
end)

RegisterNetEvent('nmsh-police:client:openArmoury', function()
    local authorizedItems = {
        label = Lang:t('menu.pol_armory'),
        slots = 30,
        items = {}
    }
    local index = 1
    for _, armoryItem in pairs(Config.Items.items) do
        for i=1, #armoryItem.authorizedJobGrades do
            if armoryItem.authorizedJobGrades[i] == PlayerJob.grade.level then
                authorizedItems.items[index] = armoryItem
                authorizedItems.items[index].slot = index
                index = index + 1
            end
        end
    end
    SetWeaponSeries()
    TriggerServerEvent("inventory:server:OpenInventory", "shop", "police", authorizedItems)
end)

RegisterNetEvent('nmsh-police:client:spawnHelicopter', function(k)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
    else
        local coords = Config.Locations["helispawn"][k]
        if Heli then QBCore.Functions.Notify(Lang:t("error.alradyhaveheli"), "error", 4500) return end
        if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 2.0) then QBCore.Functions.Notify(Lang:t("error.clearspawnpoint"), "error", 4500) return end
        if not coords then coords = GetEntityCoords(PlayerPedId()) end
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            Heli = veh
            SetVehicleLivery(veh , 0)
            SetVehicleMod(veh, 0, 48)
            SetVehicleNumberPlateText(veh, "ZULU"..tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            exports['LegacyFuel']:SetFuel(veh, 100.0)
            closeMenuFull()
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true)
        end, Config.PoliceHelicopter, coords, true)
    end
end)

RegisterNetEvent('nmsh-police:client:removeHelicopter', function()
    DeleteEntity(Heli)
    Heli = nil
end)

RegisterNetEvent("nmsh-police:client:openStash", function()
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
    TriggerEvent("inventory:client:SetCurrentStash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
end)

RegisterNetEvent('nmsh-police:client:openTrash', function()
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policetrash", {
        maxweight = 4000000,
        slots = 300,
    })
    TriggerEvent("inventory:client:SetCurrentStash", "policetrash")
end)

RegisterNetEvent('policejob:client:VehicleLiveryMenu', function(data)
    local vehicle = data.vehicle
    local liveries = getVehicleLiveries(vehicle)
    local LiveryMenu = {}
    LiveryMenu[#LiveryMenu+1] = {header = "Choose your livery", txt = '', isMenuHeader = true}
    LiveryMenu[#LiveryMenu+1] = {header = '', txt = '❌ Close'}
    for k,v in pairs(liveries) do
        LiveryMenu[#LiveryMenu+1] = {header = v.name, txt = 'Change livery to '.. v.name, params = {event = 'police:client:ChangeLivery', args = {id = v.id}}}
    end
    exports['nmsh-menu']:openMenu(LiveryMenu)
end)

RegisterNetEvent('police:client:ChangeLivery', function(data)
    if IsPedInAnyVehicle(PlayerPedId(), false) then	vehicle = GetVehiclePedIsIn(PlayerPedId(), false) syncVehicle(vehicle) end
    if oldlivery then
		if modName == "NULL" then modName = "old" end
		if GetVehicleLivery(vehicle) == tonumber(data.id) then
            QBCore.Functions.Notify(data.id.." already installed", "error")
			return
		end
	else
		if modName == "NULL" then modName = "Stock" end
		if GetVehicleMod(vehicle, 48) == tonumber(data.id) then
            QBCore.Functions.Notify(modName.." already installed", "error")
			return
		end
	end
	if oldlivery then
		if tonumber(data.id) == 0 then
			SetVehicleMod(vehicle, 48, -1, false)
			SetVehicleLivery(vehicle, 0)
		else
			SetVehicleMod(vehicle, 48, -1, false)
			SetVehicleLivery(vehicle, tonumber(data.id))
		end
	elseif not oldlivery then
		if tonumber(data.id) == -1 then
			SetVehicleMod(vehicle, 48, -1, false)
			SetVehicleLivery(vehicle, -1)
		else
			SetVehicleMod(vehicle, 48, tonumber(data.id), false)
			SetVehicleLivery(vehicle, -1)
		end
	end
    local data = {}
    data.vehicle = vehicle
    TriggerEvent('policejob:client:VehicleLiveryMenu', data)
end)

RegisterNetEvent('policejob:client:VehicleExtrasMenu', function(data)
    local vehicle = data.vehicle
    local extras = getVehicleExtras(vehicle)
    local ExtraMenu = {}
    ExtraMenu[#ExtraMenu+1] = {header = 'Extras Menu', txt = 'Change your vehicle extras', isMenuHeader = true}
    ExtraMenu[#ExtraMenu+1] = {header = '', txt = '❌ Close'}
    for k,v in pairs(extras) do
        ExtraMenu[#ExtraMenu+1] = {header = 'Extra '.. v.id, txt = 'Change extra option '.. v.id, params = {event = 'police:client:ChangeExtra', args = {id = v.id, veh = vehicle}}}
    end
    exports['nmsh-menu']:openMenu(ExtraMenu)
end)

RegisterNetEvent('police:client:ChangeExtra', function(data)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if IsVehicleExtraTurnedOn(veh, data.id) then
        SetVehicleExtra(veh, data.id, 1)
        QBCore.Functions.Notify('Extra '.. data.id ..' has been deactivated', 'error', 2500)
    else
        SetVehicleExtra(veh, data.id, 0)
        QBCore.Functions.Notify('Extra '.. data.id ..' has been activated', 'success', 2500)
    end
    local data = {}
    data.vehicle = veh
    TriggerEvent('policejob:client:VehicleExtrasMenu', data)
end)

--##### Threads #####--

local dutylisten = false
local function dutylistener()
    dutylisten = true
    CreateThread(function()
        while dutylisten do
            if PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    local PlayerData = QBCore.Functions.GetPlayerData()
                    local dutymenu = {}

                    if PlayerData.job.onduty then dutystatus = '🟢 ' .. Lang:t('menu.dty_onduty') else dutystatus = '🔴 ' .. Lang:t('menu.dty_offduty') end

                    dutymenu[#dutymenu + 1] = {isMenuHeader = true, header = PlayerData.job.label, txt = 'Your duty status: '..dutystatus}

                    if PlayerData.job.onduty then
                        dutymenu[#dutymenu + 1] = { header = '', txt = Lang:t('menu.dty_beonduty'), icon = 'fa-solid fa-signature', disabled = true,
                            params = {event = '', args = { }}}
                        dutymenu[#dutymenu + 1] = {header = '', txt = Lang:t('menu.dty_beoffduty'), icon = 'fa-solid fa-signature',
                            params = {isServer = true, event = 'police:server:changeDuty', args = { duty = false}}}
                    else
                        dutymenu[#dutymenu + 1] = {header = '', txt = Lang:t('menu.dty_beonduty'), icon = 'fa-solid fa-signature',
                            params = {isServer = true, event = 'police:server:changeDuty',args = {duty = true}}}
                        dutymenu[#dutymenu + 1] = {header = '', txt = Lang:t('menu.dty_beoffduty'), icon = 'fa-solid fa-signature', disabled = true,
                            params = {event = '', args = { }}}
                    end exports['nmsh-menu']:openMenu(dutymenu)

                    TriggerServerEvent("police:server:UpdateCurrentCops")
                    TriggerServerEvent("police:server:UpdateBlips")
                    dutylisten = false
                    break
                end
            else
                break
            end
            Wait(0)
        end
    end)
end

-- Personal Stash Thread
local function stash()
    CreateThread(function()
        while true do
            Wait(0)
            if inStash and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
                    TriggerEvent("inventory:client:SetCurrentStash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
                    break
                end
            else
                break
            end
        end
    end)
end

-- Police Trash Thread
local function trash()
    CreateThread(function()
        while true do
            Wait(0)
            if inTrash and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policetrash", {
                        maxweight = 4000000,
                        slots = 300,
                    })
                    TriggerEvent("inventory:client:SetCurrentStash", "policetrash")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Fingerprint Thread
local function fingerprint()
    CreateThread(function()
        while true do
            Wait(0)
            if inFingerprint and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("nmsh-police:client:scanFingerPrint")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Armoury Thread
local function armoury()
    CreateThread(function()
        while true do
            Wait(0)
            if inArmoury and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("nmsh-police:client:openArmoury")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Helicopter Thread
local function heli(zone)
    CreateThread(function()
        while true do
            Wait(0)
            if inHelicopter and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    if IsPedInAnyHeli(PlayerPedId()) then
                        TriggerEvent('nmsh-police:client:removeHelicopter')
                    else
                        TriggerEvent("nmsh-police:client:spawnHelicopter", zone)
                    end
                end
            else
                break
            end
        end
    end)
end

-- Police Impound Thread
local function impound()
    CreateThread(function()
        while true do
            Wait(0)
            if inImpound and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    if IsControlJustReleased(0, 38) then
                        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                        break
                    end
                end
            else
                break
            end
        end
    end)
end

-- Police Garage Thread
local function garage()
    CreateThread(function()
        while true do
            Wait(0)
            if inGarage and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    if IsControlJustReleased(0, 38) then
                        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                        break
                    end
                end
            else
                break
            end
        end
    end)
end

if Config.UseTarget then
    CreateThread(function()
        -- Toggle Duty
        for k, v in pairs(Config.Locations["duty"]) do
            exports['nmsh-target']:AddBoxZone("PoliceDuty_"..k, vector3(v.x, v.y, v.z), 1, 1, {
                name = "PoliceDuty_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "nmsh-policejob:ToggleDuty",
                        icon = "fas fa-sign-in-alt",
                        label = "Sign In",
                        jobType = 'leo',
                    },
                },
                distance = 1.5
            })
        end

        -- Personal Stash
        for k, v in pairs(Config.Locations["stash"]) do
            exports['nmsh-target']:AddBoxZone("PoliceStash_"..k, vector3(v.x, v.y, v.z), 1.5, 1.5, {
                name = "PoliceStash_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "nmsh-police:client:openStash",
                        icon = "fas fa-dungeon",
                        label = "Open Personal Stash",
                        jobType = "leo"
                    },
                },
                distance = 1.5
            })
        end

        -- Police Trash
        for k, v in pairs(Config.Locations["trash"]) do
            exports['nmsh-target']:AddBoxZone("PoliceTrash_"..k, vector3(v.x, v.y, v.z), 1, 1.75, {
                name = "PoliceTrash_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "nmsh-police:client:openTrash",
                        icon = "fas fa-trash",
                        label = "Open Trash",
                        jobType = "leo"
                    },
                },
                distance = 1.5
            })
        end

        -- Fingerprint
        for k, v in pairs(Config.Locations["fingerprint"]) do
            exports['nmsh-target']:AddBoxZone("PoliceFingerprint_"..k, vector3(v.x, v.y, v.z), 2, 1, {
                name = "PoliceFingerprint_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "nmsh-police:client:scanFingerPrint",
                        icon = "fas fa-fingerprint",
                        label = "Open Fingerprint",
                        jobType = "leo"
                    },
                },
                distance = 1.5
            })
        end

        -- Armoury
        for k, v in pairs(Config.Locations["armory"]) do
            exports['nmsh-target']:AddBoxZone("PoliceArmory_"..k, vector3(v.x, v.y, v.z), 5, 1, {
                name = "PoliceArmory_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "nmsh-police:client:openArmoury",
                        icon = "fas fa-swords",
                        label = "Open Armory",
                        jobType = "leo"
                    },
                },
                distance = 1.5
            })
        end

        for k, v in pairs(Config.Locations["evidence"]) do
            exports['nmsh-target']:AddBoxZone("PoliceEvidenceStash_"..k, vector3(v.x, v.y, v.z), 2, 2, {
                name = "PoliceEvidenceStash_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            }, {
                options = {
                    {
                        icon = 'fa-solid fa-folder-open',
                        label = "Open Evidence",
                        jobType = "leo",
                        action = function()
                            local currentEvidence = 0
                            local pos = GetEntityCoords(PlayerPedId())

                            for k, v in pairs(Config.Locations["evidence"]) do
                                if #(pos - v) < 2 then
                                    currentEvidence = k
                                end
                            end

                            exports['nmsh-menu']:openMenu({
                                {
                                    header = QBCore.Functions.GetPlayerData().job.label,
                                    icon = 'fa-solid fa-building-shield',
                                    isMenuHeader = true,
                                },
                                {
                                    header = Lang:t('menu.evd_drawer_h'),
                                    txt = Lang:t('menu.evd_drawer_b'),
                                    icon = 'fa-solid fa-list-ol',
                                    params = {
                                        event = 'police:client:EvidenceStashDrawer',
                                        args = {
                                            type = 'drawer',
                                            number = currentEvidence
                                        }
                                    }
                                },
                                {
                                    header = Lang:t('menu.evd_stash_h'),
                                    txt = Lang:t('menu.evd_stash_b'),
                                    icon = 'fa-solid fa-folder-closed',
                                    params = {
                                        event = 'police:client:EvidenceStashDrawer',
                                        args = {
                                            type = 'stash',
                                            number = currentEvidence
                                        }
                                    }
                                },
                            })
                        end,
                    },
                },
                distance = 1.5
            })
        end

        for k, v in pairs(Config.Locations["vehicle"]) do
            local hash = GetHashKey(Config.GaragePedModel)
            RequestModel(hash)
            while not HasModelLoaded(hash) do Wait(10) end
            GaragePed[k] = CreatePed(5, hash, vector3(v.x,v.y,v.z-1), v.w, false, false)
            FreezeEntityPosition(GaragePed[k], true)
            SetBlockingOfNonTemporaryEvents(GaragePed[k], true)
            SetEntityInvincible(GaragePed[k], true) --Don't let the ped die.
            TaskStartScenarioInPlace(GaragePed[k], "WORLD_HUMAN_CLIPBOARD", 0, true)
            exports['nmsh-target']:AddBoxZone("GaragePed"..k, vector3(v.x,v.y,v.z), 0.8, 0.6, {
                name = "GaragePed"..k, heading=v.w, debugPoly=false, minZ=v.z - 2, maxZ=v.z + 2,}, {
                options = {{
                    type = "client",
                    event = "police:client:VehicleMenuHeader",
                    label = Lang:t("menu.pol_garage"),
                    currentSelection = k,
                    icon = 'fas fa-car-on',
                    jobType = "leo"}},
                distance = 1.5,})
        end

        for k, v in pairs(Config.Locations["helicopter"]) do
            local helioptions = {}
            if Heli then
                helioptions = { label = Lang:t("menu.remove_heli"), icon = 'fas fa-helicopter', jobType = "leo",
                action = function()
                    TriggerEvent('nmsh-police:client:removeHelicopter')
                end,
            }
            else
                helioptions = { label = Lang:t("menu.spawn_heli"), icon = 'fas fa-helicopter', jobType = "leo",
                    action = function()
                        TriggerEvent('nmsh-police:client:spawnHelicopter', k)
                    end,
                }
            end
            local hash = GetHashKey(Config.GaragePedModel)
            RequestModel(hash)
            while not HasModelLoaded(hash) do Wait(10) end
            HeliPed[k] = CreatePed(5, hash, vector3(v.x,v.y,v.z-1), v.w, false, false)
            FreezeEntityPosition(HeliPed[k], true)
            SetBlockingOfNonTemporaryEvents(HeliPed[k], true)
            SetEntityInvincible(HeliPed[k], true) --Don't let the ped die.
            TaskStartScenarioInPlace(HeliPed[k], "WORLD_HUMAN_CLIPBOARD", 0, true)
            exports['nmsh-target']:AddBoxZone("HeliPed"..k, vector3(v.x,v.y,v.z), 0.8, 0.6, {
                name = "HeliPed"..k, heading=v.w, debugPoly=false, minZ=v.z - 2, maxZ=v.z + 2,}, {
                options = {
                    {
                        label = Lang:t("menu.spawn_heli"),
                        icon = 'fas fa-helicopter',
                        jobType = "leo",
                        canInteract = function()
                            if not Heli then return true end
                        end,
                        action = function()
                            TriggerEvent('nmsh-police:client:spawnHelicopter', k)
                        end,
                    },
                    {
                        label = Lang:t("menu.remove_heli"),
                        icon = 'fas fa-helicopter',
                        jobType = "leo",
                        canInteract = function()
                            if Heli then return true end
                        end,
                        action = function()
                            TriggerEvent('nmsh-police:client:removeHelicopter')
                        end,
                    }
                },
                distance = 1.5,
            })
        end

    end)

else

    -- Toggle Duty
    local dutyZones = {}
    for _, v in pairs(Config.Locations["duty"]) do
        dutyZones[#dutyZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 1.75, 1, {
            name="box_zone",
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local dutyCombo = ComboZone:Create(dutyZones, {name = "dutyCombo", debugPoly = false})
    dutyCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            dutylisten = true
            dutylistener()
        else
            dutylisten = false
            exports['qb-core']:HideText()
        end
    end)

    -- Personal Stash
    local stashZones = {}
    for _, v in pairs(Config.Locations["stash"]) do
        stashZones[#stashZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 1.5, 1.5, {
            name="box_zone",
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local stashCombo = ComboZone:Create(stashZones, {name = "stashCombo", debugPoly = false})
    stashCombo:onPlayerInOut(function(isPointInside, _, _)
        if isPointInside then
            inStash = true
            if PlayerJob.type == "leo" and PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.stash_enter'), 'left')
                stash()
            end
        else
            inStash = false
            exports['qb-core']:HideText()
        end
    end)

    -- Police Trash
    local trashZones = {}
    for _, v in pairs(Config.Locations["trash"]) do
        trashZones[#trashZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 1, 1.75, {
            name="box_zone",
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local trashCombo = ComboZone:Create(trashZones, {name = "trashCombo", debugPoly = false})
    trashCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inTrash = true
            if PlayerJob.type == "leo" and PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.trash_enter'),'left')
                trash()
            end
        else
            inTrash = false
            exports['qb-core']:HideText()
        end
    end)

    -- Fingerprints
    local fingerprintZones = {}
    for _, v in pairs(Config.Locations["fingerprint"]) do
        fingerprintZones[#fingerprintZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 2, 1, {
            name="box_zone",
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local fingerprintCombo = ComboZone:Create(fingerprintZones, {name = "fingerprintCombo", debugPoly = false})
    fingerprintCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inFingerprint = true
            if PlayerJob.type == "leo" and PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.scan_fingerprint'),'left')
                fingerprint()
            end
        else
            inFingerprint = false
            exports['qb-core']:HideText()
        end
    end)

    -- Armoury
    local armouryZones = {}
    for _, v in pairs(Config.Locations["armory"]) do
        armouryZones[#armouryZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 5, 1, {
            name="box_zone",
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local armouryCombo = ComboZone:Create(armouryZones, {name = "armouryCombo", debugPoly = false})
    armouryCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inArmoury = true
            if PlayerJob.type == "leo" and PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.enter_armory'),'left')
                armoury()
            end
        else
            inArmoury = false
            exports['qb-core']:HideText()
        end
    end)

    -- Evidence Storage
    local evidenceZones = {}
    for _, v in pairs(Config.Locations["evidence"]) do
        evidenceZones[#evidenceZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 2, 1, {
            name="box_zone",
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local evidenceCombo = ComboZone:Create(evidenceZones, {name = "evidenceCombo", debugPoly = false})
    evidenceCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            if PlayerJob.type == "leo" and PlayerJob.onduty then
                local currentEvidence = 0
                local pos = GetEntityCoords(PlayerPedId())

                for k, v in pairs(Config.Locations["evidence"]) do
                    if #(pos - v) < 2 then
                        currentEvidence = k
                    end
                end
                exports['nmsh-menu']:openMenu({
                    {header = QBCore.Functions.GetPlayerData().job.label, icon = 'fa-solid fa-building-shield', isMenuHeader = true},
                    { header = Lang:t('menu.evd_drawer_h'), txt = Lang:t('menu.evd_drawer_b'), icon = 'fa-solid fa-list-ol',
                        params = {
                            event = 'police:client:EvidenceStashDrawer',
                            args = {
                                type = 'drawer',
                                number = currentEvidence
                            }
                        }
                    },
                    { header = Lang:t('menu.evd_stash_h'), txt = Lang:t('menu.evd_stash_b'), icon = 'fa-solid fa-folder-closed',
                        params = {
                            event = 'police:client:EvidenceStashDrawer',
                            args = {
                                type = 'stash',
                                number = currentEvidence
                            }
                        }
                    },
                })
            end
        else
            exports['nmsh-menu']:closeMenu()
        end
    end)

    -- Police Garage
    local garageZones = {}
    for _, v in pairs(Config.Locations["vehicle"]) do
        garageZones[#garageZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 3, 3, {
            name="box_zone",
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local garageCombo = ComboZone:Create(garageZones, {name = "garageCombo", debugPoly = false})
    garageCombo:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            inGarage = true
            if PlayerJob.name == 'police' and PlayerJob.onduty then
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    exports['qb-core']:DrawText(Lang:t('info.store_veh'), 'left')
            garage()
                else
                    local currentSelection = 0

                    for k, v in pairs(Config.Locations["vehicle"]) do
                        if #(point - vector3(v.x, v.y, v.z)) < 4 then
                            currentSelection = k
                        end
                    end
                    exports['nmsh-menu']:showHeader({
                        {
                            header = Lang:t('menu.pol_garage'),
                            params = {
                                event = 'police:client:VehicleMenuHeader',
                                args = {
                                    currentSelection = currentSelection,
                                }
                            }
                        }
                    })
                end
            end
        else
            inGarage = false
            exports['nmsh-menu']:closeMenu()
            exports['qb-core']:HideText()
        end
    end)

     -- Helicopter
    local helicopterZones = {}
    for k, v in pairs(Config.Locations["helispawn"]) do
        helicopterZones[#helicopterZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 10, 10, {
            name="box_zone",
            data = {zone = k},
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local helicopterCombo = ComboZone:Create(helicopterZones, {name = "helicopterCombo", debugPoly = false})
    helicopterCombo:onPlayerInOut(function(isPointInside, _, zone)
        if isPointInside then
            inHelicopter = true
            if PlayerJob.type == "leo" and PlayerJob.onduty then
                if IsPedInAnyHeli(PlayerPedId()) then
                    -- exports['qb-core']:HideText()
                    exports['qb-core']:DrawText(Lang:t('info.store_heli'), 'left')
                    heli()
                else
                    exports['qb-core']:DrawText(Lang:t('info.take_heli'), 'left')
                    heli(zone.data.zone)
                end
            end
        else
            inHelicopter = false
            exports['qb-core']:HideText()
        end
    end)

end

CreateThread(function()

    -- Police Impound
    local impoundZones = {}
    for _, v in pairs(Config.Locations["impound"]) do
        impoundZones[#impoundZones+1] = BoxZone:Create(
            vector3(v.x, v.y, v.z), 4, 4, {
            name="box_zone",
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
            heading = 180,
        })
    end

    local impoundCombo = ComboZone:Create(impoundZones, {name = "impoundCombo", debugPoly = false})
    impoundCombo:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            inImpound = true
            if PlayerJob.type == "leo" and PlayerJob.onduty then
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    exports['qb-core']:DrawText(Lang:t('info.impound_veh'), 'left')
                    impound()
                else
                    local currentSelection = 0

                    for k, v in pairs(Config.Locations["impound"]) do
                        if #(point - vector3(v.x, v.y, v.z)) < 4 then
                            currentSelection = k
                        end
                    end
                    exports['nmsh-menu']:showHeader({
                        {
                            header = Lang:t('menu.pol_impound'),
                            params = {
                                event = 'police:client:ImpoundMenuHeader',
                                args = {
                                    currentSelection = currentSelection,
                                }
                            }
                        }
                    })
                end
            end
        else
            inImpound = false
            exports['nmsh-menu']:closeMenu()
            exports['qb-core']:HideText()
        end
    end)
end)


RegisterCommand('liverymenu', function()
    if not PlayerJob.type == "leo" then QBCore.Functions.Notify("You can't use this menu..", "error") return end
    local vehicle = nil
	if IsPedInAnyVehicle(PlayerPedId(), false) then	
        vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        syncVehicle(vehicle)
    else
        QBCore.Functions.Notify("You need to be in a car!", "error")
        return
    end
    LiveryMenu = {}
    LiveryMenu[#LiveryMenu+1] = {header = "Livery Menu", txt = "", isMenuHeader = true }
    LiveryMenu[#LiveryMenu+1] = {header = "Change Liveries", txt = "Change your vehicle liveries", params= {event = 'policejob:client:VehicleLiveryMenu', args = {vehicle = vehicle}}}
    LiveryMenu[#LiveryMenu+1] = {header = "Change Extras", txt = "Change your vehicle extras", params= {event = 'policejob:client:VehicleExtrasMenu', args = {vehicle = vehicle}}}
    exports['nmsh-menu']:openMenu(LiveryMenu)
end)

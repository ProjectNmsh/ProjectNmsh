local QBCore = exports['qb-core']:GetCoreObject()

local dutyTable = {}

Citizen.CreateThread(function()
    while true do
        local sendTable = {}
        for k, v in pairs(dutyTable) do
            local coords = GetEntityCoords(GetPlayerPed(k))
            local tempVar = v
            tempVar.playerId = k
            tempVar.coords = coords

            table.insert(sendTable, tempVar)
        end
        for player, kekw in pairs(dutyTable) do
            TriggerClientEvent('nmsh-pdblips:receiveData', player, player, sendTable)
        end
        Citizen.Wait(1000)
    end
end)

RegisterNetEvent('nmsh-pdblips:setDuty')
AddEventHandler('nmsh-pdblips:setDuty', function(onDuty)
    local src = source

    if onDuty then
        local Player = QBCore.Functions.GetPlayer(src)
        local playerJob =  Player.PlayerData.job

        if Config.emergencyJobs[playerJob.name] then

            dutyTable[src] = {
                job = playerJob.name,
                name = '['..Player.PlayerData.metadata.callsign..'] '.. Player.PlayerData.charinfo.firstname,
                callsign = Player.PlayerData.metadata.callsign,
            }
            
            log('Setting on duty '..GetPlayerName(src))
        end
    else
        if dutyTable[src] then
            log(src..' Setting off-duty')
            dutyTable[src] = nil
            for k, v in pairs(dutyTable) do
                TriggerClientEvent('nmsh-pdblips:removeUser', k, src)
            end
        else
            log(src..' Tried to set off duty when off duty, wth')
        end
    end
end)

RegisterNetEvent('nmsh-pdblips:enteredVeh')
AddEventHandler('nmsh-pdblips:enteredVeh', function(vehCfg)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local playerJob = Player.PlayerData.job
    dutyTable[src].inVeh = true
    dutyTable[src].vehSprite = vehCfg and vehCfg.sprite or Config.emergencyJobs[playerJob.name].vehBlip['default'].sprite or Config.emergencyJobs[playerJob.name].blip.sprite
    dutyTable[src].vehColor = vehCfg and vehCfg.color or Config.emergencyJobs[playerJob.name].vehBlip['default'].color or Config.emergencyJobs[playerJob.name].blip.color
end)

RegisterNetEvent('nmsh-pdblips:leftVeh')
AddEventHandler('nmsh-pdblips:leftVeh', function()
    local src = source
    dutyTable[src].inVeh = nil
    dutyTable[src].vehSprite = nil
    dutyTable[src].vehColor = nil
end)

RegisterNetEvent('nmsh-pdblips:toggleSiren')
AddEventHandler('nmsh-pdblips:toggleSiren', function(isOn)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local playerJob = Player.PlayerData.job
    if isOn then
        dutyTable[src].siren = true
        dutyTable[src].flashColors = Config.emergencyJobs[playerJob.name].blip.flashColors or {Config.emergencyJobs[playerJob.name].blip.color}
    else
        dutyTable[src].siren = false
        dutyTable[src].flashColors = nil
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if dutyTable[src] then
        dutyTable[src] = nil
        for k, v in pairs(dutyTable) do
            TriggerClientEvent('nmsh-pdblips:removeUser', k, src)
        end
    end
end)

function log(...)
    if Config.prints then
        print('^3[nmsh-pdblips]^0', ...)
    end
end
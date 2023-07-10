local QBCore = exports['qb-core']:GetCoreObject()
local ply = QBCore.Functions.GetPlayerData()
CreateThread(function()
    while true do
        Wait(Config.time * 60 * 1000)
        if ply.job.name == "police" and ply.job.onduty then
            TriggerServerEvent('core-policepoints:server:addpoints', Config.points)
        end
    end
end)
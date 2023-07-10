if Config.Framework == 'esx' then
    Core = exports['es_extended']:getSharedObject()

    Core.RegisterServerCallback("uniq-deathscreen:server:removeMoney", function(source, cb)
        local xPlayer = Core.GetPlayerFromId(source)

        xPlayer.removeMoney(Config.PriceForDead)
    end)

    GetPlayer = function (pId)
        return Core.GetPlayerFromId(pId)
    end

    GetPlayerRPName = function (pId)
        return Core.GetPlayerFromId(pId).name
    end
elseif Config.Framework == 'qbcore' then
    Core = exports['qb-core']:GetCoreObject()

    Core.Functions.CreateCallback("uniq-deathscreen:server:removeMoney", function(source, cb)
        local Player = Core.Functions.GetPlayer(source)

        Player.Functions.RemoveMoney("cash", Config.PriceForDead)
    end)

    RegisterNetEvent('hospital:server:SetLaststandStatus')
    AddEventHandler('hospital:server:SetLaststandStatus', function(isDead)
        TriggerClientEvent('uniq-deathscreen:client:onPlayerDeath', source, isDead)
    end)

    GetPlayer = function (pId)
        return Core.Functions.GetPlayer(pId)
    end

    GetPlayerRPName = function (pId)
        return Core.Functions.GetPlayer(pId).PlayerData.charinfo.firstname .. ' ' .. Core.Functions.GetPlayer(pId).PlayerData.charinfo.lastname
    end
end

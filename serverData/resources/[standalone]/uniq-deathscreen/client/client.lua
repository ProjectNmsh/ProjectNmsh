RegisterNetEvent('uniq-deathscreen:client:onPlayerDeath')
AddEventHandler('uniq-deathscreen:client:onPlayerDeath', function(isDead)
    if isDead then
        local killername = nil
        TriggerEvent('uniq-deathscreen:client:setDeathStatus', true)
        SendNUIMessage({type = "show", status = true})
        SetNuiFocus(true, true)

        local PedKiller = GetPedSourceOfDeath(PlayerPedId())
        local killerid = NetworkGetPlayerIndexFromPed(PedKiller)

        if IsEntityAVehicle(PedKiller) and IsEntityAPed(GetVehiclePedIsIn(PedKiller, -1)) and IsPedAPlayer(GetPedInVehicleSeat(PedKiller, -1)) then
            killerid = NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(PedKiller, -1))
        end

        if (killerid == -1) then
            killername = Config.Translation.Suicide
        elseif (killerid == nil) then
            killername = Config.Translation.Unknown
        elseif (killerid ~= -1) then

            if Config.UseRPName then
                TriggerServerEvent('uniq-deathscreen:server:getRPName', GetPlayerServerId(killerid))
            else
                killername = GetPlayerName(killerid)
            end
        end

        SendNUIMessage({type = 'setUPValues', killer = killername, timer = Config.Timer})
    end
end)

RegisterNetEvent('uniq-deathscreen:client:getRPName')
AddEventHandler('uniq-deathscreen:client:getRPName', function(name)
    SendNUIMessage({type = 'setUPValues', killer = name, timer = Config.Timer})
end)

RegisterNetEvent('uniq-deathscreen:client:hide_ui')
AddEventHandler('uniq-deathscreen:client:hide_ui', function()
    SendNUIMessage({type = "show", status = false})
    SetNuiFocus(false, false)
end)

RegisterNuiCallback("accept_to_die", function(data)
    SendNUIMessage({type = "show", status = false})
    SetNuiFocus(false, false)
    TriggerEvent('uniq-deathscreen:client:remove_revive')
    if Config.Framework == 'esx' then
        Core.TriggerServerCallback("uniq-deathscreen:server:removeMoney")
        Core.ShowNotification((Config.Translation.MoneyRemoved):format(Config.PriceForDead))
    elseif Config.Framework == 'qbcore' then
        Core.Functions.TriggerCallback("uniq-deathscreen:server:removeMoney")
        Core.Functions.Notify((Config.Translation.MoneyRemoved):format(Config.PriceForDead), 'primary', 5000)
    end
end)

RegisterNuiCallback("call_emergency", function(data)
    SendDistressSignal()
end)

RegisterNuiCallback("time_expired", function(data)
    SetNuiFocus(false, false)
    TriggerEvent('uniq-deathscreen:client:remove_revive')
end)


RegisterNuiCallback("call_ai_doc", function(data)
    TriggerServerEvent("hh_aidoc:hhfw:callHelp")
    print("NUI Callback triggered") -- Add this line for debugging
end)
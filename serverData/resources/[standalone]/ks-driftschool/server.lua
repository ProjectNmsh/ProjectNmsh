RegisterServerEvent('np-driftschool:takemoney')
AddEventHandler('np-driftschool:takemoney', function(data)
    local src = source
    local user = QBCore.Functions.GetPlayer(src)
    local money = user.Functions.GetMoney('bank')
    local price = data
	if money >= data then
        --user:removeMoney(data)
        user.Functions.RemoveMoney('bank', data, "Repair")
        --exports['ks-pank']:removeAccountMoney(Player.PlayerData, data, "Vehicle Repair")
        TriggerClientEvent('np-driftschool:tookmoney', src, true)
    else
        --TriggerClientEvent('DoLongHudText', src, 'You dont have enough money to do that little bitch.', 2)
        QBCore.Functions.Notify('You dont have enough money')
    end
end)



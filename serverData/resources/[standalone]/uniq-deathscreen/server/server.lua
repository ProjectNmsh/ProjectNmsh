RegisterNetEvent('uniq-deathscreen:server:getRPName')
AddEventHandler('uniq-deathscreen:server:getRPName', function(killerid)
    local Player = GetPlayer(killerid)
    if Player == nil then return end
    TriggerClientEvent('uniq-deathscreen:client:getRPName', source, GetPlayerRPName(killerid))
end)

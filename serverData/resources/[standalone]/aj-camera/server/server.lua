local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateUseableItem("camera", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("aj-camera:client:PlaceCamera", source)
    end
end)

RegisterNetEvent('aj-camera:server:GiveCamBack', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.AddItem('camera', 1)
end)
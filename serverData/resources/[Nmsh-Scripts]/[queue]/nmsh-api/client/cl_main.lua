triggered = false;

-- Events

AddEventHandler("playerSpawned", function()
    if not triggered then 
        triggered = true;
        Wait((1000 * 20)); -- Wait 20 seconds
        TriggerServerEvent('nmsh-api/server/player-loaded');
    end
end)
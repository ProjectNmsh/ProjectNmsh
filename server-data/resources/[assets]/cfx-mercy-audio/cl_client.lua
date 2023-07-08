local Timeout = false

Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do Citizen.Wait(100) end
    Citizen.SetTimeout(10000, function() Timeout = true end)
    while not RequestScriptAudioBank('dlc_nikez_sounds/general', 0) and not Timeout do
        Citizen.Wait(0)
    end
end)
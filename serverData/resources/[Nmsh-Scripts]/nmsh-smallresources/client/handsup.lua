local animDict = "missminuteman_1ig_2"
local anim = "handsup_base"
local handsup = false

RegisterCommand(Config.HandsUp.command, function()
    local ped = PlayerPedId()
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(10)
        end
    end
    handsup = not handsup
    if exports['nmsh-policejob']:IsHandcuffed() then return end
    if handsup then
        TaskPlayAnim(ped, animDict, anim, 8.0, 8.0, -1, 50, 0, false, false, false)
        exports['nmsh-smallresources']:addDisableControls(Config.disableHandsupControls)
    else
        ClearPedTasks(ped)
        exports['nmsh-smallresources']:removeDisableControls(Config.disableHandsupControls)
    end
end, false)

RegisterKeyMapping(Config.HandsUp.command, 'Hands Up', 'keyboard', Config.HandsUp.keybind)
exports('getHandsup', function() return handsup end)

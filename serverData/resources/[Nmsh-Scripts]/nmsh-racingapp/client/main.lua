-----------------------
----   Variables   ----
-----------------------
local QBCore = exports['qb-core']:GetCoreObject()

local Players = {}
local Countdown = 10
local ToFarCountdown = 10
local FinishedUITimeout = false
local useDebug = Config.Debug
local creatorObjectLeft, creatorObjectRight
local creatorCheckpointObject
local start
local RaceData = {
    InCreator = false,
    InRace = false,
    ClosestCheckpoint = 0
}

local LastCheckPointDeleted = nil
local PreCheckpoints = {}
local PostCheckpoints = {}
local NewCheckpoint = {}

local EditingCheckpoint = false
local CreatorData = {
    RaceName = nil,
    RacerName = nil,
    Checkpoints = {},
    TireDistance = 3.0,
    ConfirmDelete = false,
    IsEdit = false,
    RaceId = nil
}

local CurrentRaceData = {
    RaceId = nil,
    RaceName = nil,
    RacerName = nil,
    MaxClass = nil,
    Checkpoints = {},
    Started = false,
    CurrentCheckpoint = nil,
    TotalLaps = 0,
    TotalRacers = 0,
    Lap = 0,
    Position = 0,
    Ghosted = false,
}

local Classes = exports['nmsh-performance']:getPerformanceClasses()
local Entities = {}

-- for debug
local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

-----------------------
----   Functions   ----
-----------------------

local function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(10)
    end
end

local function cleanupObjects()
    DeleteObject(creatorObjectLeft)
    DeleteObject(creatorObjectRight)
    creatorObjectLeft, creatorObjectRight = nil, nil
end

local function DeleteClosestObject(coords, model)
    local Obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, model, 0, 0, 0)
    DeleteObject(Obj)
    ClearAreaOfObjects(coords.x, coords.y, coords.z, 50.0, 0)
end

local function CreatePile(offset, model)
    LoadModel(model)
    local Obj = CreateObject(model, offset.x, offset.y, offset.z, 0, 0, 0) -- CHANGE ONE OF THESE TO MAKE NETWORKED???
    PlaceObjectOnGroundProperly(Obj)
    FreezeEntityPosition(Obj, 1)
    SetEntityAsMissionEntity(Obj, 1, 1)
    SetEntityCollision(Obj, false, true)
    SetEntityCanBeDamaged(Obj, false)
    SetEntityInvincible(Obj, true)

    return Obj
end

local function GhostPlayers()
    CreateGhostLoop()
end

local function UnGhostPlayer()
    if useDebug then
        print('DE GHOSTED')
     end
    CurrentRaceData.Ghosted = false
    SetGhostedEntityAlpha(254)
    SetLocalPlayerAsGhost(false)
end

local function GhostPlayer()
    if useDebug then
        print('GHOSTED')
     end
    CurrentRaceData.Ghosted = true
    SetGhostedEntityAlpha(254)
    SetLocalPlayerAsGhost(true)
end

local function isFinishOrStart(CurrentRaceData, checkpoint)
    if CurrentRaceData.TotalLaps == 0 then
        if checkpoint == 1 or checkpoint == #CurrentRaceData.Checkpoints then
            return true
        else 
            return false
        end
    else
        if checkpoint == 1 then
            return true
        else 
            return false
        end  
    end
end

local function AddPointToGpsRoute(cx, cy, offset)
    local x = cx
    local y = cy
    if Config.DoOffsetGps then
        x = (x + offset.right.x) / 2;
        y = (y + offset.right.y) / 2;
    end
    AddPointToGpsMultiRoute(x,y)
end

local function clearBlips()
    for i,v in pairs(CurrentRaceData.Checkpoints) do
        
    end
end

local function doGPSForRace(started)
    DeleteAllCheckpoints()
    ClearGpsMultiRoute()
    StartGpsMultiRoute(6, started , false)
    for k, v in pairs(CurrentRaceData.Checkpoints) do
        AddPointToGpsRoute(CurrentRaceData.Checkpoints[k].coords.x,CurrentRaceData.Checkpoints[k].coords.y, v.offset)
        if started then
            if isFinishOrStart(CurrentRaceData,k) then
                CurrentRaceData.Checkpoints[k].pileleft = CreatePile(v.offset.left, Config.StartAndFinishModel)
                CurrentRaceData.Checkpoints[k].pileright = CreatePile(v.offset.right, Config.StartAndFinishModel)
            else
                CurrentRaceData.Checkpoints[k].pileleft = CreatePile(v.offset.left, Config.CheckpointPileModel)
                CurrentRaceData.Checkpoints[k].pileright = CreatePile(v.offset.right, Config.CheckpointPileModel)
            end
        end
        CurrentRaceData.Checkpoints[k].blip = CreateCheckpointBlip(v.coords, k)
    end
    if CurrentRaceData.TotalLaps > 0 then 
        for k=1, CurrentRaceData.TotalLanmsh-1, 1 do
            for k=1, #CurrentRaceData.Checkpoints, 1 do
                AddPointToGpsRoute(CurrentRaceData.Checkpoints[k].coords.x,CurrentRaceData.Checkpoints[k].coords.y, CurrentRaceData.Checkpoints[k].offset)
            end
        end
        AddPointToGpsRoute(CurrentRaceData.Checkpoints[1].coords.x,CurrentRaceData.Checkpoints[1].coords.y,  CurrentRaceData.Checkpoints[1].offset)
    end
    SetGpsMultiRouteRender(true)
end

function DeleteAllCheckpoints()
    for k, v in pairs(CreatorData.Checkpoints) do
        local CurrentCheckpoint = CreatorData.Checkpoints[k]

        if CurrentCheckpoint then
            local LeftPile = CurrentCheckpoint.pileleft
            local RightPile = CurrentCheckpoint.pileright

            if LeftPile then
                DeleteClosestObject(CurrentCheckpoint.offset.left, Config.StartAndFinishModel)
                DeleteClosestObject(CurrentCheckpoint.offset.left, Config.CheckpointPileModel)
                LeftPile = nil
            end
            if RightPile then
                DeleteClosestObject(CurrentCheckpoint.offset.right, Config.StartAndFinishModel)
                DeleteClosestObject(CurrentCheckpoint.offset.right, Config.CheckpointPileModel)
                RightPile = nil
            end
            local Blip = CurrentCheckpoint.blip
            if Blip then
                RemoveBlip(Blip)
                Blip = nil
            end
        end
    end

    for k, v in pairs(CurrentRaceData.Checkpoints) do
        local CurrentCheckpoint = CurrentRaceData.Checkpoints[k]

        if CurrentCheckpoint then
            local LeftPile = CurrentCheckpoint.pileleft
            local RightPile = CurrentCheckpoint.pileright

            if LeftPile then
                DeleteClosestObject(CurrentRaceData.Checkpoints[k].offset.left, Config.StartAndFinishModel)
                DeleteClosestObject(CurrentRaceData.Checkpoints[k].offset.left, Config.CheckpointPileModel)
                LeftPile = nil
            end

            if RightPile then
                DeleteClosestObject(CurrentRaceData.Checkpoints[k].offset.right, Config.StartAndFinishModel)
                DeleteClosestObject(CurrentRaceData.Checkpoints[k].offset.right, Config.CheckpointPileModel)
                RightPile = nil
            end
            local Blip = CurrentCheckpoint.blip
            if Blip then
                RemoveBlip(Blip)
                Blip = nil
            end
        end
    end
end

local function DeleteCheckpoint()
    local NewCheckpoints = {}
    if RaceData.ClosestCheckpoint ~= 0 then
        local ClosestCheckpoint = CreatorData.Checkpoints[RaceData.ClosestCheckpoint]
        if useDebug then
           print('deleting checkpoint', dump(ClosestCheckpoint))
        end

        if ClosestCheckpoint then
            local Blip = ClosestCheckpoint.blip
            if Blip then
                RemoveBlip(Blip)
                Blip = nil
            end

            local PileLeft = ClosestCheckpoint.pileleft
            if PileLeft then
                DeleteClosestObject(ClosestCheckpoint.offset.left, Config.StartAndFinishModel)
                DeleteClosestObject(ClosestCheckpoint.offset.left, Config.CheckpointPileModel)
                PileLeft = nil
            end

            local PileRight = ClosestCheckpoint.pileright
            if PileRight then
                DeleteClosestObject(ClosestCheckpoint.offset.right, Config.StartAndFinishModel)
                DeleteClosestObject(ClosestCheckpoint.offset.right, Config.CheckpointPileModel)
                PileRight = nil
            end

            for id, data in pairs(CreatorData.Checkpoints) do
                if id ~= RaceData.ClosestCheckpoint then
                    NewCheckpoints[#NewCheckpoints + 1] = data
                end
            end
            CreatorData.Checkpoints = NewCheckpoints
        else
            QBCore.Functions.Notify(Lang:t("error.slow_down"), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t("error.slow_down"), 'error')
    end
end

function DeleteCreatorCheckpoints()
    for id, _ in pairs(CreatorData.Checkpoints) do
        local CurrentCheckpoint = CreatorData.Checkpoints[id]

        local Blip = CurrentCheckpoint.blip
        if Blip then
            RemoveBlip(Blip)
            Blip = nil
        end

        if CurrentCheckpoint then
            local PileLeft = CurrentCheckpoint.pileleft
            if PileLeft then
                DeleteClosestObject(CurrentCheckpoint.offset.left, Config.CheckpointPileModel)
                DeleteClosestObject(CurrentCheckpoint.offset.left, Config.StartAndFinishModel)
                PileLeft = nil
            end

            local PileRight = CurrentCheckpoint.pileright
            if PileRight then
                DeleteClosestObject(CurrentCheckpoint.offset.right, Config.CheckpointPileModel)
                DeleteClosestObject(CurrentCheckpoint.offset.right, Config.StartAndFinishModel)
                PileRight = nil
            end
        end
    end
end

function SetupPiles()
    for k, v in pairs(CreatorData.Checkpoints) do
        if not CreatorData.Checkpoints[k].pileleft then
            CreatorData.Checkpoints[k].pileleft = CreatePile(v.offset.left, Config.CheckpointPileModel)
        end

        if not CreatorData.Checkpoints[k].pileright then
            CreatorData.Checkpoints[k].pileright = CreatePile(v.offset.right, Config.CheckpointPileModel)
        end
    end
end

function SaveRace()
    local RaceDistance = 0

    for k, v in pairs(CreatorData.Checkpoints) do
        if k + 1 <= #CreatorData.Checkpoints then
            local checkpointdistance = #(vector3(v.coords.x, v.coords.y, v.coords.z) -
                                           vector3(CreatorData.Checkpoints[k + 1].coords.x,
                    CreatorData.Checkpoints[k + 1].coords.y, CreatorData.Checkpoints[k + 1].coords.z))
            RaceDistance = RaceDistance + checkpointdistance
        end
    end

    CreatorData.RaceDistance = RaceDistance
    TriggerServerEvent('nmsh-racingapp:server:SaveRace', CreatorData)
    Lang:t("error.slow_down")
    QBCore.Functions.Notify(Lang:t("success.race_saved") .. '(' .. CreatorData.RaceName .. ')', 'success')

    DeleteCreatorCheckpoints()
    cleanupObjects()

    RaceData.InCreator = false
    CreatorData.RaceName = nil
    CreatorData.RacerName = nil
    CreatorData.Checkpoints = {}
    CreatorData.IsEdit = false
    CreatorData.RaceId = nil
end

function GetClosestCheckpoint()
    local pos = GetEntityCoords(PlayerPedId(), true)
    local current = nil
    local dist = nil
    for id, _ in pairs(CreatorData.Checkpoints) do
        if current ~= nil then
            if #(pos -
                vector3(CreatorData.Checkpoints[id].coords.x, CreatorData.Checkpoints[id].coords.y,
                    CreatorData.Checkpoints[id].coords.z)) < dist then
                current = id
                dist = #(pos -
                           vector3(CreatorData.Checkpoints[id].coords.x, CreatorData.Checkpoints[id].coords.y,
                        CreatorData.Checkpoints[id].coords.z))
            end
        else
            dist = #(pos -
                       vector3(CreatorData.Checkpoints[id].coords.x, CreatorData.Checkpoints[id].coords.y,
                    CreatorData.Checkpoints[id].coords.z))
            current = id
        end
    end
    RaceData.ClosestCheckpoint = current
end

function CreatorUI()
    CreateThread(function()
        while true do
            if RaceData.InCreator then
                SendNUIMessage({
                    action = "Update",
                    type = "creator",
                    data = CreatorData,
                    racedata = RaceData,
                    active = true
                })
            else
                SendNUIMessage({
                    action = "Update",
                    type = "creator",
                    data = CreatorData,
                    racedata = RaceData,
                    active = false
                })
                break
            end
            Wait(200)
        end
    end)
end


function CreateCheckpointBlip(coords, id)
    local Blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(Blip, 1)
    SetBlipDisplay(Blip, 4)
    SetBlipScale(Blip, Config.Blips.Generic.Size)
    SetBlipAsShortRange(Blip, true)
    SetBlipColour(Blip, Config.Blips.Generic.Color)
    ShowNumberOnBlip(Blip, id)
    SetBlipShowCone(Blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Checkpoint: " .. id)
    EndTextCommandSetBlipName(Blip)

    return Blip
end

local function redrawBlips()
    for id, CheckpointData in pairs(CreatorData.Checkpoints) do
        RemoveBlip(CheckpointData.blip)
        CheckpointData.blip = CreateCheckpointBlip(CheckpointData.coords, id)
    end
end

local function AddCheckpoint(checkpointId)
    local PlayerPed = PlayerPedId()
    local PlayerPos = GetEntityCoords(PlayerPed)
    local PlayerVeh = GetVehiclePedIsIn(PlayerPed)
    local Offset = {
        left = {
            x = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).x,
            y = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).y,
            z = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).z
        },
        right = {
            x = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).x,
            y = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).y,
            z = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).z
        }
    }
    if checkpointId ~= nil then
        RemoveBlip(tonumber(CreatorData.Checkpoints[tonumber(checkpointId)].blip))
        local PileLeft = CreatorData.Checkpoints[tonumber(checkpointId)].pileleft
        if PileLeft then
            DeleteClosestObject(CreatorData.Checkpoints[tonumber(checkpointId)].offset.left, Config.StartAndFinishModel)
            DeleteClosestObject(CreatorData.Checkpoints[tonumber(checkpointId)].offset.left, Config.CheckpointPileModel)
            PileLeft = nil
        end

        local PileRight = CreatorData.Checkpoints[tonumber(checkpointId)].pileright
        if PileRight then
            DeleteClosestObject(CreatorData.Checkpoints[tonumber(checkpointId)].offset.right, Config.StartAndFinishModel)
            DeleteClosestObject(CreatorData.Checkpoints[tonumber(checkpointId)].offset.right, Config.CheckpointPileModel)
            PileRight = nil
        end

        CreatorData.Checkpoints[tonumber(checkpointId)] = {
            coords = {
                x = PlayerPos.x,
                y = PlayerPos.y,
                z = PlayerPos.z
            },
            offset = Offset
        }
    else
        CreatorData.Checkpoints[#CreatorData.Checkpoints + 1] = {
            coords = {
                x = PlayerPos.x,
                y = PlayerPos.y,
                z = PlayerPos.z
            },
            offset = Offset
        }
    end

    redrawBlips()
end


local function MoveCheckpoint()
    local dialog = exports['nmsh-input']:ShowInput({
        header = Lang:t("menu.edit_checkpoint_header"),
        submitText = Lang:t("menu.confirm"),
        inputs = {
            {
                text = "Checkpoint number", -- text you want to be displayed as a place holder
                name = "number", -- name of the input should be unique otherwise it might override
                type = "number", -- type of the input - number will not allow non-number characters in the field so only accepts 0-9
                isRequired = true, -- Optional [accepted values: true | false] but will submit the form if no value is inputted
            },
        },
    })
    if dialog ~= nil then
        if useDebug then
            print('Moving checkpoint', dialog.number)
         end
        AddCheckpoint(dialog.number)
    end
end

function CreatorLoop()
    redrawBlips()
    CreateThread(function()
        while RaceData.InCreator do
            local PlayerPed = PlayerPedId()
            local PlayerVeh = GetVehiclePedIsIn(PlayerPed)

            if PlayerVeh ~= 0 then
                if IsControlJustPressed(0, 161) or IsDisabledControlJustPressed(0, 161) then
                    AddCheckpoint()
                end

                if IsControlJustPressed(0, 162) or IsDisabledControlJustPressed(0, 162) then
                    if CreatorData.Checkpoints and next(CreatorData.Checkpoints) then
                        DeleteCheckpoint()
                    else
                        QBCore.Functions.Notify(Lang:t("error.no_checkpoints_to_delete"), 'error')
                    end
                end

                if IsControlJustPressed(0, 159) or IsDisabledControlJustPressed(0, 159) then
                    print('hehe')
                    if CreatorData.Checkpoints and next(CreatorData.Checkpoints) then
                        MoveCheckpoint()
                    else
                        QBCore.Functions.Notify(Lang:t("error.no_checkpoints_to_edit"), 'error')
                    end
                end

                if IsControlJustPressed(0, 311) or IsDisabledControlJustPressed(0, 311) then
                    if CreatorData.Checkpoints and #CreatorData.Checkpoints >= Config.MinimumCheckpoints then
                        SaveRace()
                    else
                        QBCore.Functions.Notify(Lang:t("error.not_enough_checkpoints") .. '(' ..Config.MinimumCheckpoints .. ')', 'error')
                    end
                end

                if IsControlJustPressed(0, 40) or IsDisabledControlJustPressed(0, 40) then
                    if CreatorData.TireDistance < Config.MaxTireDistance then
                        CreatorData.TireDistance = CreatorData.TireDistance + 1.0
                    else
                        QBCore.Functions.Notify(Lang:t("error.max_tire_distance") .. Config.MaxTireDistance)
                    end
                end

                if IsControlJustPressed(0, 39) or IsDisabledControlJustPressed(0, 39) then
                    if CreatorData.TireDistance > Config.MinTireDistance then
                        CreatorData.TireDistance = CreatorData.TireDistance - 1.0
                    else
                        QBCore.Functions.Notify(Lang:t("error.min_tire_distance") .. Config.MinTireDistance)
                    end
                end
            else
                local coords = GetEntityCoords(PlayerPedId())
                DrawText3Ds(coords.x, coords.y, coords.z, Lang:t("text.get_in_vehicle"))
            end

            if IsControlJustPressed(0, 163) or IsDisabledControlJustPressed(0, 163) then
                if not CreatorData.ConfirmDelete then
                    CreatorData.ConfirmDelete = true
                    QBCore.Functions.Notify(Lang:t("error.editor_confirm"), 'error')
                else
                    DeleteCreatorCheckpoints()

                    cleanupObjects()
                    RaceData.InCreator = false
                    CreatorData.RaceName = nil
                    CreatorData.Checkpoints = {}
                    QBCore.Functions.Notify(Lang:t("error.editor_canceled"), 'error')
                    CreatorData.ConfirmDelete = false
                end
            end
            Wait(0)
        end
    end)
end

local function playerIswithinDistance()
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)    
    local playerSource = GetPlayerServerId(GetPlayerIndex())
    if useDebug then
        print('You', ply, plyCoords.x..','..plyCoords.y)
    end
    for index,player in ipairs(Players) do
        local playerIdx = GetPlayerFromServerId(tonumber(player.id))
        local target = GetPlayerPed(playerIdx)
        local targetCoords = GetEntityCoords(target, 0)
        local distance = #(targetCoords.xy-plyCoords.xy)
        
        if useDebug then
           print('playeridx', playerIdx)
           print('target', target)
           print('comparing to player', ply, target)
           print(ply,target, 'is same:', ply == target)
           print('Target locations', targetCoords.x..','..targetCoords.y)
           print('distance', distance)
        end

        if distance > 0 and distance < Config.Ghosting.NearestDistanceLimit then
            return true
        end
    end  
    return false
end

local ghostLoopStart = 0

local function actuallyValidateTime(Timer)
    if Timer == 0 then
        if useDebug then
           print('Timer is off')
        end
        return true
    else
        if GetTimeDifference(GetGameTimer(), ghostLoopStart) < Timer then
            if useDebug then
               print('Timer has NOT been reached', GetTimeDifference(GetGameTimer(), ghostLoopStart) )
            end
            return true
        end
        if useDebug then
           print('Timer has been reached')
        end
        return false
    end
end

local function validateTime()
    if CurrentRaceData.Ghosting and CurrentRaceData.GhostingTime then
        return actuallyValidateTime(CurrentRaceData.GhostingTime)
    else
        return actuallyValidateTime(Config.Ghosting.Timer)
    end
end

function CreateGhostLoop()
    ghostLoopStart = GetGameTimer()
    if useDebug then
       print('non racers', dump(Players))
    end
    CreateThread(function()
        while true do
            if validateTime() then
                if CurrentRaceData.Checkpoints ~= nil and next(CurrentRaceData.Checkpoints) ~= nil then
                    if playerIswithinDistance() then
                        UnGhostPlayer()
                    else
                        GhostPlayer()
                    end
                else
                    break
                end
            else
                if useDebug then
                   print('Breaking due to time')
                end
                UnGhostPlayer()
                break
            end
            Wait(Config.Ghosting.DistanceLoopTime)
        end
    end)
end

local startTime = 0
local lapStartTime = 0

local function updateCountdown(value)
    SendNUIMessage({
        action = "Countdown",
        data = {
            value = value
        },
        active = true
    })
end

function RaceUI()
    CreateThread(function()
        while true do
            if CurrentRaceData.Checkpoints ~= nil and next(CurrentRaceData.Checkpoints) ~= nil then
                if CurrentRaceData.Started then
                    CurrentRaceData.RaceTime = GetTimeDifference(GetGameTimer(), lapStartTime)
                    CurrentRaceData.TotalTime = GetTimeDifference(GetGameTimer(), startTime)
                end
                SendNUIMessage({
                    action = "Update",
                    type = "race",
                    data = {
                        CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint,
                        TotalCheckpoints = #CurrentRaceData.Checkpoints,
                        TotalLaps = CurrentRaceData.TotalLaps,
                        CurrentLap = CurrentRaceData.Lap,
                        RaceStarted = CurrentRaceData.Started,
                        RaceName = CurrentRaceData.RaceName,
                        Time = CurrentRaceData.RaceTime,
                        TotalTime = CurrentRaceData.TotalTime,
                        BestLap = CurrentRaceData.BestLap,
                        Position = CurrentRaceData.Position,
                        Positions = CurrentRaceData.Positions,
                        TotalRacers = CurrentRaceData.TotalRacers,
                        Ghosted = CurrentRaceData.Ghosted,
                    },
                    racedata = RaceData,
                    active = true
                })
            else
                if not FinishedUITimeout then
                    FinishedUITimeout = true
                    SetTimeout(10000, function()
                        FinishedUITimeout = false
                        SendNUIMessage({
                            action = "Update",
                            type = "race",
                            data = {},
                            racedata = RaceData,
                            active = false
                        })
                    end)
                end
                break
            end
            Wait(12)
        end
    end)
end

local function SetupRace(RaceData, Laps)
    CurrentRaceData = {
        RaceId = RaceData.RaceId,
        Creator = RaceData.Creator,
        OrganizerCID = RaceData.OrganizerCID,
        RacerName = RaceData.RacerName,
        RaceName = RaceData.RaceName,
        Checkpoints = RaceData.Checkpoints,
        Ghosting = RaceData.Ghosting,
        GhostingTime = RaceData.GhostingTime,
        Started = false,
        CurrentCheckpoint = 1,
        TotalLaps = Laps,
        Lap = 1,
        RaceTime = 0,
        TotalTime = 0,
        BestLap = 0,
        MaxClass = RaceData.MaxClass,
        Racers = {},
        Position = 0
    }
    doGPSForRace()
    RaceUI()
end

local function showNonLoopParticle(dict, particleName, coords, scale, time)
    while not HasNamedPtfxAssetLoaded(dict) do
        RequestNamedPtfxAsset(dict)
        Wait(0)
    end

    UseParticleFxAssetNextCall(dict)

    local particleHandle = StartParticleFxLoopedAtCoord(particleName, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0,
    scale, false, false, false)
    SetParticleFxLoopedColour(particleHandle,0.0,0.0,1.0)
    return particleHandle
end

local function handleFlare (checkpoint)
    -- QBCore.Functions.Notify('Lighting '..checkpoint, 'success')

    local Size = 1.0
    local left = showNonLoopParticle('core', 'exp_grd_flare',
        CurrentRaceData.Checkpoints[checkpoint].offset.left, Size)
    local right = showNonLoopParticle('core', 'exp_grd_flare',
        CurrentRaceData.Checkpoints[checkpoint].offset.right, Size)

    SetTimeout(Config.FlareTime, function()
        StopParticleFxLooped(left, false)
        StopParticleFxLooped(right, false)
    end)
end


local function DoPilePfx()
    if CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1] ~= nil then
        handleFlare(CurrentRaceData.CurrentCheckpoint + 1)
    end
    if CurrentRaceData.CurrentCheckpoint == 1 then -- start
        if useDebug then
           print('start')
        end
        -- QBCore.Functions.Notify('Lighting start '..CurrentRaceData.CurrentCheckpoint, 'success')
        handleFlare(CurrentRaceData.CurrentCheckpoint)

    end
    if CurrentRaceData.TotalLaps > 0 and CurrentRaceData.CurrentCheckpoint == #CurrentRaceData.Checkpoints then -- finish
        if useDebug then
           print('finish')
        end
        --QBCore.Functions.Notify('Lighting finish/startline '..CurrentRaceData.CurrentCheckpoint + 1, 'success')
        handleFlare(1)
        if CurrentRaceData.Lap ~= CurrentRaceData.TotalLaps then
            if useDebug then
               print('not last lap')
            end
            handleFlare(2)
        end
    end
end

local function GetMaxDistance(OffsetCoords)
    local Distance = #(vector3(OffsetCoords.left.x, OffsetCoords.left.y, OffsetCoords.left.z) -
                         vector3(OffsetCoords.right.x, OffsetCoords.right.y, OffsetCoords.right.z))
    local Retval = 12.5
    if Distance > 20.0 then
        Retval = 18.5
    end
    return Retval
end

function MilliToTime(milli)
    local milliseconds = milli % 1000;
    milliseconds = tostring(milliseconds)
    local seconds = math.floor((milli / 1000) % 60);
    local minutes = math.floor((milli / (60 * 1000)) % 60);
    if minutes < 10 then
        minutes = "0"..tostring(minutes);
    else
        minutes = tostring(minutes)
    end
    if seconds < 10 then
        seconds = "0"..tostring(seconds);
    else
        seconds = tostring(seconds)
    end
    return minutes..":"..seconds.."."..milliseconds;
end

function DeleteCurrentRaceCheckpoints()
    for k, v in pairs(CurrentRaceData.Checkpoints) do
        local CurrentCheckpoint = CurrentRaceData.Checkpoints[k]
        local Blip = CurrentCheckpoint.blip
        if Blip then
            RemoveBlip(Blip)
            Blip = nil
        end

        local PileLeft = CurrentCheckpoint.pileleft
        if PileLeft then
            DeleteClosestObject(CurrentCheckpoint.offset.left, Config.StartAndFinishModel)
            DeleteClosestObject(CurrentCheckpoint.offset.left, Config.CheckpointPileModel)
            PileLeft = nil
        end

        local PileRight = CurrentCheckpoint.pileright
        if PileRight then
            DeleteClosestObject(CurrentCheckpoint.offset.right, Config.StartAndFinishModel)
            DeleteClosestObject(CurrentCheckpoint.offset.right, Config.CheckpointPileModel)
            PileRight = nil
        end
    end

    CurrentRaceData.RaceName = nil
    CurrentRaceData.Checkpoints = {}
    CurrentRaceData.Started = false
    CurrentRaceData.CurrentCheckpoint = 0
    CurrentRaceData.TotalLaps = 0
    CurrentRaceData.Lap = 0
    CurrentRaceData.RaceTime = 0
    CurrentRaceData.TotalTime = 0
    CurrentRaceData.BestLap = 0
    CurrentRaceData.RaceId = nil
    CurrentRaceData.RacerName = nil
    RaceData.InRace = false
end

-- local currentTotalTime = 0

-- CreateThread(function()
--     while true do
--         if CurrentRaceData.RaceName ~= nil then
--             if CurrentRaceData.Started then
--                 currentTotalTime = currentTotalTime+10;
--             end
--             Wait(10)
--         end
--         Wait(1000)
--     end
-- end)

function FinishRace()
    local PlayerPed = PlayerPedId()
    local info, class, perfRating, vehicleModel = exports['nmsh-performance']:getVehicleInfo(GetVehiclePedIsIn(PlayerPed, false))
    -- print('NEW TIME TEST', currentTotalTime, SecondsToClock(currentTotalTime))
    if useDebug then print('Best lap:', CurrentRaceData.BestLap, 'Total:', CurrentRaceData.TotalTime) end
    TriggerServerEvent('nmsh-racingapp:server:FinishPlayer', CurrentRaceData, CurrentRaceData.TotalTime,
        CurrentRaceData.TotalLaps, CurrentRaceData.BestLap, class, vehicleModel)
    QBCore.Functions.Notify(Lang:t("success.race_finished") .. MilliToTime(CurrentRaceData.TotalTime), 'success')
    if CurrentRaceData.BestLap ~= 0 then
        QBCore.Functions.Notify(Lang:t("success.race_best_lap") .. MilliToTime(CurrentRaceData.BestLap), 'success')
    end
    UnGhostPlayer()
    Players = {}
    ClearGpsMultiRoute()
    DeleteCurrentRaceCheckpoints()
end

function Info()
    local PlayerPed = PlayerPedId()
    local plyVeh = GetVehiclePedIsIn(PlayerPed, false)
    local IsDriver = GetPedInVehicleSeat(plyVeh, -1) == PlayerPed
    local returnValue = plyVeh ~= 0 and plyVeh ~= nil and IsDriver
    return returnValue, plyVeh
end

exports('IsInRace', IsInRace)
function IsInRace()
    local retval = false
    if RaceData.InRace then
        retval = true
    end
    return retval
end

exports('IsInEditor', IsInEditor)
function IsInEditor()
    local retval = false
    if RaceData.InCreator then
        retval = true
    end
    return retval
end

function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-----------------------
----   Threads     ----
-----------------------



CreateThread(function()
    while true do
        if RaceData.InCreator then
            GetClosestCheckpoint()
            SetupPiles()
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local Driver, plyVeh = Info()
        if Driver then
            if GetVehicleCurrentGear(plyVeh) < 3 and GetVehicleCurrentRpm(plyVeh) == 1.0 and
                math.ceil(GetEntitySpeed(plyVeh) * 2.236936) > 50 then
                while GetVehicleCurrentRpm(plyVeh) > 0.6 do
                    SetVehicleCurrentRpm(plyVeh, 0.3)
                    Wait(0)
                end
                Wait(800)
            end
        end
        Wait(500)
    end
end)

local function genericBlip(Blip)
    SetBlipScale(Blip, Config.Blips.Generic.Size)
    SetBlipColour(Blip, Config.Blips.Generic.Color)
end

local function nextBlip(Blip)
    SetBlipScale(Blip, Config.Blips.Next.Size)
    SetBlipColour(Blip, Config.Blips.Next.Color)
end

local function passedBlip(Blip)
    SetBlipScale(Blip, Config.Blips.Passed.Size)
    SetBlipColour(Blip, Config.Blips.Passed.Color)
end

local function resetBlips()
    for i, checkpoint in pairs(CurrentRaceData.Checkpoints) do
        genericBlip(checkpoint.blip)
    end
end

local timeWhenLastCheckpointWasPassed = 0
-- Racing

local function checkCheckPointTime()
    if GetTimeDifference(GetGameTimer(), timeWhenLastCheckpointWasPassed) > Config.KickTime then
        if useDebug then
           print('Getting kicked for idling')
        end
        TriggerServerEvent("nmsh-racingapp:server:LeaveRace", CurrentRaceData)
    end
end

CreateThread(function()
    while true do
        if CurrentRaceData.RaceName ~= nil then
            if CurrentRaceData.Started then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local cp = 0
                if CurrentRaceData.CurrentCheckpoint + 1 > #CurrentRaceData.Checkpoints then
                    cp = 1
                else
                    cp = CurrentRaceData.CurrentCheckpoint + 1
                end
                local data = CurrentRaceData.Checkpoints[cp]
                local CheckpointDistance = #(pos - vector3(data.coords.x, data.coords.y, data.coords.z))
                local MaxDistance = GetMaxDistance(CurrentRaceData.Checkpoints[cp].offset)
                if CheckpointDistance < MaxDistance then
                    if CurrentRaceData.TotalLaps == 0 then -- Sprint
                        if CurrentRaceData.CurrentCheckpoint + 1 < #CurrentRaceData.Checkpoints then
                            CurrentRaceData.CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint + 1
                            AddPointToGpsMultiRoute(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].coords.x,
                                CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].coords.y)
                            TriggerServerEvent('nmsh-racingapp:server:UpdateRacerData', CurrentRaceData.RaceId,
                                CurrentRaceData.CurrentCheckpoint, CurrentRaceData.Lap, false, CurrentRaceData.TotalTime)
                            DoPilePfx()
                            PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                            passedBlip(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint].blip)
                            nextBlip(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].blip)
                            timeWhenLastCheckpointWasPassed = GetGameTimer()
                        else
                            DoPilePfx()
                            PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                            CurrentRaceData.CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint + 1
                            TriggerServerEvent('nmsh-racingapp:server:UpdateRacerData', CurrentRaceData.RaceId,
                                CurrentRaceData.CurrentCheckpoint, CurrentRaceData.Lap, true, CurrentRaceData.TotalTime)
                            FinishRace()
                            timeWhenLastCheckpointWasPassed = GetGameTimer()
                        end
                    else -- Circuit
                        if CurrentRaceData.CurrentCheckpoint + 1 > #CurrentRaceData.Checkpoints then -- If new lap
                            if CurrentRaceData.Lap + 1 > CurrentRaceData.TotalLaps then -- if finish
                                DoPilePfx()
                                PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                                if CurrentRaceData.RaceTime < CurrentRaceData.BestLap then
                                    CurrentRaceData.BestLap = CurrentRaceData.RaceTime
                                    if useDebug then print('racetime less than bestlap', CurrentRaceData.RaceTime < CurrentRaceData.BestLap, CurrentRaceData.RaceTime, CurrentRaceData.BestLap) end
                                elseif CurrentRaceData.BestLap == 0 then
                                    if useDebug then print('bestlap == 0', CurrentRaceData.BestLap) end
                                    CurrentRaceData.BestLap = CurrentRaceData.RaceTime
                                end
                                CurrentRaceData.CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint + 1
                                TriggerServerEvent('nmsh-racingapp:server:UpdateRacerData', CurrentRaceData.RaceId,
                                    CurrentRaceData.CurrentCheckpoint, CurrentRaceData.Lap, true, CurrentRaceData.TotalTime)
                                FinishRace()
                                timeWhenLastCheckpointWasPassed = GetGameTimer()
                            else -- if next lap
                                DoPilePfx()
                                resetBlips()
                                PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                                if CurrentRaceData.RaceTime < CurrentRaceData.BestLap then
                                    if useDebug then print('racetime less than bestlap', CurrentRaceData.RaceTime < CurrentRaceData.BestLap, CurrentRaceData.RaceTime, CurrentRaceData.BestLap) end
                                    CurrentRaceData.BestLap = CurrentRaceData.RaceTime
                                elseif CurrentRaceData.BestLap == 0 then
                                    if useDebug then print('bestlap == 0', CurrentRaceData.BestLap) end
                                    CurrentRaceData.BestLap = CurrentRaceData.RaceTime
                                end
                                lapStartTime = GetGameTimer()
                                CurrentRaceData.Lap = CurrentRaceData.Lap + 1
                                CurrentRaceData.CurrentCheckpoint = 1
                                AddPointToGpsMultiRoute(
                                    CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].coords.x,
                                    CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].coords.y)
                                TriggerServerEvent('nmsh-racingapp:server:UpdateRacerData', CurrentRaceData.RaceId,
                                    CurrentRaceData.CurrentCheckpoint, CurrentRaceData.Lap, false, CurrentRaceData.TotalTime)
                                passedBlip(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint].blip)
                                nextBlip(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].blip)
                                timeWhenLastCheckpointWasPassed = GetGameTimer()
                            end
                        else -- if next checkpoint 
                            CurrentRaceData.CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint + 1
                            if CurrentRaceData.CurrentCheckpoint ~= #CurrentRaceData.Checkpoints then
                                AddPointToGpsMultiRoute(
                                    CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].coords.x,
                                    CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].coords.y)
                                TriggerServerEvent('nmsh-racingapp:server:UpdateRacerData', CurrentRaceData.RaceId,
                                    CurrentRaceData.CurrentCheckpoint, CurrentRaceData.Lap, false, CurrentRaceData.TotalTime)
                                    passedBlip(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint].blip)
                                    nextBlip(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].blip)
                            else
                                AddPointToGpsMultiRoute(CurrentRaceData.Checkpoints[1].coords.x,
                                    CurrentRaceData.Checkpoints[1].coords.y)
                                TriggerServerEvent('nmsh-racingapp:server:UpdateRacerData', CurrentRaceData.RaceId,
                                    CurrentRaceData.CurrentCheckpoint, CurrentRaceData.Lap, false, CurrentRaceData.TotalTime)
                                    passedBlip(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint].blip)
                                    nextBlip(CurrentRaceData.Checkpoints[1].blip)
                                timeWhenLastCheckpointWasPassed = GetGameTimer()

                            end
                            DoPilePfx()
                            PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                        end
                    end
                else
                    checkCheckPointTime()
                end
            else
                local data = CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint]
                DrawMarker(4, data.coords.x, data.coords.y, data.coords.z + 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.9, 1.5,
                    1.5, 255, 255, 255, 255, 0, 1, 0, 0, 0, 0, 0)
                    nextBlip(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint+1].blip)
            end
        else
            Wait(1000)
        end

        Wait(0)
    end
end)

-- Creator
CreateThread(function()
    while true do
        if RaceData.InCreator then
            local PlayerPed = PlayerPedId()
            local PlayerVeh = GetVehiclePedIsIn(PlayerPed)
            if creatorObjectLeft and creatorObjectRight ~= nil then
                cleanupObjects()
            end
            creatorCheckpointObject = Config.CheckpointPileModel

            if PlayerVeh ~= 0 then
                LoadModel(creatorCheckpointObject)
                local Offset = {
                    left = {
                        x = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).x,
                        y = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).y,
                        z = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).z
                    },
                    right = {
                        x = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).x,
                        y = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).y,
                        z = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).z
                    }
                }
                creatorObjectLeft = CreateObjectNoOffset(creatorCheckpointObject, Offset.left.x, Offset.left.y, Offset.left.z, false, false, false)
                creatorObjectRight = CreateObjectNoOffset(creatorCheckpointObject, Offset.right.x, Offset.right.y, Offset.right.z, false, false, false)
                PlaceObjectOnGroundProperly(creatorObjectLeft)
                PlaceObjectOnGroundProperly(creatorObjectRight)

                SetEntityCollision(creatorObjectLeft, false, false)
                SetEntityCollision(creatorObjectRight, false, false)
                SetModelAsNoLongerNeeded(creatorCheckpointObject)
            end
        end
        Wait(0)
    end
end)

-----------------------
---- Client Events ----
-----------------------

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        ClearGpsMultiRoute()
        DeleteAllCheckpoints()
    end
end)

RegisterNetEvent('nmsh-racingapp:client:ReadyJoinRace', function(RaceData)
    local PlayerPed = PlayerPedId()
    local PlayerIsInVehicle = IsPedInAnyVehicle(PlayerPed, false)

    local info, class, perfRating = '', '', ''
    if PlayerIsInVehicle then
        info, class, perfRating = exports['nmsh-performance']:getVehicleInfo(GetVehiclePedIsIn(PlayerPed, false))
    else
        QBCore.Functions.Notify('You are not in a vehicle', 'error')
    end
    
    if myCarClassIsAllowed(RaceData.MaxClass, class) then
        RaceData.RacerName = RaceData.SetupRacerName
        RaceData.PlayerVehicleEntity = GetVehiclePedIsIn(PlayerPed, false)
        TriggerServerEvent('nmsh-racingapp:server:JoinRace', RaceData)
    else 
        QBCore.Functions.Notify('Your car is not the correct class', 'error')
    end
end)

local function openRaceUi()
    CreatorUI()
    CreatorLoop()
end

RegisterNetEvent('nmsh-racingapp:client:StartRaceEditor', function(RaceName, RacerName, RaceId)
    if not RaceData.InCreator then
        CreatorData.RaceName = RaceName
        CreatorData.RacerName = RacerName
        RaceData.InCreator = true
        if RaceId then
            QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetTrackData', function(track)
                if track then
                    CreatorData.RaceName = RaceName
                    CreatorData.RacerName = RacerName
                    CreatorData.RaceId = RaceId
                    CreatorData.CheckPoints = {}
                    CreatorData.TireDistance = 3.0
                    CreatorData.ConfirmDelete = false
                    CreatorData.IsEdit = true
                    for i, checkpoint in pairs(track.Checkpoints) do
                        CreatorData.Checkpoints[#CreatorData.Checkpoints+1] = checkpoint
                    end
                    openRaceUi()
                    
                else
                    print('Something went wrong with fetching this track')
                end
            end, RaceId)
        else
            CreatorData.IsEdit = false
            openRaceUi()
        end
    else
        QBCore.Functions.Notify(Lang:t("error.already_making_race"), 'error')
    end
end)

local function getIndex (Positions)
    for k,v in pairs(Positions) do
        if v.RacerName == CurrentRaceData.RacerName then return k end
    end
end

RegisterNetEvent('nmsh-racingapp:client:UpdateRaceRacerData', function(RaceId, RaceData, Positions)
    if (CurrentRaceData.RaceId ~= nil) and CurrentRaceData.RaceId == RaceId then
        local MyPosition = getIndex(Positions)
        CurrentRaceData.Racers = RaceData.Racers
        CurrentRaceData.Position = MyPosition
        CurrentRaceData.Positions = Positions
    end
end)

RegisterNetEvent('nmsh-racingapp:client:JoinRace', function(Data, Laps, RacerName)
    if not RaceData.InRace then
        Data.RacerName = RacerName
        RaceData.InRace = true
        SetupRace(Data, Laps)
        QBCore.Functions.Notify(Lang:t("primary.race_joined"))
        TriggerServerEvent('nmsh-racingapp:server:UpdateRaceState', CurrentRaceData.RaceId, false, true)
    else
        QBCore.Functions.Notify(Lang:t("error.already_in_race"), 'error')
    end
end)

RegisterNetEvent('nmsh-racingapp:client:UpdateRaceRacers', function(RaceId, Racers)
    if CurrentRaceData.RaceId == RaceId then
        CurrentRaceData.Racers = Racers
    end
end)


RegisterNetEvent('nmsh-racingapp:client:UpdateOrganizer', function(RaceId, organizer)
    if CurrentRaceData.RaceId == RaceId then
        if useDebug then print('updating organizer') end
        CurrentRaceData.OrganizerCID = organizer
    end
end)

RegisterNetEvent('nmsh-racingapp:client:LeaveRace', function(data)
    ClearGpsMultiRoute()
    UnGhostPlayer()
    DeleteCurrentRaceCheckpoints()
    FreezeEntityPosition(GetVehiclePedIsIn(PlayerPedId(), false), false)
end)

local function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
      table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
      return sortFunction(tbl[a], tbl[b])
    end)
    if useDebug then
       print('KEYS',dump(keys))
    end
    return keys
end

RegisterNetEvent("nmsh-racingapp:Client:DeleteTrackConfirmed", function(data)
    QBCore.Functions.Notify(data.RaceName..Lang:t("primary.has_been_removed"))
    TriggerServerEvent("nmsh-racingapp:Server:DeleteTrack", data.RaceId)
end)

RegisterNetEvent("nmsh-racingapp:Client:ClearLeaderboardConfirmed", function(data)
    QBCore.Functions.Notify(data.RaceName..Lang:t("primary.leaderboard_has_been_cleared"))
    TriggerServerEvent("nmsh-racingapp:Server:ClearLeaderboard", data.RaceId)
end)

RegisterNetEvent("nmsh-racingapp:Client:EditTrack", function(data)
    TriggerEvent("nmsh-racingapp:client:StartRaceEditor", data.RaceName, data.name, data.RaceId)
end)

function split(source)
    local str = source:gsub("%s+", "")
    str = string.gsub(str, "%s+", "")
    local result, i = {}, 1
    while true do
        local a, b = str:find(',')
        if not a then break end
        local candidat = str:sub(1, a - 1)
        if candidat ~= "" then 
            result[i] = candidat
        end i=i+1
        str = str:sub(b + 1)
    end
    if str ~= "" then 
        result[i] = str
    end
    return result
end

RegisterNetEvent("nmsh-racingapp:Client:EditAccess", function(data)
    QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetAccess', function(accessTable)
        if accessTable == 'NOTHING' then
            if useDebug then
               print('Access table was empty')
            end
            accessTable = { race = ''}
        else            
            local raceText = ''
            if accessTable.race then
                for i, v in pairs(accessTable.race) do
                    if i == 1 then raceText = v else
                        raceText = raceText..', '..v
                    end
                end
                accessTable = { race = raceText}
            else
            accessTable.race = ''
            end
        end

        local dialog = exports['nmsh-input']:ShowInput({
            header = Lang:t("menu.access_list"),
            submitText = "Submit Access",
            inputs = {
                {
                    text = Lang:t('menu.access_race'), -- text you want to be displayed as a place holder
                    name = "accessRace", -- name of the input should be unique otherwise it might override
                    type = "text", -- type of the input
                    default = accessTable.race, -- Default text option, this is optional
                }
            },
        })
        if dialog ~= nil then
            if dialog.accessRace then
                local newAccess = {
                    race = split(dialog.accessRace)
                }
                TriggerServerEvent("nmsh-racingapp:server:SetAccess", data.RaceId, newAccess)
            end
        end
    end, data.RaceId)

end)

RegisterNetEvent("nmsh-racingapp:Client:DeleteTrack", function(data)
    local menu = {{
        header = Lang:t("menu.are_you_sure_you_want_to_delete_track")..' ('..data.RaceName..')' ,
        isMenuHeader = true
    }}
    menu[#menu + 1] = {
        header = Lang:t("menu.yes"),
        icon = "fas fa-check",
        params = {
            event = "nmsh-racingapp:Client:DeleteTrackConfirmed",
            args = {
                type = data.type,
                name = data.name,
                RaceId = data.RaceId,
                RaceName = data.RaceName
            }
        }
    }
    menu[#menu + 1] = {
        header = Lang:t("menu.no"),
        icon = "fas fa-xmark",
        params = {
            event = "nmsh-racingapp:Client:TrackInfo",
            args = {
                type = data.type,
                name = data.name,
                RaceId = data.RaceId,
                RaceName = data.RaceName
            }
        }
    }
    exports['nmsh-menu']:openMenu(menu)
end)

RegisterNetEvent("nmsh-racingapp:Client:ClearLeaderboard", function(data)
    local menu = {{
        header = Lang:t("menu.are_you_sure_you_want_to_clear")..' ('..data.RaceName..')' ,
        isMenuHeader = true
    }}
    menu[#menu + 1] = {
        header = Lang:t("menu.yes"),
        icon = "fas fa-check",
        params = {
            event = "nmsh-racingapp:Client:ClearLeaderboardConfirmed",
            args = {
                type = data.type,
                name = data.name,
                RaceId = data.RaceId,
                RaceName = data.RaceName
            }
        }
    }
    menu[#menu + 1] = {
        header = Lang:t("menu.no"),
        icon = "fas fa-xmark",
        params = {
            event = "nmsh-racingapp:Client:TrackInfo",
            args = {
                type = data.type,
                name = data.name,
                RaceId = data.RaceId,
                RaceName = data.RaceName
            }
        }
    }
    exports['nmsh-menu']:openMenu(menu)
end)

RegisterNetEvent("nmsh-racingapp:Client:TrackInfo", function(data)
    local menu = {{
        header = data.RaceName,
        icon = "fas fa-flag-checkered",
        isMenuHeader = true
    }}

    menu[#menu + 1] = {
        header = Lang:t("menu.clear_leaderboard"),
        icon = "fas fa-eraser",
        params = {
            event = "nmsh-racingapp:Client:ClearLeaderboard",
            args = {
                type = data.type,
                name = data.name,
                RaceId = data.RaceId,
                RaceName = data.RaceName
            }
        }
    }
    menu[#menu + 1] = {
        header = Lang:t("menu.edit_track"),
        icon = "fas fa-wrench",
        params = {
            event = "nmsh-racingapp:Client:EditTrack",
            args = {
                type = data.type,
                name = data.name,
                RaceId = data.RaceId,
                RaceName = data.RaceName
            }
        }
    }
    menu[#menu + 1] = {
            header = Lang:t("menu.edit_access"),
            icon = "fas fa-user-lock",
            params = {
                event = "nmsh-racingapp:Client:EditAccess",
                args = {
                    type = data.type,
                    name = data.name,
                    RaceId = data.RaceId,
                    RaceName = data.RaceName
                }
            }
    }        
    menu[#menu + 1] = {
        header = Lang:t("menu.delete_track"),
        icon = "fas fa-trash-can",
        params = {
            event = "nmsh-racingapp:Client:DeleteTrack",
            args = {
                type = data.type,
                name = data.name,
                RaceId = data.RaceId,
                RaceName = data.RaceName
            }
        }
    }

    menu[#menu + 1] = {
        header = Lang:t("menu.go_back"),
        icon = "fas fa-arrow-left",
        params = {
            event = "nmsh-racingapp:Client:ListMyTracks",
            args = {
                type = data.type,
                name = data.name
            }
        }
    }

    if #menu == 1 then
        QBCore.Functions.Notify(Lang:t("primary.no_races_exist"))
        TriggerEvent('nmsh-racingapp:Client:ListMyTracks', {
            type = data.type,
            name = data.name
        })
        return
    end

    exports['nmsh-menu']:openMenu(menu)
end)

local function filterTracksByRacer(Tracks)
    local filteredTracks = {}
    for i, track in pairs(Tracks) do      
        if track.Creator == QBCore.Functions.GetPlayerData().citizenid then
            table.insert(filteredTracks, track)
        end
    end
    return filteredTracks
end

RegisterNetEvent("nmsh-racingapp:Client:ListMyTracks", function(data)
    QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetTracks', function(Tracks)
        local menu = {}

        for i, track in pairs(filterTracksByRacer(Tracks)) do      
            menu[#menu + 1] = {
                header = track.RaceName.. ' | '.. track.Distance..'m',
                icon = "fas fa-flag-checkered",
                params = {
                    event = "nmsh-racingapp:Client:TrackInfo",
                    args = {
                        type = data.type,
                        name = data.name,
                        RaceId = track.RaceId,
                        RaceName = track.RaceName
                    }
                }
            }
        end

        table.sort(menu, function (a,b)
            return a.header < b.header
        end)

        menu[#menu + 1] = {
            header = Lang:t("menu.go_back"),
            icon = "fas fa-arrow-left",
            params = {
                event = "nmsh-racingapp:Client:OpenMainMenu",
                args = {
                    type = data.type,
                    name = data.name
                }
            }
        }

        table.insert(menu, 1, {
            header = Lang:t("menu.my_tracks"),
            icon = "fas fa-route",
            isMenuHeader = true
        })
        if #menu == 1 then
            QBCore.Functions.Notify(Lang:t("menu.no_tracks_exist"))
            TriggerEvent('nmsh-racingapp:Client:OpenMainMenu', {
                type = data.type,
                name = data.name
            })
            return
        end
        exports['nmsh-menu']:openMenu(menu)
    end, class)
    exports['nmsh-menu']:openMenu(menu)
end)

RegisterNetEvent('nmsh-racingapp:client:RaceCountdown', function(TotalRacers, Positions)
    doGPSForRace(true)
    Players = {}
    TriggerServerEvent('nmsh-racingapp:server:UpdateRaceState', CurrentRaceData.RaceId, true, false)
    CurrentRaceData.TotalRacers = TotalRacers
    CurrentRaceData.Positions = Positions
    if CurrentRaceData.RaceId ~= nil then
        while Countdown ~= 0 do
            if CurrentRaceData.RaceName ~= nil then
                if Countdown == 10 then
                    --QBCore.Functions.Notify(Lang:t("primary.race_will_start"), 'primary', 2500)
                    updateCountdown(Lang:t("primary.race_will_start"))
                    PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS")
                elseif Countdown <= 5 then
                    --QBCore.Functions.Notify(Countdown, 'primary', 500)
                    updateCountdown(Countdown)
                    PlaySoundFrontend(-1, "Oneshot_Final", "MP_MISSION_COUNTDOWN_SOUNDSET")
                end
                Countdown = Countdown - 1
                FreezeEntityPosition(GetVehiclePedIsIn(PlayerPedId(), true), true)
            else
                break
            end
            Wait(1000)
        end
        if CurrentRaceData.RaceName ~= nil then
            AddPointToGpsMultiRoute(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].coords.x,
            CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].coords.y)
            --QBCore.Functions.Notify(Lang:t("success.race_go"), 'success', 1000)
            updateCountdown(Lang:t("success.race_go"))
            SetBlipScale(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint + 1].blip, Config.Blips.Generic.Size)
            FreezeEntityPosition(GetVehiclePedIsIn(PlayerPedId(), true), false)
            DoPilePfx()
            if Config.Ghosting.Enabled and CurrentRaceData.Ghosting then
                QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetRacers', function(Racers)
                    QBCore.Functions.TriggerCallback('nmsh-racingapp:Server:getplayers', function(players)
                        if useDebug then
                            print('Doing ghosting stuff')
                            print('PLAYERS', dump(players))
                            print('Racers', dump(Racers))
                        end
                        for index,player in ipairs(players) do
                            if useDebug then
                                print('checking if exists in racers:', player.citizenid)
                                print(Racers[player.citizenid] ~= nil)
                            end
                            if Racers[player.citizenid] then
                                if useDebug then
                                    print('not adding ', player.name)
                                end
                            else
                                Players[#Players+1] = player
                            end
                        end
                        if useDebug then
                            print('PLAYERS AFTER', dump(Players))
                            print('====================')
                        end
                        GhostPlayers()
                    end)
                end, CurrentRaceData.RaceId)
            end
            lapStartTime = GetGameTimer()
            startTime = GetGameTimer()
            CurrentRaceData.Started = true
            timeWhenLastCheckpointWasPassed = GetGameTimer()
            Countdown = 10
        else
            FreezeEntityPosition(GetVehiclePedIsIn(PlayerPedId(), true), false)
            Countdown = 10
        end
    else
        QBCore.Functions.Notify(Lang:t("error.already_in_race"), 'error')
    end
end)

RegisterNetEvent('nmsh-racingapp:client:PlayerFinish', function(RaceId, Place, RacerName)
    if CurrentRaceData.RaceId ~= nil then
        if CurrentRaceData.RaceId == RaceId then
            QBCore.Functions.Notify(RacerName .. Lang:t("primary.racer_finished_place") .. Place, 'primary', 3500)
        end
    end
end)

RegisterNetEvent('nmsh-racingapp:client:NotCloseEnough', function(x,y)
    QBCore.Functions.Notify(Lang:t('error.not_close_enough_to_join'), 'error')
    SetNewWaypoint(x, y)
end)

RegisterNetEvent("nmsh-racingapp:Client:OpenMainMenu", function(data)
    local type = data.type
    local name = data.name
    local info, class, perfRating = '', '', ''
    local subtitle = Lang:t('menu.not_in_a_vehicle')

    local PlayerPed = PlayerPedId()
    local PlayerIsInVehicle = IsPedInAnyVehicle(PlayerPed, false)

    if PlayerIsInVehicle then
        info, class, perfRating = exports['nmsh-performance']:getVehicleInfo(GetVehiclePedIsIn(PlayerPed, false))
        subtitle = Lang:t('menu.currently_in') .. class .. perfRating.. Lang:t('menu.class_car')
    else
        QBCore.Functions.Notify(Lang:t('menu.not_in_a_vehicle'), 'error')
    end


    exports['nmsh-menu']:openMenu({{
        header = Lang:t("menu.ready_to_race") .. name .. '?',
        txt = subtitle,
        icon = 'fas fa-car-burst',
        isMenuHeader = true
    }, {
        header = Lang:t("menu.current_race"),
        txt = Lang:t("menu.current_race_txt"),
        icon = "fas fa-hourglass-start",
        disabled = (CurrentRaceData.RaceId == nil),
        params = {
            event = "nmsh-racingapp:Client:CurrentRaceMenu",
            args = {
                type = type,
                name = name
            }
        }
    }, {
        header = Lang:t("menu.available_races"),
        txt = Lang:t("menu.available_races_txt"),
        icon = "fas fa-flag-checkered",
        disabled = not Config.Permissions[type].join,
        params = {
            event = "nmsh-racingapp:Client:AvailableRacesMenu",
            args = {
                type = type,
                name = name
            }
        }
    }, {
        header = Lang:t("menu.race_records"),
        txt = Lang:t("menu.race_records_txt"),
        icon = "fas fa-trophy",
        disabled = not Config.Permissions[type].records,
        params = {
            event = "nmsh-racingapp:Client:RaceRecordsMenu",
            args = {
                type = type,
                name = name
            }
        }
    }, {
        header = Lang:t("menu.setup_race"),
        txt = "",
        icon = "fas fa-calendar-plus",
        disabled = not Config.Permissions[type].setup,
        params = {
            event = "nmsh-racingapp:Client:SetupRaceMenu",
            args = {
                type = type,
                name = name
            }
        }
    }, {
        header = Lang:t("menu.create_race"),
        txt = "",
        icon = "fas fa-plus",
        disabled = not Config.Permissions[type].create,
        params = {
            event = "nmsh-racingapp:Client:CreateRaceMenu",
            args = {
                type = type,
                name = name
            }
        }
    },
    {
        header = Lang:t("menu.my_tracks"),
        txt = "",
        icon = "fas fa-route",
        disabled = not Config.Permissions[type].create,
        params = {
            event = "nmsh-racingapp:Client:ListMyTracks",
            args = {
                type = type,
                name = name
            }
        }
    },
    {
        header = Lang:t("menu.open_tuning_overlay"),
        txt = "",
        icon = "fas fa-wrench",
        hidden = not Config.ShowMechToolOption,
        params = {
            event = "nmsh-mechtool:client:openTuning",
            args = { fromObd = false}

        }
    },
    {
        header = Lang:t("menu.close"),
        txt = "",
        icon = "fas fa-x",
        params = {
            event = "nmsh-menu:client:closeMenu"
        }
    }})

end)

RegisterNetEvent("nmsh-racingapp:Client:CurrentRaceMenu", function(data)
    if not CurrentRaceData.RaceId then
        return
    end

    local racers = 0
    local maxClass = 'open'
    for _ in pairs(CurrentRaceData.Racers) do
        racers = racers + 1
    end
    if (CurrentRaceData.MaxClass ~= nil and CurrentRaceData.MaxClass ~= "") then
        maxClass = CurrentRaceData.MaxClass
    end

    exports['nmsh-menu']:openMenu({{
        header = CurrentRaceData.RaceName .. ' | ' .. racers .. Lang:t("menu.racers") .. ' | Class: ' ..
            tostring(maxClass),
        isMenuHeader = true
    }, {
        header = Lang:t("menu.start_race"),
        txt = "",
        icon = "fas fa-play",
        disabled = (not (CurrentRaceData.OrganizerCID == QBCore.Functions.GetPlayerData().citizenid) or
            CurrentRaceData.Started),
        params = {
            isServer = true,
            event = "nmsh-racingapp:server:StartRace",
            args = CurrentRaceData.RaceId
        }
    }, {
        header = Lang:t("menu.leave_race"),
        txt = "",
        icon = "fas fa-door-open",
        params = {
            isServer = true,
            event = "nmsh-racingapp:server:LeaveRace",
            args = CurrentRaceData
        }
    }, {
        header = Lang:t("menu.go_back"),
        icon = "fas fa-arrow-left",
        params = {
            event = "nmsh-racingapp:Client:OpenMainMenu",
            args = {
                type = data.type,
                name = data.name
            }
        }
    }})
end)

RegisterNetEvent("nmsh-racingapp:Client:AvailableRacesMenu", function(data)
    QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetRaces', function(Races)
        local menu = {{
            header = Lang:t("menu.available_races"),
            isMenuHeader = true
        }}

        for _, race in ipairs(Races) do
            local RaceData = race.RaceData
            local racers = 0
            local PlayerPed = PlayerPedId()
            race.PlayerVehicleEntity = GetVehiclePedIsIn(PlayerPed, false)
            for _ in pairs(RaceData.Racers) do
                racers = racers + 1
            end

            race.RacerName = data.name

            local maxClass = 'open'
            if (RaceData.MaxClass ~= nil and RaceData.MaxClass ~= "") then
                maxClass = RaceData.MaxClass
            end
            local text = race.Laps..' lap(s) | ' ..RaceData.Distance.. 'm | ' ..racers.. ' racer(s) | Class: ' ..maxClass
            if race.Ghosting then
                text = text..' | 👻'
                if race.GhostingTime then
                    text = text..' ('..race.GhostingTime..'s)'
                end
            end
            local header = RaceData.RaceName
            if RaceData.BuyIn > 0 then
                local currency = ''
                if Config.Options.MoneyType == 'cash' or Config.Options.MoneyType == 'bank' then
                    currency = '$'
                else
                    currency = Config.Options.CryptoType
                end
                header = header.. ' | '..currency .. RaceData.BuyIn
            end
            menu[#menu + 1] = {
                header = header,
                txt = text,
                disabled = CurrentRaceData.RaceId == RaceData.RaceId,
                params = {
                    isServer = true,
                    event = "nmsh-racingapp:server:JoinRace",
                    args = race
                }
            }
        end

        menu[#menu + 1] = {
            header = Lang:t("menu.go_back"),
            icon = "fas fa-arrow-left",
            params = {
                event = "nmsh-racingapp:Client:OpenMainMenu",
                args = {
                    type = data.type,
                    name = data.name
                }
            }
        }

        if #menu == 1 then
            QBCore.Functions.Notify(Lang:t("primary.no_pending_races"))
            TriggerEvent('nmsh-racingapp:Client:OpenMainMenu', {
                type = data.type,
                name = data.name
            })
            return
        end

        exports['nmsh-menu']:openMenu(menu)
    end)
end)

RegisterNetEvent("nmsh-racingapp:Client:RaceRecordsMenu", function(data)
    local PlayerPed = PlayerPedId()
    local PlayerIsInVehicle = IsPedInAnyVehicle(PlayerPed, false)

    local info, class, perfRating = '', '', ''
    if PlayerIsInVehicle then
        info, class, perfRating = exports['nmsh-performance']:getVehicleInfo(GetVehiclePedIsIn(PlayerPed, false))
    end

    QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetTracks', function(Tracks)
        local menu = {}
        for i, track in pairs(Tracks) do      
            menu[#menu + 1] = {
                header = track.RaceName.. ' | '.. track.Distance..'m',
                icon = "fas fa-hourglass-start",
                params = {
                    event = "nmsh-racingapp:Client:ClassesList",
                    args = {
                        type = data.type,
                        name = data.name,
                        trackName = track.RaceName 
                    }
                }
            }
        end

        table.sort(menu, function (a,b)
            return a.header < b.header
        end)

        table.insert(menu, 1, {
            header = Lang:t("menu.choose_a_track"),
            icon = "fas fa-route",
            isMenuHeader = true
        })
        if #menu == 1 then
            QBCore.Functions.Notify(Lang:t("menu.no_tracks_exist"))
            TriggerEvent('nmsh-racingapp:Client:OpenMainMenu', {
                type = data.type,
                name = data.name
            })
            return
        end

        menu[#menu + 1] = {
            header = Lang:t("menu.go_back"),
            icon = "fas fa-arrow-left",
            params = {
                event = "nmsh-racingapp:Client:OpenMainMenu",
                args = {
                    type = data.type,
                    name = data.name
                }
            }
        }
        exports['nmsh-menu']:openMenu(menu)
    end, class)

    exports['nmsh-menu']:openMenu(menu)
end)

local function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
      table.insert(keys, key)
    end
  
    table.sort(keys, function(a, b)
      return sortFunction(tbl[a], tbl[b])
    end)
    if useDebug then
       print('KEYS',dump(keys))
    end
    return keys
  end


RegisterNetEvent("nmsh-racingapp:Client:ClassesList", function(data)
    local classes = exports['nmsh-performance']:getPerformanceClasses()
    local sortedClasses = getKeysSortedByValue(classes, function(a, b) return a > b end)

    local menu = {{
        header = Lang:t("menu.choose_a_class"),
        icon = 'fas fa-car',
        isMenuHeader = true
    }}
    menu[#menu + 1] = {
        header = Lang:t("menu.all"),
        icon = 'fas fa-globe',
        params = {
            event = "nmsh-racingapp:Client:TrackRecordList",
            args = {
                type = data.type,
                name = data.name,
                trackName = data.trackName,
                class = 'all'
            }
        }
    }

    for value, class in pairs(sortedClasses) do
        menu[#menu + 1] = {
            header = class,
            icon = 'fas fa-taxi',
            params = {
                event = "nmsh-racingapp:Client:TrackRecordList",
                args = {
                    type = data.type,
                    name = data.name,
                    trackName = data.trackName,
                    class = class
                }
            }
        }
    end

    menu[#menu + 1] = {
        header = Lang:t("menu.go_back"),
        icon = "fas fa-arrow-left",
        params = {
            event = "nmsh-racingapp:Client:RaceRecordsMenu",
            args = {
                type = data.type,
                name = data.name
            }
        }
    }

    if #menu == 2 then
        QBCore.Functions.Notify(Lang:t("primary.no_races_exist"))
        TriggerEvent('nmsh-racingapp:Client:RaceRecordsMenu', {
            type = data.type,
            name = data.name
        })
        return
    end

    exports['nmsh-menu']:openMenu(menu)
end)

RegisterNetEvent("nmsh-racingapp:Client:TrackRecordList", function(data)
    QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetRacingLeaderboards', function(filteredLeaderboards)
        local headerText = data.trackName..' | '
        if data.class == 'all' then
            headerText = headerText..Lang:t("menu.all")
        else
            headerText = headerText..data.class
        end
        local menu = {{
            header = data.trackName..' | '..data.class,
            icon = "fas fa-globe",
            isMenuHeader = true
        }}
        if useDebug then
           print(dump(filteredLeaderboards))
        end
        for i, RecordData in pairs(filteredLeaderboards) do
            if useDebug then
               print('RecordData', dump(RecordData), i)
            end
            
            local class = RecordData.Class
            local holder = RecordData.Holder
            local vehicle = RecordData.Vehicle
            local time = RecordData.Time

            if not class then
                class = 'NO DATA AVAILABLE'
            end
            if not holder then
                holder = 'NO DATA AVAILABLE'
            end
            if not vehicle then
                vehicle = 'NO DATA AVAILABLE'
            end
            if not time then
                time = 'NO DATA AVAILABLE'
            end

            local text = ''
            local first = '🥇 '
            local second = '🥈 '
            local third = '🥉 '
            local header = ''
            if i == 1 then
                header = first..holder
            elseif i == 2 then
                header = second..holder
            elseif i == 3 then
                header = third..holder
            else
                header = i..'. '..holder
            end
            text = MilliToTime(time).. ' | '..vehicle
            if data.class == 'all' then
                text = text.. ' | '..class
            end

            menu[#menu + 1] = {
                header = header,
                icon = "fas fa-hourglass-start",
                text = text,
                disabled = true
            }
        end

        menu[#menu + 1] = {
            header = Lang:t("menu.go_back"),
            icon = "fas fa-arrow-left",
            params = {
                event = "nmsh-racingapp:Client:ClassesList",
                args = {
                    type = data.type,
                    name = data.name,
                    trackName = data.trackName 
                }
            }
        }

        if #menu == 1 then
            QBCore.Functions.Notify(Lang:t("primary.no_races_exist"))
            TriggerEvent('nmsh-racingapp:Client:RaceRecordsMenu', {
                type = data.type,
                name = data.name
            })
            return
        end

        exports['nmsh-menu']:openMenu(menu)
    end, data.class, data.trackName)
end)

local function toboolean(str)
    local bool = false
    if str == "true" or str == true then
        bool = true
    end
    return bool
end

local function verifyTrackAccess(track, type)
    if track.Access[type] ~= nil then
        if track.Access[type][1] == nil then print('no values', track.RaceName) return true end -- if list is added but emptied 
        local playerCid = QBCore.Functions.GetPlayerData().citizenid
        if track.Creator == playerCid then return true end -- if creator default to true
        if useDebug then
            print('track', track.RaceName, 'has access limitations for', type)
            print('player cid', playerCid)
        end
        for i, citizenId in pairs(track.Access[type]) do
            if useDebug then
               print(i, citizenId)
            end
            if citizenId == playerCid then return true end -- if one of the players in the list
        end
        return false
    end
    return true
end

RegisterNetEvent("nmsh-racingapp:Client:SetupRaceMenu", function(data)
    QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetListedRaces', function(Races)
        local tracks = {{
            value = "none",
            text = Lang:t("menu.choose_a_track"),
            name = 'none',
        }}
        for id, track in pairs(Races) do
            if not track.Waiting and verifyTrackAccess(track, 'race') then
                tracks[#tracks + 1] = {
                    value = id,
                    text = string.format("%s | %s | %sm", track.RaceName, track.CreatorName, track.Distance),
                    name = track.RaceName,
                }
            end
        end

        if #tracks == 1 then
            QBCore.Functions.Notify(Lang:t("primary.no_available_tracks"))
            TriggerEvent('nmsh-racingapp:Client:OpenMainMenu', {
                type = data.type,
                name = data.name
            })
            return
        end

        table.sort(tracks, function(a, b) return a.name < b.name end)

        local currency = ''
        if Config.Options.MoneyType == 'cash' or Config.Options.MoneyType == 'bank' then
            currency = '$'
        else
            currency = Config.Options.CryptoType
        end

        local options = {{
                text = Lang:t("menu.select_track"),
                name = "track",
                type = "select",
                options = tracks
            }, {
                text = Lang:t("menu.number_laps"),
                name = "laps",
                type = "select",
                options = Config.Options.Laps,
                isRequired = true
            },
            {
                text = Lang:t("menu.buyIn")..' ('..currency..')',
                name = "buyIn",
                type = "select",
                options = Config.Options.BuyIns,
                isRequired = true
            }}

        if Config.Ghosting.Enabled then
            table.insert(options, {
                text = Lang:t("menu.useGhosting"),
                name = "ghosting", 
                type = "radio", 
                options = {
                    { value = false, text = Lang:t("menu.no"), checked = true },
                    { value = true, text = Lang:t("menu.yes")},
                }})
            table.insert(options, {
                text = Lang:t('menu.ghostingTime'),
                name = "ghostingTime",
                type = "select",
                options = Config.Ghosting.Options
                })
        end
        
        local classes = { {value = '', text = Lang:t('menu.no_class_limit'), number = 9000} }
        for i, class in pairs(Config.Classes) do
            if useDebug then
                print(i, Classes[i])
            end
            classes[#classes+1] = { value = i, text = i, number = Classes[i] }
        end

        table.sort(classes, function(a,b)
            return a.number > b.number
        end)
        table.insert(options, {
            text =  Lang:t('menu.max_class'),
            name = "maxClass",
            type = "select",
            options = classes
        })

        local dialog = exports['nmsh-input']:ShowInput({
            header = Lang:t("menu.racing_setup"),
            submitText = "✓",
            inputs = options
        })
        if dialog ~= nil then
            if useDebug then
                print('selected max class', dialog.maxClass)
            end
            if dialog.maxClass == '' or Config.Classes[dialog.maxClass] then
                if not dialog or dialog.track == "none" then
                    TriggerEvent('nmsh-racingapp:Client:OpenMainMenu', {
                        type = data.type,
                        name = data.name
                    })
                    return
                end
    
                local PlayerPed = PlayerPedId()
                local PlayerIsInVehicle = IsPedInAnyVehicle(PlayerPed, false)
    
                if PlayerIsInVehicle then
                    local info, class, perfRating = exports['nmsh-performance']:getVehicleInfo(GetVehiclePedIsIn(PlayerPed, false))
                    if myCarClassIsAllowed(dialog.maxClass, class) then
                        TriggerServerEvent('nmsh-racingapp:server:SetupRace',
                            dialog.track,
                            tonumber(dialog.laps),
                            data.name,
                            dialog.maxClass,
                            toboolean(dialog.ghosting),
                            tonumber(dialog.ghostingTime),
                            tonumber(dialog.buyIn)
                        )
                    else 
                        QBCore.Functions.Notify('Your car is not the correct class', 'error')
                    end
                else
                        QBCore.Functions.Notify('You are not in a vehicle', 'error')
                end
            else
                QBCore.Functions.Notify('The class you chose does not exist', 'error')
            end
        end
    end)
end)

RegisterNetEvent("nmsh-racingapp:Client:CreateRaceMenu", function(data)
    local citizenId = QBCore.Functions.GetPlayerData().citizenid
    QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetAmountOfTracks', function(tracks)
        local maxCharacterTracks = Config.MaxCharacterTracks
        if Config.CustomAmountsOfTracks[citizenId] then
            maxCharacterTracks = Config.CustomAmountsOfTracks[citizenId]
        end
        if useDebug then print('Max allowed for you:', maxCharacterTracks, "You have this many tracks:", tracks) end
        if Config.LimitTracks and tracks >= maxCharacterTracks then
            QBCore.Functions.Notify("You already have ".. maxCharacterTracks.." tracks")
            return
        else
            local dialog = exports['nmsh-input']:ShowInput({
                header = Lang:t("menu.name_track_question"),
                submitText = "✓",
                inputs = {{
                    text = Lang:t("menu.name_track_question"),
                    name = "trackname",
                    type = "text",
                    isRequired = true
                }}
            })
        
            if not dialog then
                TriggerEvent('nmsh-racingapp:Client:OpenMainMenu', {
                    type = data.type,
                    name = data.name
                })
                return
            end
        
            if not #dialog.trackname then
                QBCore.Functions.Notify("This track need to have a name", 'error')
                TriggerEvent("nmsh-racingapp:Client:CreateRaceMenu", {
                    type = data.type,
                    name = data.name
                })
                return
            end
        
            if #dialog.trackname < Config.MinTrackNameLength then
                QBCore.Functions.Notify(Lang:t("error.name_too_short"), 'error')
                TriggerEvent("nmsh-racingapp:Client:CreateRaceMenu", {
                    type = data.type,
                    name = data.name
                })
                return
            end
        
            if #dialog.trackname > Config.MaxTrackNameLength then
                QBCore.Functions.Notify(Lang:t("error.name_too_long"), 'error')
                TriggerEvent("nmsh-racingapp:Client:CreateRaceMenu", {
                    type = data.type,
                    name = data.name
                })
                return
            end
        
            QBCore.Functions.TriggerCallback('nmsh-racingapp:server:IsAuthorizedToCreateRaces',
                function(IsAuthorized, NameAvailable)
                    if not IsAuthorized then
                        return
                    end
                    if not NameAvailable then
                        QBCore.Functions.Notify(Lang:t("error.race_name_exists"), 'error')
                        TriggerEvent("nmsh-racingapp:Client:CreateRaceMenu", {
                            type = data.type,
                            name = data.name
                        })
                        return
                    end
        
                    TriggerServerEvent('nmsh-racingapp:server:CreateLapRace', dialog.trackname, data.name)
                end, dialog.trackname)
            end
    end, citizenId)
end)

local function indexOf(array, value)
    for i, v in ipairs(array) do
        print(i, value)
        if i == value then
            return i
        end
    end
    return nil
end

function myCarClassIsAllowed(maxClass, myClass)
    if maxClass == nil or maxClass == '' then
        return true
    end
    local myClassIndex = Classes[myClass]
    local maxClassIndex = Classes[maxClass]
    if myClassIndex > maxClassIndex then
        return false
    end

    return true
end

local function racerNameIsValid(name)
    if #name > Config.MinRacerNameLength then
        if #name < Config.MaxRacerNameLength then
            return true
        else
            QBCore.Functions.Notify(Lang:t('error.name_too_long'), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t('error.name_too_short'), 'error')
    end
    return false
end

local function hasAuth(tradeType, fobType)
    if tradeType.jobRequirement[fobType] then
        local Player = QBCore.Functions.GetPlayerData()
        local playerHasJob = Config.AllowedJobs[Player.job.name]
        local jobGradeReq = nil
        if useDebug then
           print('Player job: ', Player.job.name)
           print('Allowed jobs: ', dump(Config.AllowedJobs))
        end
        if playerHasJob then
            if useDebug then
               print('Player job level: ', Player.job.grade.level)
            end
            if Config.AllowedJobs[Player.job.name] ~= nil then
                jobGradeReq = Config.AllowedJobs[Player.job.name][fobType]
                if useDebug then
                   print('Required job grade: ', jobGradeReq)
                end
                if jobGradeReq ~= nil then
                    if Player.job.grade.level >= jobGradeReq then
                        return true
                    end
                end
            end
        end
        return false
    else
        return true
    end
end

RegisterNetEvent("nmsh-racingapp:client:OpenFobInput", function(data)
    local purchaseType = data.purchaseType
    local fobType = data.fobType

    QBCore.Functions.Notify("Max "..Config.MaxRacerNames.. " unique names per person.")

    local inputs = {
        {
            text = 'Racer Name', -- text you want to be displayed as a place holder
            name = "racerName", -- name of the input should be unique otherwise it might override
            type = "text", -- type of the input - number will not allow non-number characters in the field so only accepts 0-9
        },
    }

    if not purchaseType.useSlimmed then
        inputs[#inputs+1] = {
            text = 'Paypal/temp id (leave empty if for you)', -- text you want to be displayed as a place holder
            name = "racerId", -- name of the input should be unique otherwise it might override
            type = "text", -- type of the input - number will not allow non-number characters in the field so only accepts 0-9
        }
    end

    local dialog = exports['nmsh-input']:ShowInput({
        header = 'Creating a '..fobType..' Racing GPS',
        submitText = 'Submit',
        inputs = inputs
    })

    if dialog ~= nil then
        local racerName = dialog["racerName"]
        local racerId = dialog["racerId"]
        if racerId == nil or racerId == ''then
            racerId = GetPlayerServerId(PlayerId())
        end
        if racerNameIsValid(racerName) then
            QBCore.Functions.TriggerCallback('nmsh-racingapp:server:GetRacerNamesByPlayer', function(playerNames)
                if useDebug then print('player names', #playerNames, json.encode(playerNames)) end
                local maxRacerNames = Config.MaxRacerNames
                if #playerNames > 1 and playerNames[1].citizenid and Config.CustomAmounts[playerNames[1].citizenid] then
                    maxRacerNames = Config.CustomAmounts[playerNames[1].citizenid]
                end

                if useDebug then print('Racer names allowed for', racerId, maxRacerNames) end
                if playerNames == nil or #playerNames < maxRacerNames then
                    QBCore.Functions.TriggerCallback('nmsh-racingapp:server:NameIsAvailable', function(nameIsNotTaken)
                        if nameIsNotTaken then
                            TriggerEvent('animations:client:EmoteCommandStart', {"idle7"})
                            QBCore.Functions.Progressbar("item_check", 'Creating Racing Fob', 2000, false, true, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                                }, {
                                }, {}, {}, function() -- Done
                                    TriggerServerEvent('nmsh-racingapp:server:CreateFob', racerId, racerName, fobType, purchaseType)
                                    TriggerEvent('animations:client:EmoteCommandStart', {"keyfob"})
                                end, function()
                                    TriggerEvent('animations:client:EmoteCommandStart', {"damn"})
                                end)
                        else
                            QBCore.Functions.Notify( Lang:t("error.name_is_used")..racerName, 'error')
                            TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                        end
                    end, racerName, racerId)
                else
                    QBCore.Functions.Notify( Lang:t("error.to_many_names"), 'error')
                    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                end
            end, racerId)

        else
            TriggerEvent('animations:client:EmoteCommandStart', {"c"})
        end
    else
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end
end)

local traderEntity
if Config.Trader.active then
    local trader = Config.Trader
    CreateThread(function()
        local animation
        if trader.animation then
            animation = trader.animation
        else
            animation = "WORLD_HUMAN_STAND_IMPATIENT"
        end
    
        local currency = ''
        if trader.moneyType == 'cash' or trader.moneyType == 'bank' then
            currency = '$'
        else
            currency = Config.Options.CryptoType
        end

        local options = {
            { 
                type = "client",
                event = "nmsh-racingapp:client:OpenFobInput",
                icon = "fas fa-flag-checkered",
                label = 'Buy a racing GPS for '..trader.racingFobCost..' '..currency,
                purchaseType = trader,
                fobType = 'basic',
                canInteract = function()
                    return hasAuth(trader,'basic')
                end
            },
            { 
                type = "client",
                event = "nmsh-racingapp:client:OpenFobInput",
                icon = "fas fa-flag-checkered",
                label = 'Buy a Master racing GPS for '..trader.racingFobMasterCost..' '..currency,
                purchaseType = trader,
                fobType = 'master',
                canInteract = function()
                    return hasAuth(trader,'master')
                end
            }
        }

        traderEntity = exports['nmsh-target']:SpawnPed({
            model = trader.model,
            coords = trader.location,
            minusOne = true,
            freeze = true,
            invincible = true,
            blockevents = true,
            scenario = animation,
            target = {
                options = options,
                distance = 3.0 
            },
            spawnNow = true,
            currentpednumber = 4,
        })
        Entities[#Entities+1] = traderEntity
    end)
end

local laptopEntity
if Config.Laptop.active then
    CreateThread(function()        
        local laptop = Config.Laptop
        local currency = ''
        if laptop.moneyType == 'cash' or laptop.moneyType == 'bank' then
            currency = '$'
        else
            currency = Config.Options.CryptoType
        end
        local options = {
            { 
                type = "client",
                event = "nmsh-racingapp:client:OpenFobInput",
                icon = "fas fa-flag-checkered",
                label = 'Buy a racing fob for '..laptop.racingFobCost..' '.. currency,
                purchaseType = laptop,
                fobType = 'basic',
                canInteract = function()
                    return hasAuth(laptop,'basic')
                end
            },
            { 
                type = "client",
                event = "nmsh-racingapp:client:OpenFobInput",
                icon = "fas fa-flag-checkered",
                label = 'Buy a Master racing fob for '..laptop.racingFobMasterCost..' '.. currency,
                purchaseType = laptop,
                fobType = 'master',
                canInteract = function()
                    return hasAuth(laptop,'master')
                end
            }
        }
        laptopEntity = CreateObject(laptop.model, laptop.location.x, laptop.location.y, laptop.location.z, false,  false, true)
        SetEntityHeading(laptopEntity, laptop.location.w)
        CreateObject(laptopEntity)
        FreezeEntityPosition(laptopEntity, true)
        Entities[#Entities+1] = laptopEntity
        exports['nmsh-target']:AddTargetEntity(laptopEntity, {
            options = options,
            distance = 3.0 
        })
    end)
end

AddEventHandler('onResourceStop', function (resource)
   if resource ~= GetCurrentResourceName() then return end
   for i, entity in pairs(Entities) do
       print('deleting', entity)
       if DoesEntityExist(entity) then
          DeleteEntity(entity)
       end
    end
end)
DoScreenFadeIn(100)

local QBCore = exports['qb-core']:GetCoreObject()
local CameraProp = {}
local CountCamera = 0
local UsingPanel = false
local PlacingCamera = false
local PropTablet = nil
local NoLocation = vector3(0.0, 0.0, 0.0)
local objects = {
    'prop_cctv_cam_01a',
    'prop_cctv_cam_04c',
    'prop_cctv_cam_06a'
}
local slot = 0

-- Functions --

local function getDirVecFromHead(h, p)
    h = h + 270
    return vector3(math.cos(math.rad(h))*math.cos(math.rad(p)), math.sin(math.rad(h))*math.cos(math.rad(p)), math.sin(math.rad(p)))
end

local function OpenCamAnim()
    local animDict = "anim@heists@ornate_bank@hack"
    RequestAnimDict(animDict)
    RequestModel("hei_prop_hst_laptop")
    while not HasAnimDictLoaded(animDict)
        or not HasModelLoaded("hei_prop_hst_laptop") do
        Wait(100)
    end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    -- local animPos = GetAnimInitialOffsetPosition(animDict, "hack_loop")
    

    laptop = CreateObject(`hei_prop_hst_laptop`, pos.x, pos.y, pos.z + 0.40, 1, 1, 0)
    -- SetEntityCollision(laptop, false, false)
    SetEntityHeading(laptop, GetEntityHeading(ped))

    local LaptopCoords = GetEntityCoords(laptop)

    local HackLoop = NetworkCreateSynchronisedScene(LaptopCoords, GetEntityRotation(laptop), 0, true, true, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(ped, HackLoop, animDict, "hack_loop", 3.0, 3.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(laptop, HackLoop, animDict, "hack_loop_laptop", 4.0, -8.0, 1)

    HackLoopFinish = NetworkCreateSynchronisedScene(LaptopCoords, GetEntityRotation(laptop), 0, true, true, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(ped, HackLoopFinish, animDict, "hack_exit", 3.0, 3.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(laptop, HackLoopFinish, animDict, "hack_exit_laptop", 4.0, -8.0, 1)

    NetworkStartSynchronisedScene(HackLoop)
end

local function RotationToDirection(rotation)
    local adjustedRotation = 
    { 
        x = (math.pi / 180) * rotation.x, 
        y = (math.pi / 180) * rotation.y, 
        z = (math.pi / 180) * rotation.z 
    }
    local direction = 
    {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

local function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

local function Button(ControlButton)
    ScaleformMovieMethodAddParamPlayerNameString(ControlButton)
end

local function setupScaleform(scaleform)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end

    -- draw it once to set up layout
    --DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    Button(GetControlInstructionalButton(2, 194, true)) 
    ButtonMessage("Exit Camera")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    Button(GetControlInstructionalButton(2, 35, true))
    ButtonMessage("NextCamera")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(2)
    Button(GetControlInstructionalButton(2, 34, true))
    ButtonMessage("Previous Camera")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(3)
    Button(GetControlInstructionalButton(2, 173, true))
    ButtonMessage("Down")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(4)
    Button(GetControlInstructionalButton(2, 172, true))
    ButtonMessage("Up")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(5)
    Button(GetControlInstructionalButton(2, 174, true))
    ButtonMessage("Left")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(6)
    Button(GetControlInstructionalButton(2, 175, true))
    ButtonMessage('Right')
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(7)
    Button(GetControlInstructionalButton(2, 10, true))
    ButtonMessage('Zoom')
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(8)
    Button(GetControlInstructionalButton(2, 11, true))
    ButtonMessage('Dezoom')
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

local function AnimTablet()
    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        SetCurrentPedWeapon(playerPed, 'weapon_unarmed', true)
        form = setupScaleform("instructional_buttons")
        Citizen.CreateThread(function()
            while UsingPanel do
                DrawScaleformMovieFullscreen(form, 255, 255, 255, 255, 0)
                Citizen.Wait(1)
            end
        end)
    end)
end

local function ExitMenuCamera()
    DoScreenFadeOut(500)
    Citizen.Wait(500)

    UsingPanel = false
    DetachEntity(PropTablet, true, false)
    DeleteEntity(PropTablet)
    FreezeEntityPosition(PlayerPedId(), false)
    ClearPedSecondaryTask(PlayerPedId())

    ClearTimecycleModifier("scanline_cam_cheap")
    DisplayRadar(true)
    SendNUIMessage({
        type = "frontcam",
        toggle = false
    })
    DestroyCam(CamTemporal)
    RenderScriptCams(0, 0, 1, 1, 1)
    Citizen.Wait(500)
    -- RenderScriptCams(false, true, 2000, true, true)
    DoScreenFadeIn(500)
    -- NetworkStopSynchronisedScene(HackLoop)
    NetworkStartSynchronisedScene(HackLoopFinish)
    Wait(1500)
    NetworkStopSynchronisedScene(HackLoopFinish)
    DeleteObject(bag)
    DeleteObject(laptop)
    LocalPlayer.state:set("inv_busy", false, true)
end

local function MakeInvProp()
    Citizen.CreateThread(function()
        while UsingPanel do
            SetEntityLocallyInvisible(CameraProp[ActualCamera])
            Citizen.Wait(1)
        end
    end)
end

local function GoPanelCamera()
    UsingPanel = true
    -- AnimTablet()
    -- Citizen.Wait(2000)

    NumberCameras = 0
    ActualCamera = 1

    for i,Cameras in ipairs(CameraProp) do
        NumberCameras = NumberCameras + 1
    end
    local CoordsCameraVirtual = GetEntityCoords(CameraProp[1])

    local CamTemporal = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", CoordsCameraVirtual.x, CoordsCameraVirtual.y, CoordsCameraVirtual.z - 0.3 , 0, 0.0, GetEntityHeading(CameraProp[ActualCamera]) - 180, 90.0)

    DoScreenFadeOut(500)
    OpenCamAnim()
    Citizen.Wait(750)
    AnimTablet()
    DisplayRadar(false)

    SetTimecycleModifier("scanline_cam_cheap")
    -- SetTimecycleModifierStrength(1.5)

    SetCamActive(CamTemporal, true)
    RenderScriptCams(true, false, 100, true, false)
    MakeInvProp()

    Citizen.Wait(500)
    DoScreenFadeIn(500)
    NeedToCheck = true
    LocalPlayer.state:set("inv_busy", true, true)

    Citizen.CreateThread(function()
        while true do
            if IsControlJustPressed(0, 35) then

                if ActualCamera < NumberCameras then
                    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(CameraProp[ActualCamera + 1])) < Config.DistanceToConnect then
                        ActualCamera = ActualCamera + 1

                        NeedToCheck = true
                        DoScreenFadeOut(500)
                        Citizen.Wait(500)

                        CoordsCameraVirtual = GetEntityCoords(CameraProp[ActualCamera])
                        SetCamCoord(CamTemporal, CoordsCameraVirtual + vector3(0.0, 0.0, -0.3))
                        SetCamRot(CamTemporal, 0.0, 0.0, GetEntityHeading(CameraProp[ActualCamera]) - 180)

                        Citizen.Wait(200)
                        DoScreenFadeIn(500)
                    else
                        QBCore.Functions.Notify('You are too far away to establish connection with the camera', 'error')
                    end
                else
                    QBCore.Functions.Notify("There are no more cameras to continue watching", 'error')
                end

            end
            if IsControlJustPressed(0, 34) then

                if ActualCamera > 1 then
                    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(CameraProp[ActualCamera - 1])) < Config.DistanceToConnect then
                    ActualCamera = ActualCamera - 1
                    
                    NeedToCheck = true
                    DoScreenFadeOut(500)
                    Citizen.Wait(500)

                    CoordsCameraVirtual = GetEntityCoords(CameraProp[ActualCamera])
                    SetCamCoord(CamTemporal, CoordsCameraVirtual + vector3(0.0, 0.0, -0.3))
                    SetCamRot(CamTemporal, 0.0, 0.0, GetEntityHeading(CameraProp[ActualCamera]) - 180, 1)

                    Citizen.Wait(200)
                    DoScreenFadeIn(500)
                    else
                        QBCore.Functions.Notify("You are too far away to establish connection with the camera", 'error')
                    end
                else
                    QBCore.Functions.Notify("There are no more cameras to continue watching", 'error')
                end
            end

            if IsControlPressed(0, 174) then
                local RotationCamera = GetCamRot(CamTemporal)
                SetCamRot(CamTemporal, RotationCamera.x, RotationCamera.y, RotationCamera.z + 1)
                SetEntityHeading(CameraProp[ActualCamera], GetEntityHeading(CameraProp[ActualCamera]) + 1)
            end

            if IsControlPressed(0, 175) then
                local RotationCamera = GetCamRot(CamTemporal)
                SetCamRot(CamTemporal, RotationCamera.x, RotationCamera.y, RotationCamera.z - 1)
                SetEntityHeading(CameraProp[ActualCamera], GetEntityHeading(CameraProp[ActualCamera]) - 1)
            end

            if IsControlPressed(0, 173) then
                local RotationCamera = GetCamRot(CamTemporal)

                if RotationCamera.x > -30 then
                    SetCamRot(CamTemporal, RotationCamera.x - 1, RotationCamera.y, RotationCamera.z)
                end
            end

            if IsControlPressed(0, 172) then
                local RotationCamera = GetCamRot(CamTemporal)

                if RotationCamera.x < 30 then
                    SetCamRot(CamTemporal, RotationCamera.x + 1, RotationCamera.y, RotationCamera.z)
                end
            end

            if IsControlJustPressed(1, 194) then
                ExitMenuCamera()
                break
            end

            if IsControlPressed(1, 10) then
                if GetCamFov(CamTemporal) > 30 then 
                    SetCamFov(CamTemporal, GetCamFov(CamTemporal) - 1.0)
                end
            end

            if IsControlPressed(1, 11) then
                if GetCamFov(CamTemporal) < 100 then 
                    SetCamFov(CamTemporal, GetCamFov(CamTemporal) + 1.0)
                end
            end

            local s1, s2 = GetStreetNameAtCoord(CoordsCameraVirtual.x, CoordsCameraVirtual.y, CoordsCameraVirtual.z)
            local street = GetStreetNameFromHashKey(s1)
        
            if NeedToCheck then
                if GetEntityHealth(CameraProp[ActualCamera]) > 881 then
                    SetTimecycleModifierStrength(1.5)
                    SendNUIMessage({
                        type = "frontcam",
                        toggle = true,
                        label = street,
                        idfk = 'Camera #'..ActualCamera,
                        connection = 'CONNECTED'
                    })
                else
                    SetTimecycleModifierStrength(25.0)
                    SendNUIMessage({
                        type = "frontcam",
                        toggle = true,
                        label = street,
                        idfk = 'Camera #'..ActualCamera,
                        connection = 'DISCONNECTED'
                    })
                end
                NeedToCheck = false
            end

            Citizen.Wait(5)
        end
    end)
end

RegisterNetEvent("aj-camera:client:PlaceCamera", function()
        if PlacingCamera then return end
        PlacingCamera = true
        CountCamera = CountCamera + 1
        RequestModel(`prop_cctv_cam_06a`)
        while not HasModelLoaded(`prop_cctv_cam_06a`) do
            Wait(100)
        end
        CameraProp[CountCamera] = CreateObject(`prop_cctv_cam_06a`, 0, 0, 0, true, true, true)
        SetEntityCollision(CameraProp[CountCamera], false, false)
        SetEntityAsMissionEntity(CameraProp[CountCamera], true, true)
        NetworkRegisterEntityAsNetworked(CameraProp[CountCamera])

        QBCore.Functions.Notify('Press [E] to place the camera', 'primary', 7500)

        Citizen.CreateThread(function()
            while true do
                PlayerCoords = GetEntityCoords(PlayerPedId())
                a, CoordsCamera, c = RayCastGamePlayCamera(15)
                if CoordsCamera ~= NoLocation then
                    SetEntityVisible(CameraProp[CountCamera], true)
                    SetEntityCoords(CameraProp[CountCamera], CoordsCamera + vector3(0, 0.0, 0))

                    if GetEntityCoords(CameraProp[CountCamera]) == NoLocation then
                        if IsControlJustPressed(0, 38) then
                            QBCore.Functions.Notify("You cant place this here!", 'error')
                        end
                    else
                        local Camcoords = GetEntityCoords(CameraProp[CountCamera])
                        -- DrawLine(CoordsCamera.x, CoordsCamera.y, CoordsCamera.z - 0.3, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 255, 255, 255, 255)
                        local forwardCoord = Camcoords+(getDirVecFromHead(GetEntityHeading(CameraProp[CountCamera]), 0)*2)
                        DrawLine(Camcoords.x, Camcoords.y, Camcoords.z - 0.28, forwardCoord.x, forwardCoord.y, forwardCoord.z - 0.85, 255, 50, 50, 255)
                        if IsControlPressed(0, 174) then
                            SetEntityRotation(CameraProp[CountCamera], 0, 0, GetEntityHeading(CameraProp[CountCamera]) + 1.0, 2, true)
                        end
            
                        if IsControlPressed(0, 175) then
                            SetEntityRotation(CameraProp[CountCamera], 0, 0, GetEntityHeading(CameraProp[CountCamera]) - 1.0, 2, true)
                        end

                        --TODO: Make more then 1 type of camera model [WIP]
                        -- if IsControlJustPressed(0, 172) then
                        --     slot = slot + 1
                        --     print(slot, #objects)
                        --     if slot > #objects then
                        --         print('Reset Slot')
                        --         slot = 1
                        --     end
                        --     print('Pressed')
                        --     local CamModel = GetHashKey(objects[slot])
                        --     DeleteEntity(CameraProp[CountCamera])
                        --     RequestModel(CamModel)
                        --     while not HasModelLoaded(CamModel) do
                        --         Wait(100)
                        --         print('Requesting '..CamModel)
                        --     end
                        --     CameraProp[CountCamera] = CreateObject(GetHashKey(objects[slot]), 0, 0, 0, true, true, true)
                        --     SetEntityCollision(CameraProp[CountCamera], false, false)
                        -- end
            
                        if IsControlJustPressed(0, 38) then
                            PlacingCamera = false
                            SetEntityCollision(CameraProp[CountCamera], true, true)
                            QBCore.Functions.Notify('You placed camera #'..CountCamera, 'success')
                            break
                        end

                        if IsControlJustPressed(0, 177) then
                            PlacingCamera = false
                            DeleteEntity(CameraProp[CountCamera])
                            CountCamera = CountCamera - 1
                            TriggerServerEvent('aj-camera:server:GiveCamBack')
                            break
                        end
                    end
                else
                    if CameraProp[CountCamera] and DoesEntityExist(CameraProp[CountCamera]) then
                        -- DeleteEntity(CameraProp[CountCamera])
                        SetEntityVisible(CameraProp[CountCamera], false)
                    end
                end

                Citizen.Wait(3)
            end
        end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        FreezeEntityPosition(PlayerPedId(), false)
        ClearTimecycleModifier("scanline_cam_cheap")
        for i,Prop in ipairs(CameraProp) do
            DeleteEntity(Prop)
        end
    end
end)


RegisterCommand("cameras", function(source, args, rawCommand)
    if not IsPedInAnyVehicle(PlayerPedId(), true) then
        a, ListCameras = ipairs(CameraProp)

        if json.encode(ListCameras) == "[]" then
            QBCore.Functions.Notify('You dont have any cameras connected!', 'error')
        else
            if not PlacingCamera then 
                if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(CameraProp[1])) < Config.DistanceToConnect then
                    GoPanelCamera()
                else
                    QBCore.Functions.Notify('You cant seem to connect to the cameras', 'error')
                end
            end
        end
    end
end)
local QBCore = exports['qb-core']:GetCoreObject()
local menu_opened = false

local function toggleNuiFrame(shouldShow)
  SetNuiFocus(shouldShow, shouldShow)
  SendReactMessage('setVisible', shouldShow)
end

local function toggleNuiFrameNoFocus(shouldShow)
  SendReactMessage('setVisible', shouldShow)
end

RegisterCommand('open-list', function(source, args)
  if args[1] == "0" then
    if not menu_opened then
      menu_opened = true
      toggleNuiFrame(true)
      TriggerServerEvent('nmsh-policehub:get:officers')
    else
      menu_opened = false
      toggleNuiFrame(false)
    end
  else
    if not menu_opened then
      menu_opened = true
      toggleNuiFrameNoFocus(true)
      TriggerServerEvent('nmsh-policehub:get:officers')
    else
      menu_opened = false
      toggleNuiFrameNoFocus(false)
    end
  end
end)

RegisterNUICallback('hideFrame', function(_, cb)
  toggleNuiFrame(false)
  TriggerEvent('nmsh-policehub:close:all')
  menu_opened = false
  cb({})
end)

RegisterNetEvent('nmsh-policehub:close:all')
AddEventHandler('nmsh-policehub:close:all', function()
    SendReactMessage('closeall', {})
end)

local cops = 0
RegisterNetEvent('nmsh-policehub:send:officers')
AddEventHandler('nmsh-policehub:send:officers', function(users, cops)
    SendReactMessage('open', { users = users, count = tostring(cops) })
    cops = users.count
end)

RegisterNUICallback('Get-officers-count', function(data, cb)
  QBCore.Functions.TriggerCallback('nmsh-policehub:officers:count', function(count2)
    local retData <const> = { count = count2 }
    cb(retData)
  end)
end)

local officerlocationblip = nil
local officerlocationblipwave = nil

RegisterNUICallback('Get-officer-location', function(data, cb)
  local NumberData = tonumber(data.id)
  local NameData = data.name
  local GradeData = data.grade
  local playerIdx = GetPlayerFromServerId(NumberData)
  local ped = GetPlayerPed(playerIdx)
  local PlayerCoords = GetEntityCoords(ped)
  if DoesBlipExist(officerlocationblip) then
    RemoveBlip(officerlocationblip)
    officerlocationblip = nil
    RemoveBlip(officerlocationblipwave)
    officerlocationblipwave = nil
    Citizen.Wait(1000)
    -- wave blip
    officerlocationblipwave = AddBlipForCoord(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
    SetBlipSprite(officerlocationblipwave, 161)
    SetBlipColour(officerlocationblipwave, 1)
    SetBlipAsShortRange(officerlocationblipwave, true)
    -- circle blip
    officerlocationblip = AddBlipForCoord(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
    SetBlipSprite(officerlocationblip, 774)
    SetBlipDisplay(officerlocationblip, 4)
    SetBlipScale(officerlocationblip, 1.0)
    SetBlipColour(officerlocationblip, 1)
    SetBlipAlpha(officerlocationblip, 255)
    SetBlipAsShortRange(officerlocationblip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Location Of : "..GradeData.." "..NameData.."")
    EndTextCommandSetBlipName(officerlocationblip)
    QBCore.Functions.Notify("Radar just found "..GradeData.." "..NameData.." location", "success", 5000)
    Citizen.Wait(20000)
    RemoveBlip(officerlocationblip)
    officerlocationblip = nil
    RemoveBlip(officerlocationblipwave)
    officerlocationblipwave = nil
    QBCore.Functions.Notify("Radar lost connection to "..GradeData.." "..NameData.."", "error", 5000)
  else
    -- wave blip
    officerlocationblipwave = AddBlipForCoord(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
    SetBlipSprite(officerlocationblipwave, 161)
    SetBlipColour(officerlocationblipwave, 1)
    SetBlipAsShortRange(officerlocationblipwave, true)
    -- cricle blip
    officerlocationblip = AddBlipForCoord(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
    SetBlipSprite(officerlocationblip, 774)
    SetBlipDisplay(officerlocationblip, 4)
    SetBlipScale(officerlocationblip, 1.0)
    SetBlipColour(officerlocationblip, 1)
    SetBlipAlpha(officerlocationblip, 255)
    SetBlipAsShortRange(officerlocationblip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Location OF : "..GradeData.." "..NameData.."")
    EndTextCommandSetBlipName(officerlocationblip)
    QBCore.Functions.Notify("Radar just found "..GradeData.." "..NameData.." location", "success", 5000)
    Citizen.Wait(20000)
    RemoveBlip(officerlocationblip)
    officerlocationblip = nil
    RemoveBlip(officerlocationblipwave)
    officerlocationblipwave = nil
    QBCore.Functions.Notify("Radar lost connection to "..GradeData.." "..NameData.."", "error", 5000)
  end
end)

RegisterNUICallback("Join-Officer-radio", function(data)
  local playerid = data.id
  local playername = data.name
  local playergrade = data.grade
  local channel = Player(playerid).state['radioChannel']
  if channel ~= 0 then
      exports["pma-voice"]:setRadioChannel(channel)
      QBCore.Functions.Notify("You just joined "..playergrade.." "..playername.." radio channel", "success", 5000)
  else
      QBCore.Functions.Notify(""..playergrade.." "..playername.." is not in radio channel", "error", 5000)
  end
end)

RegisterNUICallback("Use-Panic-Button", function()
  local playerid = QBCore.Functions.GetPlayerData().source
  local playergrade = QBCore.Functions.GetPlayerData().job.grade.name
  local playername = QBCore.Functions.GetPlayerData().charinfo.firstname .." ".. QBCore.Functions.GetPlayerData().charinfo.lastname
  local NumberData = tonumber(playerid)
  local playerIdx = GetPlayerFromServerId(NumberData)
  local playerped = GetPlayerPed(playerIdx)
  local playerCoords = GetEntityCoords(playerped)
  TriggerServerEvent('nmsh-policehub:SendPanicToPlayers', playerCoords, playergrade, playername, playerped)
end)

local PanicBlipData = nil

RegisterNetEvent('nmsh-policehub:SetPanicBlip')
AddEventHandler('nmsh-policehub:SetPanicBlip', function(PlayerCoords)
  if DoesBlipExist(PanicBlipData) then
    RemoveBlip(PanicBlipData)
    PanicBlipData = nil
    Citizen.Wait(1000)
    -- wave blip
    PanicBlipData = AddBlipForCoord(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
    SetBlipSprite(PanicBlipData, 161)
    SetBlipColour(PanicBlipData, 1)
    SetBlipAsShortRange(PanicBlipData, true)
    Citizen.Wait(20000)
    RemoveBlip(PanicBlipData)
    PanicBlipData = nil
  else
    -- wave blip
    PanicBlipData = AddBlipForCoord(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
    SetBlipSprite(PanicBlipData, 161)
    SetBlipColour(PanicBlipData, 1)
    SetBlipAsShortRange(PanicBlipData, true)
    Citizen.Wait(20000)
    RemoveBlip(PanicBlipData)
    PanicBlipData = nil
  end
end)

RegisterNUICallback("Change-Officer-Callsign", function(data, cb)
  local playerid = data.id
  local playernewcallsign = data.callsign
  TriggerServerEvent('nmsh-policehub:officer:change:callsign', playerid, playernewcallsign)
  cb({})
end)

CreateThread(function()
  while true do
    if IsPauseMenuActive() then
      if menu_opened then
        toggleNuiFrame(false)
        TriggerEvent('nmsh-policehub:close:all')
        menu_opened = false
      end
    end
    Wait(500)
  end
end)
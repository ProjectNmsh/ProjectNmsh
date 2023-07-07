if GetConvarInt('ox_target:defaults', 1) ~= 1 then return end

local ox_target = exports.ox_target
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetVehicleDoorLockStatus = GetVehicleDoorLockStatus

local function toggleDoor(vehicle, door)
    if GetVehicleDoorLockStatus(vehicle) ~= 2 then
        if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
            SetVehicleDoorShut(vehicle, door, false)
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end
    end
end

ox_target:addGlobalVehicle({
    {
        name = 'ox_target:driverF',
        icon = 'fa-solid fa-car-side',
        label = locale('toggle_front_driver_door'),
        bones = { 'door_dside_f', 'seat_dside_f' },
        canInteract = function(entity, distance, coords, name)
            if GetVehicleDoorLockStatus(entity) > 1 then return end

            local boneId = GetEntityBoneIndexByName(entity, 'door_dside_f')

            if IsVehicleDoorDamaged(entity, 0) then return end

            if boneId ~= -1 then
                return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_dside_f'))) < 0.72
            end
        end,
        onSelect = function(data)
            toggleDoor(data.entity, 0)
        end
    }
})

ox_target:addGlobalVehicle({
    {
        name = 'ox_target:passengerF',
        icon = 'fa-solid fa-car-side',
        label = locale('toggle_front_passenger_door'),
        bones = { 'door_pside_f', 'seat_pside_f' },
        canInteract = function(entity, distance, coords, name)
            if GetVehicleDoorLockStatus(entity) > 1 then return end

            local boneId = GetEntityBoneIndexByName(entity, 'door_pside_f')
            if IsVehicleDoorDamaged(entity, 1) then return end

            if boneId ~= -1 then
                return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_pside_f'))) < 0.72
            end
        end,
        onSelect = function(data)
            toggleDoor(data.entity, 1)
        end
    }
})

ox_target:addGlobalVehicle({
    {
        name = 'ox_target:driverR',
        icon = 'fa-solid fa-car-side',
        label = locale('toggle_rear_driver_door'),
        bones = { 'door_dside_r', 'seat_dside_r' },
        canInteract = function(entity, distance, coords, name)
            if GetVehicleDoorLockStatus(entity) > 1 then return end

            local boneId = GetEntityBoneIndexByName(entity, 'door_dside_r')
            if IsVehicleDoorDamaged(entity, 2) then return end

            if boneId ~= -1 then
                return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_dside_r'))) < 0.72
            end
        end,
        onSelect = function(data)
            toggleDoor(data.entity, 2)
        end
    }
})

ox_target:addGlobalVehicle({
    {
        name = 'ox_target:passengerR',
        icon = 'fa-solid fa-car-side',
        label = locale('toggle_rear_passenger_door'),
        bones = { 'door_pside_r', 'seat_pside_r' },
        canInteract = function(entity, distance, coords, name)
            if GetVehicleDoorLockStatus(entity) > 1 then return end

            local boneId = GetEntityBoneIndexByName(entity, 'door_pside_r')
            if IsVehicleDoorDamaged(entity, 3) then return end

            if boneId ~= -1 then
                return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_pside_r'))) < 0.72
            end
        end,
        onSelect = function(data)
            toggleDoor(data.entity, 3)
        end
    }
})


ox_target:addGlobalVehicle({
    {
        name = 'ox_target:bonnet',
        icon = 'fa-solid fa-car',
        label = locale('toggle_hood'),
        bones = 'bonnet',
        canInteract = function(entity, distance, coords, name, boneId)
            if GetVehicleDoorLockStatus(entity) > 1 then return end
            if IsVehicleDoorDamaged(entity, 4) then return end
            return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.9
        end,
        onSelect = function(data)
            toggleDoor(data.entity, 4)
        end
    }
})

ox_target:addGlobalVehicle({
    {
        name = 'ox_target:trunk',
        icon = 'fa-solid fa-car-rear',
        label = locale('toggle_trunk'),
        bones = 'boot',
        canInteract = function(entity, distance, coords, name, boneId)
            if GetVehicleDoorLockStatus(entity) > 1 then return end
            if IsVehicleDoorDamaged(entity, 5) then return end
            return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.9
        end,
        onSelect = function(data)
            toggleDoor(data.entity, 5)
        end
    }
})

ox_target:addGlobalVehicle({
    {
        name = 'ox_target:garbage',
        icon = 'fa-solid fa-truck',
        label = locale('garbage_bag'),
        bones = 'boot',
        canInteract = function(entity, distance, coords, name, boneId)
            if distance >= 0.9 then return end
            return exports['prisma-sanitation']:garbageTarget()
        end,
        onSelect = function(data)
            TriggerEvent('qb-garbage-asd')
        end
    }
})

ox_target:addGlobalVehicle({
    {
        name = 'ox_target:impound',
        icon = 'fa-solid fa-car',
        label = "Impound",
        bones = { 'door_dside_f', 'seat_dside_f', 'boot', 'hood' },
        canInteract = function(entity, distance, coords, name, boneId)
            if distance >= 0.9 then return end
            return exports['qb-policejob']:GetJobName("police")
        end,
        onSelect = function(data)
            TriggerEvent('qb-policejob:copimpound') 
        end
    }
})

ox_target:addGlobalVehicle({
    {
        name = 'ox_target:impoundTow',
        icon = 'fa-solid fa-car',
        label = "Impound",
        bones = { 'door_dside_f', 'seat_dside_f', 'boot', 'hood' },
        canInteract = function(entity, distance, coords, name, boneId)
            if distance >= 0.9 then return end
            return exports['qb-policejob']:GetJobName("tow")
        end,
        onSelect = function(data)
            TriggerEvent('qb-policejob:towimpound') 
        end
    }
})

ox_target:addGlobalPlayer({ 
    {
        type = "client",
        event = "bunny-cuff:client:CuffPlayer", 
        icon = "fas fa-hands",
        label = "Cuff Player",
        item = 'handcuffs',
    },
    {
        type = "client",
        event = "bunny-cuff:client:UnCuffFully",
        icon = "fas fa-hands", 
        label = "UnCuff Player",
        item = 'handcuffs',
    },
    {
        type = "client",
        event = "police:client:EscortPlayer",
        icon = "fas fa-key",
        label = "Escort",
    },
})

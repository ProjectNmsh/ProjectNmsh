CallbackModule, PlayerModule, FunctionsModule, DatabaseModule, CommandsModule, EventsModule = nil, nil, nil, nil, nil, nil
Carrying, Carried = {}, {}

local _Ready = false
AddEventHandler('Modules/server/ready', function()
    TriggerEvent('Modules/server/request-dependencies', {
        'Callback',
        'Player',
        'Functions',
        'Database',
        'Commands',
        'Events',
    }, function(Succeeded)
        if not Succeeded then return end
        CallbackModule = exports['nmsh-base']:FetchModule('Callback')
        PlayerModule = exports['nmsh-base']:FetchModule('Player')
        FunctionsModule = exports['nmsh-base']:FetchModule('Functions')
        DatabaseModule = exports['nmsh-base']:FetchModule('Database')
        CommandsModule = exports['nmsh-base']:FetchModule('Commands')
        EventsModule = exports['nmsh-base']:FetchModule('Events')
        _Ready = true
    end)
end)

Citizen.CreateThread(function() 
    while not _Ready do 
        Citizen.Wait(4) 
    end 

    CommandsModule.Add({"me"}, "Character Expression", {{Name="message", Help="Message"}}, false, function(source, args)
        local Text = table.concat(args, ' ')
        TriggerClientEvent('nmsh-misc/client/me', -1, Source, Text)
    end)

    CommandsModule.Add({"carry"}, "Carry the closest person", {}, false, function(source, args)
        local Player = PlayerModule.GetPlayerBySource(source)
        local Text = args[1]
        TriggerClientEvent('nmsh-misc/client/try-carry', source)
    end)

    CallbackModule.CreateCallback('nmsh-misc/server/gopros/does-exist', function(Source, Cb, CamId)
        for k, v in pairs(Config.GoPros) do
            if tonumber(v.Id) == tonumber(CamId) then
                Cb(v)
                return
            end
        end
        Cb(false)
    end)

    CallbackModule.CreateCallback('nmsh-misc/server/gopros/get-all', function(Source, Cb)
        Cb(Config.GoPros)
    end)

    CallbackModule.CreateCallback('nmsh-misc/server/has-illegal-item', function(Source, Cb)
        local Player = PlayerModule.GetPlayerBySource(Source)
        if Player then
            for k, v in pairs(Config.IllegalItems) do
                local ItemData = Player.Functions.GetItemByName(v)
                if ItemData ~= nil and ItemData.Amount > 0 then
                    Cb(v)
                end
            end
        end
        Cb(false)
    end)
    
    EventsModule.RegisterServer("nmsh-misc/server/spray-place", function(Source, Coords, Heading, Type)
        local CustomId = math.random(11111, 99999)
        local NewSpray = {
            Id = CustomId,
            Name = "Spray-"..CustomId,
            Type = Type,
            Coords = { 
                X = Coords.x,
                Y = Coords.y,
                Z = Coords.z - 2.0,
                H = Heading
            },
        }
        Config.Sprays[#Config.Sprays + 1] = NewSpray
        TriggerClientEvent('nmsh-misc/client/sync-sprays', -1, NewSpray)
        SetTimeout(100, function()
            TriggerClientEvent('nmsh-misc/client/done-placing-spray', Source, CustomId)
        end)
    end)

    EventsModule.RegisterServer("nmsh-misc/server/gopro-place", function(Source, Coords, Heading, Encrypted, IsVehicle, Vehicle)
        local CustomId = math.random(11111, 99999)
        local NewGoPro = {
            Id = CustomId,
            Name = "GoPro-"..CustomId,
            IsEncrypted = Encrypted,
            IsVehicle = IsVehicle,
            Vehicle = IsVehicle and Vehicle or false,
            Coords = { 
                X = Coords.x,
                Y = Coords.y,
                Z = Coords.z,
                H = Heading
            },
            Timestamp = os.date(),
        }
        Config.GoPros[#Config.GoPros + 1] = NewGoPro
        TriggerClientEvent('nmsh-misc/client/gopro-action', -1, 2, NewGoPro)
        TriggerClientEvent('nmsh-ui/client/notify', Source, "gopro-placed", "You placed a GoPro ("..CustomId..")", 'success')
    end)
    
    EventsModule.RegisterServer('nmsh-misc/server/send-me', function(Source, Text)
        TriggerClientEvent('nmsh-misc/client/me', -1, Source, Text)
    end)
    
    EventsModule.RegisterServer('nmsh-misc/server/goldpanning/get-loot', function(Source, Multiplier)
        print('Giving goldpanning loot', Multiplier)
        if Multiplier == 1 then

        elseif Multiplier == 2 then

        elseif Multiplier == 3 then

        end
    end)
end)

RegisterNetEvent("nmsh-misc/server/carry-target", function(TargetServer)
    local src = source
    TriggerClientEvent('nmsh-misc/client/getting-carried', TargetServer, src)
    Carrying[src] = TargetServer
    Carried[TargetServer] = src
end)

RegisterNetEvent("nmsh-misc/server/stop-carry", function()
    local src = source
    if Carrying[src] then
        TriggerClientEvent('nmsh-misc/client/stop-carry', Carrying[src])
    elseif Carried[src] then
        TriggerClientEvent('nmsh-misc/client/stop-carry', Carried[src])
    end
    Carrying[src] = nil
    Carried[TargetServer] = nil
end)

-- GoPro

RegisterNetEvent("nmsh-misc/server/gopro-action", function(GoProId, Action, Bool)
    if Action == 'SetBlurred' then
        for k, v in pairs(Config.GoPros) do
            if tonumber(v.Id) == tonumber(GoProId) then
                Config.GoPros[k].Blurred = Bool
                TriggerClientEvent('nmsh-misc/client/gopro-action', -1, 3, Config.GoPros[k])
                return
            end
        end
    end
end)
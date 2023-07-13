local ResourceRequested = {}

RegisterNetEvent(
    "dev-antidump:server:" .. GetCurrentResourceName(),
    function(underTrigger)
        local src = source
        local id = tostring(src)

        if not ResourceRequested[id] then
            ResourceRequested[id] = true

            local info = DevConfig.AntiDump
            local path = "./resources/"

            if info.folder then
                path = path .. info.folder .. "/"
            end

            path = path .. GetCurrentResourceName() .. "/"

            local ResCode = ""
            local JS = ""
            local html = ""
            local css = ""
            local hasNui = false

            for _, file in pairs(info.scripts) do
                local script = path .. file.name

                if file.nui then
                    hasNui = true

                    if file.html then
                        html = html .. exports["dev-antidump"]:LoadFile(script)
                    end

                    if file.js then
                        JS =
                            JS ..
                            '<script type="text/javascript">' ..
                                exports["dev-antidump"]:LoadFile(script) ..
                                    "</script>"
                    end

                    if file.css then
                        css =
                            css ..
                            "<style>" ..
                                exports["dev-antidump"]:LoadFile(script) ..
                                    "</style>"
                    end
                else
                    ResCode =
                        ResCode .. exports["dev-antidump"]:LoadFile(script)
                end
            end

            local data = {
                nui = hasNui,
                lua = ResCode,
                html = html,
                js = JS,
                css = css
            }
            -- if you want enable queue just remove comment from exports and comment on TriggerClientEvent
            -- exports['dev-antidump']:InsertQueue(src, underTrigger, data, GetCurrentResourceName())
            TriggerClientEvent(underTrigger, src, data)
        else

            exports["dev-antidump"]:BanPlayer(
                src,
                "DevX-Antidump: Go fuck your self."
            )
            -- if you use esx or other framework, you can TriggerEvent  or exports to ban player and remove dev-antidump from here.
            -- or edit dev-antidump ban player function to your framework
        end
    end
)
-- continue your server side code here.